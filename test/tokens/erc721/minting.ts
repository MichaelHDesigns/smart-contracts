import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";
import { deployCollection } from "./util/fixtures";
import { createMintSignature } from "../../common/utils/signature";
import { getLastBlockTimestamp } from "../../common/utils/time";

describe("ArttacaERC721Upgradeable minting", function () {
  let collection, owner, user, factory;
  const TOKEN_ID = 3;
  const tokenURI = 'ipfs://123123';
  beforeEach(async () => {
    ({ collection, owner, user, factory } = await loadFixture(deployCollection));
  });

  it("Owner should mint", async function () {
    const tx = await collection.mintAndTransferByOwner(owner.address, TOKEN_ID, tokenURI);
    await tx.wait();

    expect(await collection.totalSupply()).to.equal(1);
    expect((await collection.tokensOfOwner(owner.address)).length).to.equal(1);
    expect((await collection.tokensOfOwner(owner.address))[0]).to.equal(TOKEN_ID);
    expect(await collection.tokenOfOwnerByIndex(owner.address, 0)).to.equal(TOKEN_ID);
  });

  it("Not owner minting should fail", async function () {
    await expect(
      collection.connect(user).mintAndTransferByOwner(owner.address, TOKEN_ID, tokenURI)
    ).to.rejectedWith("VM Exception while processing transaction: reverted with reason string 'Ownable: caller is not the owner'");
  });

  it("Operator with correct signature should be able to mint", async function () {

    let tx = await factory.addOperator(user.address);
    await tx.wait();

	  const timestamp = await getLastBlockTimestamp();
    const expTimestamp = timestamp + 100;
	  const mintSignature = await createMintSignature(
	    collection.address,
      owner,
      TOKEN_ID,
      tokenURI,
      expTimestamp,
      [[owner.address, 5000]]
    );

    const tokenData = [
      TOKEN_ID,
      tokenURI,
      [[owner.address, 5000]]
    ]

    const mintData = [
      user.address,
      expTimestamp,
      mintSignature
    ]

    tx = await collection.connect(user).mintAndTransfer(tokenData, mintData);
    await tx.wait();

    expect(await collection.totalSupply()).to.equal(1);
    expect((await collection.tokensOfOwner(user.address)).length).to.equal(1);
    expect((await collection.tokensOfOwner(user.address))[0]).to.equal(TOKEN_ID);
    expect(await collection.tokenOfOwnerByIndex(user.address, 0)).to.equal(TOKEN_ID);
  });

  it("Operator with wrong signature should fail", async function () {

    let tx = await factory.addOperator(user.address);
    await tx.wait();

	  const timestamp = await getLastBlockTimestamp();
    const expTimestamp = timestamp + 100;
    const wrongTokenId = 5;
	
	  const wrongMintSignature = await createMintSignature(
	    collection.address,
      owner,
      TOKEN_ID,
      tokenURI,
      expTimestamp,
      []
    );

    const tokenData = [
      wrongTokenId,
      tokenURI,
      []
    ]

    const mintData = [
      user.address,
      expTimestamp,
      wrongMintSignature
    ]

    await expect(
      collection.connect(user).mintAndTransfer(tokenData, mintData)
    ).to.rejectedWith("VM Exception while processing transaction: reverted with reason string 'ArttacaERC721Upgradeable:mintAndTransfer:: Signature is not valid.'");
  });


  it("Operator with expired signature should fail", async function () {

    let tx = await factory.addOperator(user.address);
    await tx.wait();

	  const timestamp = await getLastBlockTimestamp();
    const pastExpTimestamp = timestamp - 100;
	
	  const expiredMintSignature = await createMintSignature(
	    collection.address,
      owner,
      TOKEN_ID,
      tokenURI,
      pastExpTimestamp, // time is before timestamp
      []
    );

    const tokenData = [
      TOKEN_ID,
      tokenURI,
      []
    ]

    const mintData = [
      user.address,
      pastExpTimestamp,
      expiredMintSignature
    ]

    await expect(
      collection.connect(user).mintAndTransfer(tokenData, mintData)
    ).to.rejectedWith("VM Exception while processing transaction: reverted with reason string 'ArttacaERC721Upgradeable:mintAndTransfer:: Signature is expired.'");
  });


  it("Minting a existing ID should revert", async function () {
    const tx = await collection.mintAndTransferByOwner(owner.address, TOKEN_ID, tokenURI);
    await tx.wait();

    await expect(
      collection.mintAndTransferByOwner(owner.address, TOKEN_ID, tokenURI)
    ).to.rejectedWith("VM Exception while processing transaction: reverted with reason string 'ERC721: token already minted'");
  });
});
