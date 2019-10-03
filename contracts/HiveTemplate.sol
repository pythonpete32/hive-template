pragma solidity 0.4.24;

import "@aragon/apps-shared-minime/contracts/MiniMeToken.sol";
import "@aragon/templates-shared/contracts/BaseTemplate.sol";
import "./tps/AddressBook.sol";
import "./tps/Allocations.sol";
import "./tps/Rewards.sol";
import { DotVoting } from "./tps/DotVoting.sol";


contract HiveTemplate is BaseTemplate {
    string constant private ERROR_MISSING_TOKEN_CACHE = "TEMPLATE_MISSING_TOKEN_CACHE";
    string constant private ERROR_MINIME_FACTORY_NOT_PROVIDED = "TEMPLATE_MINIME_FAC_NOT_PROVIDED";

    string constant private ERROR_EMPTY_HOLDERS = "COMPANY_EMPTY_HOLDERS";
    string constant private ERROR_BAD_HOLDERS_STAKES_LEN = "COMPANY_BAD_HOLDERS_STAKES_LEN";
    string constant private ERROR_BAD_VOTE_SETTINGS = "COMPANY_BAD_VOTE_SETTINGS";

    uint64 constant PCT64 = 10 ** 16;
    address constant ANY_ENTITY = address(-1);

    struct TokenCache {
        address owner;
        MiniMeToken mbrToken;
        MiniMeToken mrtToken;
    }

    TokenCache tokenCache;

    constructor(DAOFactory _daoFactory, ENS _ens, MiniMeTokenFactory _miniMeFactory, IFIFSResolvingRegistrar _aragonID)
        BaseTemplate(_daoFactory, _ens, _miniMeFactory, _aragonID)
        public
    {
        _ensureAragonIdIsValid(_aragonID);
        _ensureMiniMeFactoryIsValid(_miniMeFactory);
    }

    /**
    * @dev cretaes a new 1Hive DAO with no args for testing
     */
    function newTokensAndInstance() external {
        uint64[3] memory voteSettings = [uint64(50 ** 16), uint64(50 ** 16), uint64(259200)];
        address[] memory holders;
        uint256[] memory stakes;

        holders[0] = msg.sender;
        stakes[0] = uint256(1 ** 18);

        newTokensAndInstance(
            "BEE Token",
            "BEE",
            "HONEY Token",
            "HONEY",
            "1Hive",
            holders,
            stakes,
            voteSettings,
            voteSettings,
            voteSettings
        );
    }

    /**
    * @dev Create two new MiniMe token and deploy a 1hive DAO.
    * @param _mbrName String with the name for the token used by members in the organization
    * @param _mbrSymbol String with the symbol for the token used by members in the organization
    * @param _mrtName String with the name for the token used as merit in the organization
    * @param _mrtSymbol String with the symbol for the token used as merit in the organization
    * @param _id String with the name for org, will assign `[id].aragonid.eth`
    * @param _holders Array of member token holder addresses
    * @param _stakes Array of token merit stakes for member token holders holders (token has 18 decimals, multiply token amount `* 10^18`)
    * @param _mbrVotingSettings Array of [supportRequired, minAcceptanceQuorum, voteDuration] to set up the member voting app of the organization
    * @param _mrtVotingSettings Array of [supportRequired, minAcceptanceQuorum, voteDuration] to set up the merit voting app of the organization
    * @param _dotVotingSettings Array of [_minQuorum, _candidateSupportPct, _voteTime] to set up the dot voting app of the organization
    */
    function newTokensAndInstance(
        string _mbrName,
        string _mbrSymbol,
        string _mrtName,
        string _mrtSymbol,
        string _id,
        address[] _holders,
        uint256[] _stakes,
        uint64[3] _mbrVotingSettings,
        uint64[3] _mrtVotingSettings,
        uint64[3] _dotVotingSettings
    )
        public
    {
        newTokens(_mbrName, _mbrSymbol,_mrtName, _mrtSymbol);
        newInstance(_id, _holders, _stakes, _mbrVotingSettings, _mrtVotingSettings, _dotVotingSettings);
    }

    /**
    * @dev Create two new MiniMe token and cache them for the user
    * @param _mbrName String with the name for the token used by members in the organization
    * @param _mbrSymbol String with the symbol for the token used by members in the organization
    * @param _mbrName String with the name for the token used for merit in the organization
    * @param _mbrSymbol String with the symbol for the token used for metit in the organization
    */
    function newTokens(
        string memory _mbrName,
        string memory _mbrSymbol,
        string memory _mrtName,
        string memory _mrtSymbol
    )
    public returns (MiniMeToken, MiniMeToken)
    {
        MiniMeToken mbrToken = _createNonTransferableToken(_mbrName, _mbrSymbol);
        MiniMeToken mrtToken = _createTransferableToken(_mrtName, _mrtSymbol);
        _cacheTokens(mbrToken, mrtToken, msg.sender);
        return (mbrToken, mrtToken);
    }

    /**
    * @dev Deploy a 1Hive DAO using previously cached MiniMe tokens
    * @param _id String with the name for org, will assign `[id].aragonid.eth`
    * @param _holders Array of token holder addresses
    * @param _stakes Array of merit token stakes for holders (token has 18 decimals, multiply token amount `* 10^18`)
    * @param _mbrVotingSettings Array of [supportRequired, minAcceptanceQuorum, voteDuration] to set up the voting app of the organization
    * @param _mrtVotingSettings Array of [supportRequired, minAcceptanceQuorum, voteDuration] to set up the voting app of the organization
    * @param _dotVotingSettings Array of [_minQuorum, _candidateSupportPct, _voteTime] to set up the dot voting app of the organization
    */

    function newInstance(
        string memory _id,
        address[] memory _holders,
        uint256[] memory _stakes,
        uint64[3] memory _mbrVotingSettings,
        uint64[3] memory _mrtVotingSettings,
        uint64[3] _dotVotingSettings
    )
        public
    {
        _ensureDAOSettings(_holders, _stakes, _mbrVotingSettings, _mrtVotingSettings);

        (Kernel dao, ACL acl) = _createDAO();

        (
            Voting mbrVoting,
            Voting mrtVoting,
            MiniMeToken mrtToken,
            Vault vault
        ) = _setupApps(dao, acl, _holders, _stakes, _mbrVotingSettings, _mrtVotingSettings);

        _setupTps(dao, acl, mrtToken, vault, _dotVotingSettings,  mbrVoting,  mrtVoting);
        _transferRootPermissionsFromTemplateAndFinalizeDAO(dao, mbrVoting);
        _registerID(_id, dao);
    }

    // --------------------------- Internal Functions ---------------------------
    function _cacheTokens(MiniMeToken _mbrToken, MiniMeToken _mrtToken, address _owner) internal {
        tokenCache = TokenCache(_owner, _mbrToken, _mrtToken);
    }

    function _popTokenCache(address _owner) internal returns (MiniMeToken, MiniMeToken) {
        require(tokenCache.owner != address(0), ERROR_MISSING_TOKEN_CACHE);

        MiniMeToken mbrToken = tokenCache.mbrToken;
        MiniMeToken mrtToken = tokenCache.mrtToken;

        delete tokenCache.mbrToken;
        delete tokenCache.mrtToken;
        delete tokenCache.owner;

        return (mbrToken, mrtToken);
    }

    // ***** i didn't use createToken from basetemplate because i coudnt set transferability *****
    function _createTransferableToken(string memory _name, string memory _symbol) internal returns (MiniMeToken) {
        require(address(miniMeFactory) != address(0), ERROR_MINIME_FACTORY_NOT_PROVIDED);
        MiniMeToken token = miniMeFactory.createCloneToken(MiniMeToken(address(0)), 0, _name, 18, _symbol, true);
        emit DeployToken(address(token));
        return token;
    }

    // ***** i didn't use createToken from basetemplate because i coudnt set transferability *****
    function _createNonTransferableToken(string memory _name, string memory _symbol) internal returns (MiniMeToken) {
        require(address(miniMeFactory) != address(0), ERROR_MINIME_FACTORY_NOT_PROVIDED);
        MiniMeToken token = miniMeFactory.createCloneToken(MiniMeToken(address(0)), 0, _name, 0, _symbol, false);
        emit DeployToken(address(token));
        return token;
    }

    function _setupApps(
        Kernel _dao,
        ACL _acl,
        address[] memory _holders,
        uint256[] memory _stakes,
        uint64[3] memory _mbrVotingSettings,
        uint64[3] memory _mrtVotingSettings
    )
        internal
        returns (Voting, Voting, MiniMeToken, Vault)
    {
        (MiniMeToken mbrToken, MiniMeToken mrtToken) = _popTokenCache(msg.sender);
        Vault vault = _installVaultApp(_dao);

        TokenManager mbrTokenManager = _installTokenManagerApp(_dao, mbrToken, false, uint256(1));
        TokenManager mrtTokenManager = _installTokenManagerApp(_dao, mrtToken, true, uint256(0));

        Voting mbrVoting = _installVotingApp(_dao, mbrToken, _mbrVotingSettings);
        Voting mrtVoting = _installVotingApp(_dao, mrtToken, _mrtVotingSettings);

        _mintTokens(_acl, mbrTokenManager, _holders, _stakes);
        _mintTokens(_acl, mrtTokenManager, _holders, _stakes);

        _setupPermissions(_acl, vault, mbrVoting, mrtVoting, mbrTokenManager, mrtTokenManager);

        return (mbrVoting, mrtVoting, mrtToken, vault);
    }

    function _setupTps(
        Kernel _dao,
        ACL _acl,
        MiniMeToken _mrtToken,
        Vault _vault,
        uint64[3] _dotVotingSettings,
        Voting _mbrVoting,
        Voting _mrtVoting
    )
        internal
    {
        AddressBook addressBook = _installAddressBook(_dao);
        DotVoting dotVoting = _installDotVoting(_dao, _mrtToken, _dotVotingSettings);
        Allocations allocations = _installAllocations(_dao, addressBook, _vault);
        Rewards rewards = _installRewards(_dao, _vault);

        _setupTpsPermissions(_acl, addressBook, dotVoting, allocations, rewards, _mbrVoting, _mrtVoting);
    }

    function _installDotVoting (
        Kernel _dao,
        MiniMeToken _mrtToken,
        uint64[3] _dotVotingSettings
    ) internal returns (DotVoting)
    {
        bytes32 dotVotingAppId = apmNamehash("dot-voting");

        DotVoting dotVoting = DotVoting(
            _dao.newAppInstance(dotVotingAppId, _latestVersionAppBase(dotVotingAppId))
        );

        dotVoting.initialize(_mrtToken, _dotVotingSettings[0], _dotVotingSettings[1], _dotVotingSettings[2]);
        return dotVoting;
    }

    function _installAddressBook (Kernel _dao) internal returns (AddressBook) {
        bytes32 addressBookAppId = apmNamehash("address-book");

        AddressBook addressBook = AddressBook(
            _dao.newAppInstance(addressBookAppId, _latestVersionAppBase(addressBookAppId))
        );

        addressBook.initialize();
        return addressBook;
    }

    function _installAllocations (Kernel _dao, AddressBook _addressBook, Vault _vault ) internal returns (Allocations) {
        bytes32 allocationsAppId = apmNamehash("allocations");

        Allocations allocations = Allocations(
            _dao.newAppInstance(allocationsAppId, _latestVersionAppBase(allocationsAppId))
        );

        allocations.initialize(_addressBook, _vault);
        return allocations;
    }

    function _installRewards(Kernel _dao, Vault _vault) internal returns (Rewards) {
        bytes32 rewardsAppId = apmNamehash("rewards");

        Rewards rewards = Rewards(
            _dao.newAppInstance(rewardsAppId, _latestVersionAppBase(rewardsAppId))
        );

        rewards.initialize(_vault);
        return rewards;
    }

    function _setupTpsPermissions(
        ACL acl,
        AddressBook addressBook,
        DotVoting dotVoting,
        Allocations allocations,
        Rewards rewards,
        Voting mbrVoting,
        Voting mrtVoting
    )
        internal
    {
        acl.createPermission(mbrVoting, addressBook, addressBook.ADD_ENTRY_ROLE(), mbrVoting);
        acl.createPermission(mbrVoting, addressBook, addressBook.REMOVE_ENTRY_ROLE(), mbrVoting);
        emit InstalledApp(addressBook, apmNamehash("address-book"));


        /**  Projects permissions: <-- add these after i include projects app
        acl.createPermission(voting, projects, projects.FUND_ISSUES_ROLE(), voting);
        acl.createPermission(voting, projects, projects.ADD_REPO_ROLE(), voting);
        acl.createPermission(voting, projects, projects.CHANGE_SETTINGS_ROLE(), voting);
        acl.createPermission(dotVoting, projects, projects.CURATE_ISSUES_ROLE(), voting);
        acl.createPermission(voting, projects, projects.REMOVE_REPO_ROLE(), voting);
        acl.createPermission(voting, projects, projects.REVIEW_APPLICATION_ROLE(), voting);
        acl.createPermission(voting, projects, projects.WORK_REVIEW_ROLE(), voting);
        emit InstalledApp(projects, planningAppIds[uint8(PlanningApps.Projects)]);
        */

        // Dot-voting permissions
        acl.createPermission(ANY_ENTITY, dotVoting, dotVoting.ROLE_CREATE_VOTES(), mbrVoting);
        acl.createPermission(ANY_ENTITY, dotVoting, dotVoting.ROLE_ADD_CANDIDATES(), mbrVoting);
        emit InstalledApp(dotVoting, apmNamehash("dot-voting"));

        // Allocations permissions:
        acl.createPermission(mbrVoting, allocations, allocations.CREATE_ACCOUNT_ROLE(), mbrVoting);
        acl.createPermission(dotVoting, allocations, allocations.CREATE_ALLOCATION_ROLE(), mbrVoting);
        acl.createPermission(ANY_ENTITY, allocations, allocations.EXECUTE_ALLOCATION_ROLE(), mbrVoting);
        emit InstalledApp(allocations, apmNamehash("allocations"));

        // Rewards permissions:
        acl.createPermission(mbrVoting, rewards, rewards.ADD_REWARD_ROLE(), mbrVoting);
        emit InstalledApp(rewards, apmNamehash("rewards"));
    }

    function _setupPermissions(
        ACL _acl,
        Vault _vault,
        Voting _mbrVoting,
        Voting _mrtVoting,
        TokenManager _mbrTokenManager,
        TokenManager _mrtTokenManager
    )
        internal
    {

        _createVaultPermissions(_acl, _vault, _mbrVoting, _mbrVoting);
        _createVotingPermissions(_acl, _mbrVoting, _mbrVoting, _mbrTokenManager, _mbrVoting);
        _createVotingPermissions(_acl, _mrtVoting, _mrtVoting, _mrtTokenManager, _mbrVoting);
        _createEvmScriptsRegistryPermissions(_acl, _mbrVoting, _mbrVoting);
        _createTokenManagerPermissions(_acl, _mbrTokenManager, _mbrVoting, _mbrVoting);
        _createTokenManagerPermissions(_acl, _mrtTokenManager, _mrtVoting, _mbrVoting);
    }

    function _ensureDAOSettings(
        address[] memory _holders,
        uint256[] memory _stakes,
        uint64[3] memory _mbrVotingSettings,
        uint64[3] memory _mrtVotingSettings
    ) private pure
    {
        require(_holders.length > 0, ERROR_EMPTY_HOLDERS);
        require(_holders.length == _stakes.length, ERROR_BAD_HOLDERS_STAKES_LEN);
        require(_mbrVotingSettings.length == 3, ERROR_BAD_VOTE_SETTINGS);
        require(_mrtVotingSettings.length == 3, ERROR_BAD_VOTE_SETTINGS);
    }
}