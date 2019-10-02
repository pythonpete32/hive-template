pragma solidity 0.4.24;

import "@aragon/apps-shared-minime/contracts/MiniMeToken.sol";


contract HiveTemplate {
    string constant private ERROR_MISSING_TOKEN_CACHE = "TEMPLATE_MISSING_TOKEN_CACHE";

    struct TokenCache {
        address owner;
        MiniMeToken mbrToken;
        MiniMeToken mrtToken;
    }
    
    TokenCache tokenCache;




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
}