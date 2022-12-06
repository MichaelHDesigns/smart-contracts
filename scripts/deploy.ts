import { ethers } from "hardhat";


async function main() {

  const ArttacaERC721Upgradeable = await ethers.getContractFactory("ArttacaERC721Upgradeable");
  const ArttacaERC721FactoryUpgradeable = await ethers.getContractFactory("ArttacaERC721FactoryUpgradeable");
  const ArttacaMarketplaceUpgradeable = await ethers.getContractFactory("ArttacaMarketplaceUpgradeable");

  const erc721 = await ArttacaERC721Upgradeable.deploy();
  
  const factory = await upgrades.deployProxy(ArttacaERC721FactoryUpgradeable, [erc721.address], { initializer: '__ArttacaERC721Factory_initialize' });

  await factory.deployed()

  console.log(`Arttaca ERC721 collection factory has been deployed at ${factory.address}`);

  const marketplace = await upgrades.deployProxy(ArttacaMarketplaceUpgradeable, { initializer: '__ArttacaMarketplace_init' });

  await marketplace.deployed()

  let tx = await marketplace.addOperator(operator.address);
  await tx.wait();

  tx = await factory.addOperator(marketplace.address);
  await tx.wait();
  
  console.log(`Arttaca ERC721 main collection has been deployed at ${newCollectionAddress}`);

  console.log(`Deployment script executed successfully.`);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
