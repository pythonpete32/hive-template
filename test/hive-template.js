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

const HiveTemplate = artifacts.require('HiveTemplate')

const ACL = artifacts.require('ACL')
const Kernel = artifacts.require('Kernel')
const Agent = artifacts.require('Agent')
const Vault = artifacts.require('Vault')
const Voting = artifacts.require('Voting')
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

    FINANCE_PERIOD = 60 * 60 * 24 * 15 // 15 days

    before('fetch hive template and ENS', async () => {
        ens = await getENS()
        template = HiveTemplate.at(await getTemplateAddress())

        // test if contract is over 24 KiB. im getting out of gas error
        console.log("  template length: ", template.constructor._json.deployedBytecode.length, "\n");
    })
})