/* eslint-disable*/

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
const HiveTemplate = artifacts.require('HiveTemplate')
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

contract('Hive Dao Template', ([_, owner, mbrHolder1, mbrHolder2, mrtHolder1, mrtHolder2, mrtHolder3, someone]) => {
    let daoID, template, dao, acl, ens
    let mbrVoting, mrtVoting, mbrTokenManager, mrtTokenManager, mbrToken, mrtToken, finance

    const MBR_HOLDERS = [mbrHolder1, mbrHolder2]
    const MBR_TOKEN_NAME = 'Member Token'
    const MBR_TOKEN_SYMBOL = 'MBR'

    const MRT_HOLDERS = [mrtHolder1, mrtHolder2, mrtHolder3]
    const MRT_STAKES = MRT_HOLDERS.map(() => 1e18)
    const MRT_TOKEN_NAME = 'Merit Token'
    const MRT_TOKEN_SYMBOL = 'MRT'

    const MBR_VOTE_DURATION = ONE_WEEK
    const MBR_SUPPORT_REQUIRED = 50e16
    const MBR_MIN_ACCEPTANCE_QUORUM = 40e16
    const MBR_VOTING_SETTINGS = [MBR_SUPPORT_REQUIRED, MBR_MIN_ACCEPTANCE_QUORUM, MBR_VOTE_DURATION]

    const MRT_VOTE_DURATION = ONE_WEEK
    const MRT_SUPPORT_REQUIRED = 50e16
    const MRT_MIN_ACCEPTANCE_QUORUM = 5e16
    const MRT_VOTING_SETTINGS = [MRT_SUPPORT_REQUIRED, MRT_MIN_ACCEPTANCE_QUORUM, MRT_VOTE_DURATION]

    const DOT_VOTE_DURATION = ONE_WEEK
    const DOT_SUPPORT_REQUIRED = 50e16
    const DOT_MIN_ACCEPTANCE_QUORUM = 5e16
    const DOT_VOTING_SETTINGS = [DOT_SUPPORT_REQUIRED, DOT_MIN_ACCEPTANCE_QUORUM, DOT_VOTE_DURATION]

    before('fetch hive template and ENS', async () => {
        ens = await getENS()
        template = HiveTemplate.at(await getTemplateAddress())

        // test if contract is over 24 KiB. im getting out of gas error
        console.log("  template length: ", template.constructor._json.deployedBytecode.length, "\n");
    })

    const finalizeInstance = (...params) => {
        const lastParam = params[params.length - 1]
        const txParams = (!Array.isArray(lastParam) && typeof lastParam === 'object') ? params.pop() : {}
        const finalizeInstanceFn = HiveTemplate.abi.find(({ name, inputs }) => name === 'finalizeInstance' && inputs.length === params.length)
        return template.sendTransaction(encodeCall(finalizeInstanceFn, params, txParams))
    }

    context('when the creation fails', () => {

        context('when there was no instance prepared before', () => {
            it('should revert when no board members are provided', async () => {
                await assertRevert(() =>
                    template.finalizeInstance(randomId(), MRT_HOLDERS, MRT_STAKES, DOT_VOTING_SETTINGS), 'TEMPLATE_MISSING_CACHE'), {
                        from: owner,
                    }
            })
        })

        context('preparing instance', () => {
            it('should revert when no member voting settings are provided', async () => {
                await assertRevert(() =>
                    template.prepareInstance(MBR_TOKEN_NAME, MBR_TOKEN_SYMBOL, MRT_TOKEN_NAME, MRT_TOKEN_SYMBOL, [], MRT_VOTING_SETTINGS, {
                        from: owner,
                    })
                )
            })

            it('should revert when no merit voting settings are provided', async () => {
                await assertRevert(() =>
                    template.prepareInstance(MBR_TOKEN_NAME, MBR_TOKEN_SYMBOL, MRT_TOKEN_NAME, MRT_TOKEN_SYMBOL, MBR_VOTING_SETTINGS, [], {
                        from: owner,
                    })
                )
            })
        })


        context('when there was an instance already prepared', () => {
            before('prepare instance', async () => {
                await template.prepareInstance(MBR_TOKEN_NAME, MBR_TOKEN_SYMBOL, MRT_TOKEN_NAME, MRT_TOKEN_SYMBOL, MBR_VOTING_SETTINGS, MRT_VOTING_SETTINGS)
            })

            it('should revert when no board members are provided', async () => {
                await assertRevert(() =>
                    template.prepareInstance(BOARD_TOKEN_NAME, BOARD_TOKEN_SYMBOL, [], BOARD_VOTING_SETTINGS, FINANCE_PERIOD, {
                        from: owner,
                    })
                )
            })

            it('reverts when no MRT holders were given', async () => {
                await assertRevert(() =>
                    template.finalizeInstance(randomId(), [], MRT_STAKES, DOT_VOTING_SETTINGS), 'EMPTY_HOLDERS'), {
                        from: owner,
                    }
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