import { ethers } from "hardhat";

async function main() {

  const ArttacaERC721Upgradeable = await ethers.getContractFactory("ArttacaERC721Upgradeable");
  const ArttacaERC721FactoryUpgradeable = await ethers.getContractFactory("ArttacaERC721FactoryUpgradeable");

  const erc721 = await ArttacaERC721Upgradeable.deploy();
  
  const factory = await upgrades.deployProxy(ArttacaERC721FactoryUpgradeable, [erc721.address], { initializer: '__ArttacaERC721Factory_initialize' });

  await factory.deployed()

  console.log(`Arttaca ERC721 collection factory has been deployed at ${factory.address}`);

  const tx = await factory.createCollection('Arttaca Test','ARTTT', 'https://api.arttaca.io/v1/assets/',[],[])
  await tx.wait();
  const newCollectionAddress = await factory.getCollectionAddress(0);
  
  console.log(`Arttaca ERC721 main collection has been deployed at ${newCollectionAddress}`);

  console.log(`Deployment script executed successfully.`);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
