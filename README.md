# deploy smart cotnract

```
yarn hardhat run scripts/deployProxy.js --network bsctest
npx hardhat verify --network bsctest 0xC201cCd970CbBd537C228fe5fDfD5fbC8Eff99A5
yarn hardhat run scripts/upgradeProxy.js --network bsctest
```

Implementation upgraded:  0xC201cCd970CbBd537C228fe5fDfD5fbC8Eff99A5
new implementation address:  0x1409565126527460336C359c9734415eAC7b7528

UpgradeableNFT (PROXY)  deployed to: 0x58538C3B09c8084c118902aD84fd6A058BE32A5E
getImplementationAddress: 0xe4e8e03d44Fc3e277C5Ecd109292aF024cf6299e

