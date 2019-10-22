# 1Hive Template (WIP)


The 1Hive Template is intended to allow organisations to simply deploy a DAO with the same structure and permissions as the 1Hive DAO

## Publish
You can publish the template to the devchain with

```
publish:major:devchain
```

## Usage

creating a 1Hive DAO requires calling two functions. each creates a transaction

### Prepare an incomplete DAO:

```sh
    function prepareInstance(
        string    _memberTokenName,
        string    _memberTokenSymbol,
        address[] _members,
        uint64[3] _memberVotingSettings,
        uint64    _financePeriod
    )
```

<br/>

this can be run using AragonCli with the following command :

```sh
dao new --template hive-template-staging.open.aragonpm.eth --fn prepareInstance --fn-args "BeeToken" BEE ['"0x75B98710D5995AB9992F02492B7568b43133161D"']  ['"500000000000000000","50000000000000000","604800"'] 0
```

<br/>

### Finalize DAO: