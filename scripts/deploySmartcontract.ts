import { ethers, hardhatArguments, upgrades } from "hardhat";
import fs from "fs";
import { NFTUpgradeable, MarketUpgradeable, WhiteListUpgradeable} from "typechain";

let DEPLOY_TYPE = 1; // 0: NFT, 1: Market, 2: WhiteList

const CONTRACT_NAME_0 = "NFTUpgradeable" // Change this line if you changed the contract name on contracts/UpgradeableNFT.sol.

const CONTRACT_NAME_1 = "MarketUpgradeable" // Change this line if you changed the contract name on contracts/UpgradeableNFT.sol.

const CONTRACT_NAME_2 = "MarketUpgradeable" // Change this line if you changed the contract name on contracts/UpgradeableNFT.sol.


async function main() {
  if (!hardhatArguments.network) {
    throw new Error("Unknown network");
  }

  let proxyNFTUpgradeable: NFTUpgradeable;
  let proxyMarketUpgradeable: MarketUpgradeable;
  let proxyWhiteListUpgradeable: WhiteListUpgradeable;

  const UpgradeableNFT = await ethers.getContractFactory("NFTUpgradeable")
  proxyNFTUpgradeable = await upgrades.deployProxy(UpgradeableNFT, { kind: 'uups' }) as NFTUpgradeable ; 
  await proxyNFTUpgradeable.deployed(); // deploy the proxy

  const MarketUpgrade = await ethers.getContractFactory("MarketUpgradeable")
  proxyMarketUpgradeable = await upgrades.deployProxy(MarketUpgrade, { kind: 'uups' }) as MarketUpgradeable ; 
  await proxyMarketUpgradeable.deployed(); // deploy the proxy
  
  const WhiteListUpgrade = await ethers.getContractFactory("WhiteListUpgradeable")
  proxyWhiteListUpgradeable = await upgrades.deployProxy(WhiteListUpgrade, { kind: 'uups' }) as WhiteListUpgradeable ; 
  await proxyWhiteListUpgradeable.deployed(); // deploy the proxy

  let implementationproxyNFTUpgradeable = await upgrades.erc1967.getImplementationAddress(proxyNFTUpgradeable.address)
  let implementationproxyMarketUpgradeable = await upgrades.erc1967.getImplementationAddress(proxyMarketUpgradeable.address)
  let implementationproxyWhiteListUpgradeable = await upgrades.erc1967.getImplementationAddress(proxyNFTUpgradeable.address)

  await proxyMarketUpgradeable.setAddressFee("0x65CfcB06d1e9031A0a6209CE98C31d5f5bb9aa97")
  await proxyMarketUpgradeable.setNewListingFee(ethers.utils.parseEther("0.025"))
  await proxyMarketUpgradeable.setTokenSale("0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889")
  await proxyMarketUpgradeable.setWhiteListAddress(proxyWhiteListUpgradeable.address)

  await proxyNFTUpgradeable.setWhiteListAddress(proxyWhiteListUpgradeable.address)
  await proxyNFTUpgradeable.setMarketAddress(proxyMarketUpgradeable.address)

  console.log("proxyNFTUpgradeable ", proxyNFTUpgradeable.address)
  console.log("implementationproxyNFTUpgradeable code ", implementationproxyNFTUpgradeable)
  console.log("proxyMarketUpgradeable ", proxyMarketUpgradeable.address)
  console.log("implementationproxyMarketUpgradeable code ", implementationproxyMarketUpgradeable)
  console.log("proxyWhiteListUpgradeable ", proxyWhiteListUpgradeable.address)
  console.log("implementationproxyWhiteListUpgradeable code ", implementationproxyWhiteListUpgradeable)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
