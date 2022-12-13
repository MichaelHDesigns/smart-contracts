import { ethers } from "hardhat";

const factoryAddress = "0x8dA3dA022d7a5224615c8F2E3fFdDc5B883B24A2"
async function main() {

  const ArttacaERC721FactoryUpgradeable = await ethers.getContractFactory("ArttacaERC721FactoryUpgradeable");
  const ArttacaMarketplaceUpgradeable = await ethers.getContractFactory("ArttacaMarketplaceUpgradeable");
  
  const factory = await ethers.getContractAt("ArttacaERC721FactoryUpgradeable", factoryAddress);

  const marketplace = await upgrades.deployProxy(ArttacaMarketplaceUpgradeable, [process.env.DEPLOYER_ADDRESS, [process.env.DEPLOYER_ADDRESS, 300]], { initializer: '__ArttacaMarketplace_init' });

  await marketplace.deployed()

  console.log(`Arttaca Marketplace has been deployed at ${marketplace.address}`);

  let tx = await marketplace.addOperator(process.env.ARTTACA_OPERATOR_ADDRESS);
  await tx.wait();

  console.log(`Added operator to marketplace ${process.env.ARTTACA_OPERATOR_ADDRESS}`);

  tx = await factory.addOperator(marketplace.address);
  await tx.wait();
  
  console.log('added marketplace as operator in the factory');

  console.log(`Deployment script executed successfully.`);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
