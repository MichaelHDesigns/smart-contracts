import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { deployCollectionMinted } from "./util/fixtures";

describe("ArttacaERC721Upgradeable metadata", function () {
  let collection, owner, user, tokenId;
  const NEW_BASE_URI = 'ipfs://';
  beforeEach(async () => {
      ({ collection, owner, user, tokenId } = await loadFixture(deployCollectionMinted));
  });


  it("Owner can set a new base URI", async function () {
    expect(await collection.baseURI()).to.not.equal(NEW_BASE_URI);
    const tx = await collection.setBaseURI(NEW_BASE_URI);
    await tx.wait();
    expect(await collection.tokenURI(tokenId)).to.equal(NEW_BASE_URI+tokenId);
    expect(await collection.baseURI()).to.equal(NEW_BASE_URI);
  });

  it("Non-owner can't set new base URI", async function () {    
    await expect(
      collection.connect(user).setBaseURI(NEW_BASE_URI)
    ).to.be.rejectedWith(
      "VM Exception while processing transaction: reverted with reason string 'Ownable: caller is not the owner'"
    );
    expect(await collection.baseURI()).to.not.equal(NEW_BASE_URI);
  });


  // todo change the contract to be able to mint sending the token URI within the tx
});
