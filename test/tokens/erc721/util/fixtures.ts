import { time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";

async function deployFactory() {
  const [owner, user] = await ethers.getSigners();

  const ArttacaERC721Upgradeable = await ethers.getContractFactory("ArttacaERC721Upgradeable");
  const ArttacaERC721Factory = await ethers.getContractFactory("ArttacaERC721Factory");

  const erc721 = await ArttacaERC721Upgradeable.connect(owner).deploy();
  const factory = await ArttacaERC721Factory.connect(owner).deploy(erc721.address)
  await factory.deployed()

  return { factory, erc721, owner, user };
}

async function deployCollection() {
  const { factory, erc721, owner, user } = await deployFactory();

  const tx = await factory.createCollection('Arttaca Test','ARTTT', 'https://api.arttaca.io/v1/assets/{address}/',[],[])
  await tx.wait();
  const newCollectionAddress = await factory.getCollectionAddress(0);
  const collection = await ethers.getContractAt('ArttacaERC721Upgradeable', newCollectionAddress, owner)

  return { factory, erc721, owner, user , collection };
}

async function deployCollectionMinted() {
  const { factory, erc721, owner, user, collection } = await deployCollection();

  const tokenId = 0;

  const tx = await collection['mintAndTransfer(address,uint256)'](owner.address, tokenId);
  await tx.wait();

  return { factory, erc721, owner, user , collection, tokenId };
}


export { deployFactory, deployCollection, deployCollectionMinted };
