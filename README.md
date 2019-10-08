# 1Hive Template (WIP)


The 1Hive Template is intended to allow organisations to simply deploy a DAO with the same structure and permissions as the 1Hive DAO

## Usage

creating a 1Hive DAO requires calling two functions. each creates a transaction

### Prepare an incomplete DAO:

```sh
    function prepareInstance(
        string memory mbrName,
        string memory mbrSymbol,
        string memory mrtName,
        string memory mrtSymbol,
        uint64[3] mbrVotingSettings,
        uint64[3] mrtVotingSettings
    )
```


- `mbrName`: String with the name for the token used by members in the organization
- `mbrSymbol`: String with the symbol for the token used by members in the organization
- `mbrName`: String with the name for the token used for merit in the organization
- `mbrSymbol`: String with the symbol for the token used for metit in the organization
- `mbrVotingSettings`: Array of [supportRequired, minAcceptanceQuorum, voteDuration] to set up the member voting app of the organization
- `mrtVotingSettings`: Array of [supportRequired, minAcceptanceQuorum, voteDuration] to set up the merit voting app of the organization

<br/>

this can be run using AragonCli with the following command :

```sh
dao new --template hive-template --fn prepareInstance --fn-args "Bee Token" BEE "Honey Token" HONEY  ['"500000000000000000","50000000000000000","604800"'] ['"500000000000000000","50000000000000000","604800"'] --environment aragon:rinkeby
```

<br/>

### Finalize DAO:

```sh
    function finalizeInstance(
        string memory id,
        address[] memory holders,
        uint256[] memory stakes,
        uint64[3] dotVotingSettings
    )
```

- `id`: String with the name for org, will assign `[id].aragonid.eth`
- `holders`: Array of token holder addresses
- `stakes`: Array of merit token stakes for holders (token has 18 decimals, multiply token amount `* 10^18`)
- `dotVotingSettings`: Array of [minQuorum, candidateSupportPct, voteTime] to set up the dot voting app of the organization

<br/>

this can be run using AragonCli with the following command :

```sh
dao new --template hive-template --fn finaliseInstance --fn-args "BeeHive" ['"0x123456789abcdef0123456789abcdef","0xabcdef9876543210abcdef0987654321"'] ['"1000000000000000000","1000000000000000000"'] ['"500000000000000000","50000000000000000","604800"'] --environment aragon:rinkeby
```