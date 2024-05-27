const Citrix = require('./citrix')
const sync = require('./synchronous')
require('dotenv').config()
var exec = require('child_process').exec;
const fs = require('fs');





async function main() {
    const lockFilePath = 'isRunning.lock';

    if (fs.existsSync(lockFilePath)) {
        console.error('Script already running!');
    } else {
        fs.writeFileSync(lockFilePath, 'running');

        const citrix = new Citrix()

        var result,
            data = {};
        data['errors'] = {},
            data['resources'] = {};
        data.resources.value = [];

        try {
            console.log('setting params')
            citrix.setParams({ client_id: process.env.client_id, client_secret: process.env.client_secret, customer_id: process.env.customer_id, siteId: process.env.siteId, logon_duration: Number(process.env.logon_duration) })

            try {
                console.log('getting token')
                const result = await citrix.request(
                    'https://api-us.cloud.com/cctrustoauth2/' + encodeURIComponent(citrix.params.customer_id) + '/tokens/clients',
                    'grant_type=client_credentials&client_id=' + encodeURIComponent(citrix.params.client_id) + '&client_secret=' + encodeURIComponent(citrix.params.client_secret)
                );

                if ('access_token' in result) {
                    citrix.token = result['access_token'];
                } else {
                    throw 'Auth response does not contain access token.';
                }
            }
            catch (error) {
                console.log(error.toString())
            }

            if (!('auth' in data.errors)) {
                const logonData = citrix.request("https://api-us.cloud.com/monitorodata/Sessions?$filter=" + encodeURIComponent("(LogOnDuration gt 60000)"))

                async function getParsedLogonData(logonData) {
                    const filteredData = logonData.map(function (l) {
                        return {
                            SessionKey: l.SessionKey,
                            UserId: l.UserId,
                            MachineId: l.MachineId,
                            StartDate: l.StartDate,
                            LogonDurationInSeconds: l.LogOnDuration / 1000,
                        }
                    })
                        .filter(function (l) {
                            return l.LogonDurationInSeconds > citrix.params.logon_duration
                        })


                    async function getDates(input) {
                        try {
                            const lm = await citrix.request("https://api-us.cloud.com/monitorodata/LogonMetrics?$filter=" + encodeURIComponent("(SessionKey eq " + input.SessionKey + ")"));
                            const LM = lm.value[0];

                            const startDate = new Date(LM.UserInitStartDate);
                            const endDate = new Date(LM.UserInitEndDate);

                            const ICA = (endDate.getTime() - startDate.getTime()) / 1000;

                            const data = {
                                SessionKey: input.SessionKey,
                                UserId: input.UserId,
                                MachineId: input.MachineId,
                                StartDate: input.StartDate,
                                LogonDurationInSeconds: input.LogonDurationInSeconds,
                                ICALatencyInSeconds: ICA,
                            }

                            return data
                        } catch (e) {
                            console.log(e.message)
                            return null
                        }
                    }

                    async function getUser(l) {
                        try {
                            const sessionUser = await citrix.request("https://api-us.cloud.com/monitorodata/Users?$filter=" + encodeURIComponent("(Id eq " + l.UserId + ")"))
                            const User = sessionUser.value[0]

                            return {
                                SessionKey: l.SessionKey,
                                MachineId: l.MachineId,
                                User: {
                                    Id: User.Id,
                                    UserName: User.UserName,
                                    FullName: User.FullName,
                                    ICALatencyInSeconds: l.ICALatencyInSeconds
                                },
                                LogonDurationInSeconds: l.LogonDurationInSeconds
                            }
                        } catch (e) {
                            console.log(e.message)
                            return null
                        }
                    }

                    async function getMachine(l) {
                        try {
                            const machine = await citrix.request("https://api-us.cloud.com/monitorodata/Machines?$filter=" + encodeURIComponent("(Id eq " + l.MachineId + ")"))
                            const mch = machine.value[0]

                            return {
                                UserId: l.User.Id,
                                UserName: l.User.UserName,
                                FullName: l.User.FullName,
                                ICALatencyInSeconds: l.User.ICALatencyInSeconds,
                                LogonDurationInSeconds: l.LogonDurationInSeconds,
                                MachineName: mch.Name,
                                DnsName: mch.DnsName,
                                HostingServerName: mch.HostingServerName,
                                HostedMachineName: mch.HostedMachineName,
                                OSType: mch.OSType,

                            }
                        } catch (e) {
                            console.log(e.message)
                            return null
                        }
                    }

                    console.log('item count', filteredData.length)
                    const withDates = await sync([], filteredData, filteredData.length - 1, getDates)

                    const withUser = await sync([], withDates, withDates.length - 1, getUser)

                    return await sync([], withUser, withUser.length - 1, getMachine)
                }


                logonData.then((d) => {
                    getParsedLogonData(d.value).then((d) => {
                        data.resources.value.push(d)

                        const object = d.reduce((acc, currentValue, index) => {
                            acc[index] = currentValue;
                            return acc;
                        }, {});

                        console.log(object)

                        const command = `/usr/bin/zabbix_sender -c /etc/zabbix/zabbix_agentd.conf -k logon_data -o \'${JSON.stringify(object)}\'`;

                        exec(command, (error, stdout, stderr) => {
                            if (error) {
                                console.error(`exec error: ${error}`);
                                return;
                            }
                            console.log(`stdout: ${stdout}`);
                            if (!stderr) {
                                console.log('Sent data to zabbix');
                            } else {
                                console.error(`stderr: ${stderr}`);
                            }
                        });

                        fs.unlinkSync(lockFilePath);
                    })
                })
            }
        }
        catch (error) {
            console.log(error.toString)
        }
    }
}

main()