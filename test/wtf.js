/* eslint-disable prettier/prettier */
const {
    getENS,
    getTemplateAddress,
} = require('@aragon/templates-shared/lib/ens')(web3, artifacts)

const HiveTemplate = artifacts.require('HiveTemplate')

module.exports = async (callback) => {
    const test = async () => {
        const ens = await getENS()
        console.log(`ens: `, ens, `\n`)
        const template = HiveTemplate.at(await getTemplateAddress())
        console.log(`template address: `, template, `\n`)

        return template
    }
    let t = await test()
    console.log(test().then(res => {
        console.log(res)
    }))
    console.log(t)


}

