const axios = require('axios').default;

class Citrix {
    constructor(params) {
        this.params = params;
        this.token = null;
    }

    setParams(params) {
        const fields = ['client_id', 'client_secret', 'customer_id']
        fields.forEach((field) => {
            if (typeof params !== 'object' || typeof params[field] === 'undefined' || params[field] === '') {
                throw new Error(`Required param is not set: ${field}.`);
            }
        });

        this.params = params;
    }

    async request(url, data = null) {
        const headers = {};

        if (this.token) {
            headers['Content-Type']= 'application/json';
            headers['Authorization'] = `CWSAuth bearer=${this.token}`;
            headers['Citrix-CustomerId'] = this.params.customer_id;

            if (typeof url === 'string' && url.includes('/cvad/manage/')) {
                if (!url.includes('/me')) {
                    headers['Citrix-InstanceId'] = this.params.siteId;
                }
            }
        }

        let response = null

        if (data !== null) {
            headers['Content-Type'] = 'application/x-www-form-urlencoded';
            const config = {
                headers,
                data,
            }
            response = await axios({
                method: 'post',
                url,
                headers,
                data,
                proxy: this.params.proxy ? this.params.proxy : undefined,
            })
        } else {
            response = await axios({
                method: 'get',
                url,
                headers,
                proxy: this.params.proxy ? this.params.proxy : undefined,
            })
        }

        if (response.status !== 200) {
            throw new Error(`Request failed with status code ${response.status}: ${JSON.stringify(response.data)}`);
        }

        try {
            return this.nextlink(response.data);
        } catch (error) {
            throw new Error('Failed to parse response received from API.');
        }
    }

    async nextlink(data) {
        let nextData = data;
        while ('nextLink' in nextData) {
            nextData = await this.request(nextData.nextLink);
            nextData.value.forEach((value) => {
                data.value.push(value);
            });
        }

        return data;
    }
}

module.exports = Citrix;