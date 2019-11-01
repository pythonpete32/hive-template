pragma solidity 0.4.24;

import "@aragon/apps-shared-minime/contracts/MiniMeToken.sol";
import "@aragon/templates-shared/contracts/BaseTemplate.sol";
import "./tps/AddressBook.sol";
import "./tps/Allocations.sol";
import "./tps/Rewards.sol";
import { DotVoting } from "./tps/DotVoting.sol";

contract HiveTemplate is BaseTemplate {
    string constant private ERROR_MISSING_CACHE =               "TEMPLATE_MISSING_CACHE";
    string constant private ERROR_MINIME_FACTORY_NOT_PROVIDED = "TEMPLATE_MINIME_FAC_NOT_PROVIDED";
    string constant private ERROR_EMPTY_HOLDERS =               "EMPTY_HOLDERS";
    string constant private ERROR_BAD_HOLDERS_STAKES_LEN =      "BAD_HOLDERS_STAKES_LEN";
    string constant private ERROR_BAD_VOTE_SETTINGS =           "BAD_VOTE_SETTINGS";
    string constant private ERROR_BAD_MEMBER_SETTINGS =         "MEMBERS_CANNOT_BE_0";


    //TODO: change for rinkeby
    bytes32 constant internal ADDRESS_BOOK_APP_ID = apmNamehash("address-book");      // address-book.aragonpm.eth address-book
    bytes32 constant internal ALLOCATIONS_APP_ID =  apmNamehash("allocations");       // allocations.aragonpm.eth;
    bytes32 constant internal DOT_VOTING_APP_ID =   apmNamehash("dot-voting");        // dot-voting.aragonpm.eth;
    bytes32 constant internal REWARDS_APP_ID =      apmNamehash("rewards");           // rewards.aragonpm.eth;

    uint64 constant private DEFAULT_FINANCE_PERIOD =     uint64(30 days);
    uint64 constant private DEFAULT_ALLOCATIONS_PERIOD = uint64(30 days);

    bool private constant MERIT_TRANSFERABLE =       true;
    uint8 private constant MERIT_TOKEN_DECIMALS =    uint8(18);
    uint256 private constant MERIT_MAX_PER_ACCOUNT = uint256(0);

    uint64 constant PCT64 =         10 ** 16;
    address constant ANY_ENTITY =   address(-1);

    struct Cache {
        address dao;
        address mbrTokenManager;
        address mrtTokenManager;
        address mbrVoting;
        address mrtVoting;
        address addressBook;
        address vault;
        address allocationsVault;
        address allocations;
        address dotVoting;
        address finance;
    }

    mapping (address => Cache) private cache;

    constructor(
        DAOFactory              _daoFactory,
        ENS                     _ens,
        MiniMeTokenFactory      _miniMeFactory,
        IFIFSResolvingRegistrar _aragonID
    )
        BaseTemplate(_daoFactory, _ens, _miniMeFactory, _aragonID)
        public
    {
        _ensureAragonIdIsValid(_aragonID);
        _ensureMiniMeFactoryIsValid(_miniMeFactory);
    }

    // ------------------------------------- EXTERNAL FUNCTIONS ------------------------------------- //

    function newTokenAndDao(
        address[] _members,
        uint64[3] _memberVotingSettings
    )
    external
    {
        prepareInstance("BeeToken", "BEE", _members, _memberVotingSettings, 0);
        setupApps("HoneyToken", "HONEY", 0, _memberVotingSettings, _memberVotingSettings);
        finalizeInstance("TheHive");
    }

    function prepareInstance(
        string    _memberTokenName,
        string    _memberTokenSymbol,
        address[] _members,
        uint64[3] _memberVotingSettings,
        uint64    _financePeriod
    )
        public
    {
        _ensureHoldersNotZero(_members);
        _ensureVotingSettings(_memberVotingSettings);

        // deploy DAO
        (Kernel dao, ACL acl) = _createDAO();
        // deploy member token
        MiniMeToken memberToken = _createToken(_memberTokenName, _memberTokenSymbol, uint8(0));
        // install member apps
        TokenManager memberTokenManager = _installMemberApps(dao, memberToken, _memberVotingSettings, _financePeriod);
        // mint member tokens
        _mintTokens(acl, memberTokenManager, _members, 1);
        // cache DAO
        _cacheDao(dao);
    }

    function setupApps(
        string    _meritTokenName,
        string    _meritTokenSymbol,
        uint64    _allocationPeriod,
        uint64[3] _meritVotingSettings,
        uint64[3] _dotVotingSettings
    )
        public
    {
        _ensureVotingSettings(_meritVotingSettings, _dotVotingSettings);
        _ensureMemberAppsCache();

        Kernel dao = _daoCache();
        // deploy Merit token
        MiniMeToken meritToken = _createToken(_meritTokenName, _meritTokenSymbol, MERIT_TOKEN_DECIMALS);
        // install Merit apps
        _installMeritApps(dao, meritToken, _allocationPeriod, _meritVotingSettings, _dotVotingSettings);

        _setupMemberPermissions(dao);
    }

    // TODO: probably dont need to make this a separate tx, will fit into the stack limit but not sure about gas
    function finalizeInstance(string _id) public {

        _ensureMeritAppsCache();

        Kernel dao = _daoCache();
        ACL acl = ACL(dao.acl());
        (,Voting memberVoting, , ,) = _memberAppsCache();

         //setup merit apps permissions
        _setupMeritPermissions(dao);
         //setup EVM script registry permissions
        _createEvmScriptsRegistryPermissions(acl, memberVoting, memberVoting);
         //clear DAO permissions
        _transferRootPermissionsFromTemplateAndFinalizeDAO(dao, memberVoting, memberVoting);
        // register id
        //_registerID(_id, dao);
        // clear cache
        _clearCache();
    }

    // ------------------------------------- INTERNAL FUNCTIONS ------------------------------------- //

    // ######################
    // #     Setup Steps    #
    // ######################

    function _installMemberApps(Kernel _dao, MiniMeToken _token, uint64[3] _votingSettings, uint64 _financePeriod)
        internal
        returns (TokenManager)
    {
        TokenManager memberTokenManager = _installTokenManagerApp(_dao, _token, false, uint256(1));
        Voting voting = _installVotingApp(_dao, _token, _votingSettings);
        Vault mainVault = _installVaultApp(_dao);
        Finance finance = _installFinanceApp(_dao, mainVault, _financePeriod == 0 ? DEFAULT_FINANCE_PERIOD : _financePeriod);
        AddressBook addressBook = _installAddressBookApp(_dao);

        _cacheMemberApps(memberTokenManager, voting, mainVault, finance, addressBook);

        return memberTokenManager;
    }

    // TODO: add Projects

    // TODO: Add Allocations back in
    function _installMeritApps(
        Kernel           _dao,
        MiniMeToken      _token,
        uint64           _period,
        uint64[3] memory _votingSettings,
        uint64[3] memory _dotVotingSettings

    )
        internal
        returns (TokenManager)
    {
        TokenManager meritTokenManager = _installTokenManagerApp(_dao, _token, true, uint256(18));
        Voting meritVoting = _installVotingApp(_dao, _token, _votingSettings);
        Vault allocationsVault = _installVaultApp(_dao);


        //Allocations allocations = _installAllocationsApp(_dao, allocationsVault, _period == 0 ? DEFAULT_ALLOCATIONS_PERIOD : _period);
        DotVoting dotVoting = _installDotVotingApp(_dao, _token, _dotVotingSettings);

        // TODO: add allocations back in
        _cacheMeritApps(meritTokenManager, meritVoting, allocationsVault, dotVoting);

    }

    // ######################
    // #  Setup Permissions #
    // ######################


        // TODO: none of these permissions are correct as per the canonical 1Hive DAO
    function _setupMemberPermissions(Kernel _dao) internal {
        ACL acl = ACL(_dao.acl());

        (TokenManager memberTokenManager,
        Voting        memberVoting,
        Vault         vault,
        Finance       finance,
        AddressBook   addressBook) = _memberAppsCache();

        // token manager
        _createTokenManagerPermissions(acl, memberTokenManager, memberVoting, memberVoting);
        // voting
        _createVotingPermissions(acl, memberVoting, memberVoting, memberTokenManager, memberVoting);
        // vault
        _createVaultPermissions(acl, vault, finance, memberVoting);
        // finance
        _createFinancePermissions(acl, finance, memberVoting, memberVoting);
        _createFinanceCreatePaymentsPermission(acl, finance, memberVoting, memberVoting);
        // address book
        _createAddressBookPermissions(acl, addressBook, memberVoting, memberVoting);
    }

    // TODO: none of these permissions are correct as per the canonical 1Hive DAO
    // TODO: add allocations back in
    function _setupMeritPermissions(Kernel _dao) internal {
        ACL acl = ACL(_dao.acl());

        
        (TokenManager meritTokenManager,
        Voting        meritVoting,
        Vault         allocationsVault,
        DotVoting     dotVoting) = _meritAppsCache();

        (,Voting memberVoting, , , ) = _memberAppsCache();

        // token manager
        _createTokenManagerPermissions(acl, meritTokenManager, meritVoting, memberVoting);
        // voting
        _createVotingPermissions(acl, meritVoting, meritVoting, meritTokenManager, memberVoting);
        // vault
        //_createVaultPermissions(_acl, _vault, _grantee, _manager);
        // allocations
        // _createAllocationsPermissions(acl, allocations, dotVoting, memberVoting, memberVoting);
        // dot voting
        _createDotVotingPermissions(acl, dotVoting, memberVoting, memberVoting);
    }

    // ######################
    // #     App Helpers    #
    // ######################

    // *** ADDRESS BOOK ***
    function _installAddressBookApp(Kernel _dao) internal returns (AddressBook) {
        bytes memory initializeData = abi.encodeWithSelector(AddressBook(0).initialize.selector);
        return AddressBook(_installNonDefaultApp(_dao, ADDRESS_BOOK_APP_ID, initializeData));
    }

    function _createAddressBookPermissions(ACL _acl, AddressBook _addressBook, address _grantee, address _manager) internal {
        _acl.createPermission(_grantee, _addressBook, _addressBook.ADD_ENTRY_ROLE(), _manager);
        _acl.createPermission(_grantee, _addressBook, _addressBook.REMOVE_ENTRY_ROLE(), _manager);
        _acl.createPermission(_grantee, _addressBook, _addressBook.UPDATE_ENTRY_ROLE(), _manager);
    }

    // *** ALLOCATIONS ***
    function _installAllocationsApp(Kernel _dao, Vault _vault, uint64 _periodDuration) internal returns (Allocations) {
        bytes memory initializeData = abi.encodeWithSelector(Allocations(0).initialize.selector, _vault, _periodDuration);
        return Allocations(_installNonDefaultApp(_dao, ALLOCATIONS_APP_ID, initializeData));
    }

    function _createAllocationsPermissions(
        ACL         _acl,
        Allocations _allocations,
        address     _createAllocationsGrantee,
        address     _createAccountsGrantee,
        address     _manager
    )
        internal
    {
        _acl.createPermission(_createAccountsGrantee, _allocations, _allocations.CREATE_ACCOUNT_ROLE(), _manager);
        _acl.createPermission(_createAccountsGrantee, _allocations, _allocations.CHANGE_BUDGETS_ROLE(), _manager);
        _acl.createPermission(_createAllocationsGrantee, _allocations, _allocations.CREATE_ALLOCATION_ROLE(), _manager);
        _acl.createPermission(ANY_ENTITY, _allocations, _allocations.EXECUTE_ALLOCATION_ROLE(), _manager);
        _acl.createPermission(ANY_ENTITY, _allocations, _allocations.EXECUTE_PAYOUT_ROLE(), _manager);
    }

    // *** DOT VOTING ***

    // _dotVotingSettings Array of [minQuorum, candidateSupportPct, voteDuration] to set up the dot voting app of the organization
    function _installDotVotingApp(Kernel _dao, MiniMeToken _token, uint64[3] memory _dotVotingSettings) internal returns (DotVoting) {
        return _installDotVotingApp(_dao, _token, _dotVotingSettings[0], _dotVotingSettings[1], _dotVotingSettings[2]);
    }

    function _installDotVotingApp(
        Kernel      _dao,
        MiniMeToken _token,
        uint64      _quorum,
        uint64      _support,
        uint64      _duration
    )
        internal returns (DotVoting)
    {
        bytes memory initializeData = abi.encodeWithSelector(DotVoting(0).initialize.selector, _token, _quorum, _support, _duration);
        return DotVoting(_installNonDefaultApp(_dao, DOT_VOTING_APP_ID, initializeData));
    }

    function _createDotVotingPermissions(
        ACL       _acl,
        DotVoting _dotVoting,
        address   _grantee,
        address   _manager
    )
        internal
    {
        //TODO: we should pass _tokenManager into ROLE_CREATE_VOTES as 2nd param, not _dotVoting
        _acl.createPermission(_grantee, _dotVoting, _dotVoting.ROLE_CREATE_VOTES(), _manager);
        _acl.createPermission(_grantee, _dotVoting, _dotVoting.ROLE_ADD_CANDIDATES(), _manager);
    }

    // ######################
    // #       Caching      #
    // ######################

    // *** DAO ***
    function _cacheDao(Kernel _dao) internal {
        Cache storage c = cache[msg.sender];

        c.dao = address(_dao);
    }

    function _daoCache() internal returns (Kernel dao) {
        Cache storage c = cache[msg.sender];

        dao = Kernel(c.dao);
    }

    // *** MEMBER APPS ***
    function _cacheMemberApps(
        TokenManager _memberTokenManager,
        Voting       _memberVoting,
        Vault        _vault,
        Finance      _finance,
        AddressBook  _addressBook
    ) internal
    {
        Cache storage c = cache[msg.sender];

        c.mbrTokenManager = address(_memberTokenManager);
        c.mbrVoting = address(_memberVoting);
        c.vault = address(_vault);
        c.finance = address(_finance);
        c.addressBook = address(_addressBook);
    }

    function _memberAppsCache() internal returns (
        TokenManager memberTokenManager,
        Voting memberVoting,
        Vault vault,
        Finance finance,
        AddressBook addressBook
    )
    {
        Cache storage c = cache[msg.sender];

        memberTokenManager = TokenManager(c.mbrTokenManager);
        memberVoting = Voting(c.mbrVoting);
        vault = Vault(c.vault);
        finance = Finance(c.finance);
        addressBook = AddressBook(c.addressBook);
    }

    // *** MERIT APPS ***
    // TODO: add allocations back in 
    function _cacheMeritApps(
        TokenManager _meritTokenManager,
        Voting       _meritVoting,
        Vault        _allocationsVault,
        DotVoting    _dotVoting
    ) internal
    {
        Cache storage c = cache[msg.sender];

        c.mrtTokenManager = address(_meritTokenManager);
        c.mrtVoting = address(_meritVoting);
        c.allocationsVault = address(_allocationsVault);
        // c.allocations = address(_allocations);
        c.dotVoting = address(_dotVoting);
    }

    // TODO: add allocations back in
    function _meritAppsCache() internal returns(
        TokenManager meritTokenManager,
        Voting       meritVoting,
        Vault        allocationsVault,
        DotVoting    dotVoting
    )
    {
        Cache storage c = cache[msg.sender];

        meritTokenManager = TokenManager(c.mrtTokenManager);
        meritVoting = Voting(c.mrtVoting);
        allocationsVault = Vault(c.allocationsVault);
        // allocations = Allocations(c.allocations);
        dotVoting = DotVoting(c.dotVoting);
    }

    // *** CLEAR CACHE ***
    // TODO: add allocations
    function _clearCache() internal {
        Cache storage c = cache[msg.sender];

        delete c.dao;
        delete c.mbrTokenManager;
        delete c.mrtTokenManager;
        delete c.mbrVoting;
        delete c.mrtVoting;
        delete c.addressBook;
        delete c.vault;
        delete c.allocationsVault;
        //delete c.allocations;
        delete c.dotVoting;
        delete c.finance;
    }

    // ######################
    // #      Modifiers     #
    // ######################

    function _ensureHolderSettings(address[] memory _holders, uint256[] memory _stakes) private pure {
        require(_holders.length > 0, ERROR_EMPTY_HOLDERS);
        require(_holders.length == _stakes.length, ERROR_BAD_HOLDERS_STAKES_LEN);
    }

    function _ensureVotingSettings( uint64[3] memory _votingSettings1, uint64[3] memory _votingSettings2) private pure {
        require(_votingSettings1.length == 3, ERROR_BAD_VOTE_SETTINGS);
        require(_votingSettings2.length == 3, ERROR_BAD_VOTE_SETTINGS);
    }

    function _ensureVotingSettings(uint64[3] memory _votingSettings) private pure {
        require(_votingSettings.length == 3, ERROR_BAD_VOTE_SETTINGS);
    }

    function _ensureHoldersNotZero(address[] _holders) private pure {
        require(_holders.length > 0, ERROR_EMPTY_HOLDERS);
    }

    function _ensureMemberAppsCache() private view {
        Cache storage c = cache[msg.sender];

        require(
            c.mbrTokenManager != address(0) &&
            c.mbrVoting != address(0) &&
            c.vault != address(0) &&
            c.finance != address(0) &&
            c.addressBook != address(0),

            ERROR_MISSING_CACHE
        );
    }

    // TODO: add allocations
    function _ensureMeritAppsCache() private view {
        Cache storage c = cache[msg.sender];
        require(
            c.mrtTokenManager != address(0) &&
            c.mrtVoting != address(0) &&
            c.allocationsVault != address(0) &&
            //c.allocations != address(0) &&
            c.dotVoting != address(0),

            ERROR_MISSING_CACHE
        );
    }
}