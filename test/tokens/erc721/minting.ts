import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";
import { deployCollection } from "./util/fixtures";
import { createMintSignature } from "../common/utils/signature";
import { getLastBlockTimestamp } from "../common/utils/time";

describe("ArttacaERC721Upgradeable minting", function () {
  let collection, owner, user;
  const TOKEN_ID = 3;
  const tokenURI = 'ipfs://123123';
  beforeEach(async () => {
    ({ collection, owner, user } = await loadFixture(deployCollection));
  });

  it("Should mint", async function () {
    const tx = await collection['mintAndTransfer(address,uint256)'](owner.address, TOKEN_ID);
    await tx.wait();

    expect(await collection.totalSupply()).to.equal(1);
    expect((await collection.tokensOfOwner(owner.address)).length).to.equal(1);
    expect((await collection.tokensOfOwner(owner.address))[0]).to.equal(TOKEN_ID);
    expect(await collection.tokenOfOwnerByIndex(owner.address, 0)).to.equal(TOKEN_ID);
  });

  it("Not owner minting without signature should fail", async function () {
    await expect(
      collection.connect(user)['mintAndTransfer(address,uint256)'](owner.address, TOKEN_ID)
    ).to.rejectedWith("VM Exception while processing transaction: reverted with reason string 'Ownable: caller is not the owner'");
  });

  it("Not owner with correct signature should be able to mint", async function () {

	  const timestamp = await getLastBlockTimestamp();
    const expTimestamp = timestamp + 100;
	
	  const mintSignature = await createMintSignature(
	    collection.address,
      owner,
      user.address,
      TOKEN_ID,
      tokenURI,
      expTimestamp
    );

    const mintData = [
      owner.address,
      user.address,
      TOKEN_ID,
      tokenURI,
      expTimestamp,
      mintSignature
    ]

    const tx = await collection.connect(user)['mintAndTransfer((address,address,uint256,string,uint256,bytes))'](mintData);
    await tx.wait();

    expect(await collection.totalSupply()).to.equal(1);
    expect((await collection.tokensOfOwner(user.address)).length).to.equal(1);
    expect((await collection.tokensOfOwner(user.address))[0]).to.equal(TOKEN_ID);
    expect(await collection.tokenOfOwnerByIndex(user.address, 0)).to.equal(TOKEN_ID);
  });

  it("Not owner with wrong signature should fail", async function () {

	  const timestamp = await getLastBlockTimestamp();
    const expTimestamp = timestamp + 100;
	
	  const wrongMintSignature = await createMintSignature(
	    collection.address,
      owner,
      owner.address,
      TOKEN_ID,
      tokenURI,
      expTimestamp
    );

    const mintData = [
      owner.address,
      user.address,  // changed the to value
      TOKEN_ID,
      tokenURI,
      expTimestamp,
      wrongMintSignature
    ]

    await expect(
      collection.connect(user)['mintAndTransfer((address,address,uint256,string,uint256,bytes))'](mintData)
    ).to.rejectedWith("VM Exception while processing transaction: reverted with reason string 'ArttacaERC721Upgradeable:mintAndTransfer:: Signature is not valid.'");
  });


  it("Not owner with expired signature should fail", async function () {

	  const timestamp = await getLastBlockTimestamp();
    const pastExpTimestamp = timestamp - 100;
	
	  const expiredMintSignature = await createMintSignature(
	    collection.address,
      owner,
      owner.address, // to is the owner now
      TOKEN_ID,
      tokenURI,
      pastExpTimestamp // time is before timestamp
    );

    const mintData = [
      owner.address,
      user.address,
      TOKEN_ID,
      tokenURI,
      pastExpTimestamp,
      expiredMintSignature
    ]

    await expect(
      collection.connect(user)['mintAndTransfer((address,address,uint256,string,uint256,bytes))'](mintData)
    ).to.rejectedWith("VM Exception while processing transaction: reverted with reason string 'ArttacaERC721Upgradeable:mintAndTransfer:: Signature is expired.'");
  });



  it("Minting a existing ID should revert", async function () {
    const tx = await collection['mintAndTransfer(address,uint256)'](owner.address, TOKEN_ID);
    await tx.wait();

    await expect(
      collection['mintAndTransfer(address,uint256)'](owner.address, TOKEN_ID)
    ).to.rejectedWith("VM Exception while processing transaction: reverted with reason string 'ERC721: token already minted'");
  });
});
