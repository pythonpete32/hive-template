pragma solidity 0.4.24;

import "@aragon/apps-shared-minime/contracts/MiniMeToken.sol";
import "@aragon/templates-shared/contracts/BaseTemplate.sol";


contract HiveTemplate is BaseTemplate {
    string constant private ERROR_MISSING_TOKEN_CACHE = "TEMPLATE_MISSING_TOKEN_CACHE";
    string constant private ERROR_MINIME_FACTORY_NOT_PROVIDED = "TEMPLATE_MINIME_FAC_NOT_PROVIDED";

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
}