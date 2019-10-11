/* eslint-disable prettier/prettier */
/* eslint-disable no-undef */
/* eslint-disable no-unused-vars */
const encodeCall = require('@aragon/templates-shared/helpers/encodeCall')
const assertRevert = require('@aragon/templates-shared/helpers/assertRevert')(web3)

const { hash: namehash } = require('eth-ens-namehash')
const { APP_IDS } = require('@aragon/templates-shared/helpers/apps')
const { randomId } = require('@aragon/templates-shared/helpers/aragonId')
const { getEventArgument } = require('@aragon/test-helpers/events')
const { getENS, getTemplateAddress } = require('@aragon/templates-shared/lib/ens')(web3, artifacts)
const { getInstalledAppsById } = require('@aragon/templates-shared/helpers/events')(artifacts)
const { assertRole, assertMissingRole, assertRoleNotGranted } = require('@aragon/templates-shared/helpers/assertRole')(web3)

const CompanyTemplate = artifacts.require('HiveTemplate')

const ACL = artifacts.require('ACL')
const Kernel = artifacts.require('Kernel')
const Agent = artifacts.require('Agent')
const Vault = artifacts.require('Vault')
const Voting = artifacts.require('Voting')
const Payroll = artifacts.require('Payroll')
const Finance = artifacts.require('Finance')
const TokenManager = artifacts.require('TokenManager')
const MiniMeToken = artifacts.require('MiniMeToken')
const MockContract = artifacts.require('Migrations')
const PublicResolver = artifacts.require('PublicResolver')
const EVMScriptRegistry = artifacts.require('EVMScriptRegistry')

const ONE_DAY = 60 * 60 * 24
const ONE_WEEK = ONE_DAY * 7
const THIRTY_DAYS = ONE_DAY * 30
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'

contract('Hive Dao Template', () => {

    before('fetch hive template and ENS', async () => {
        ens = await getENS()
        template = HiveTemplate.at(await getTemplateAddress())
    })

    const finalizeInstance = (...params) => {
        const lastParam = params[params.length - 1]
        const txParams = (!Array.isArray(lastParam) && typeof lastParam === 'object') ? params.pop() : {}
        const finalizeInstanceFn = HiveTemplate.abi.find(({ name, inputs }) => name === 'finalizeInstance' && inputs.length === params.length)
        return template.sendTransaction(encodeCall(finalizeInstanceFn, params, txParams))
    }

    context('when the creation fails', () => {

        context('when there was no instance prepared before', () => {
            it('reverts when there was no instance prepared before', async () => {
                // add test
            })
        })

        context('when there was an instance already prepared', () => {
            before('prepare instance', async () => {
                // add test
            })

            it('reverts when no share members were given', async () => {
                // add test
            })

            it('reverts when number of shared members and stakes do not match', async () => {
                // add test
            })

            it('reverts when an empty id is provided', async () => {
                // add test
            })
        })
    })

    context('when the creation succeeds', () => {
        let prepareReceipt, finalizeInstanceReceipt

        const loadDAO = async (apps = { vault: false, agent: false, payroll: false }) => {
            // add test
        }

        const itCostsUpTo = expectedFinalizationCost => {
            it(`gas costs must be up to ~${expectedTotalCost} gas`, async () => {
                // add test
            })
        }
    })
})