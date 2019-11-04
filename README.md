# 1Hive Template (WIP)


The 1Hive Template is intended to allow organisations to simply deploy a DAO with the same structure and permissions as the 1Hive DAO


## Development
#### Deploy Template To devchain
clone this repo with 
``` 
https://github.com/pythonpete32/hive-template.git
``` 
and install the deps with 
```
npm i
```
open three terminal windows, in the first start the devchain with
```
aragon devchain --verbose
```
in the second start IPFS with
```
aragon ipfs
```
and in the third you will deploy the template to your local APM on the devchain with 
```
npm run publish:aragen
```
#### launch template instance
once the template is on your local APM you can create a instance with

```
dao new --template hive-template-staging.open.aragonpm.eth --fn testTemplate --fn-args ['"0x75B98710D5995AB9992F02492B7568b43133161D"']  ['"500000000000000000","50000000000000000","604800"']
```

#### Interact with the DAO

you can interact with the DAO using the CLI, if you want to see the results in the client you have to intstall the client localy
```
git clone https://github.com/aragon/aragon.git
```
then install with 

```
npm i
```
you can then run the client with 
```
npm run start:local
```
