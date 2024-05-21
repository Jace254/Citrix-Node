async function sync(start = [], data, n,  callback) {
    if(n === 0) {
        const item =  await callback(data[n])
        const newStart = [...start, item]
        return newStart
    } else {
        const newData = data.filter(d => d !== data[n])
        const newItem = await callback(data[n])
        const newStart = [...start, newItem]
        return sync(newStart, newData, newData.length-1, callback)
    }
}

module.exports = sync