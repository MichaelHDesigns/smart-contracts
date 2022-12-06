import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { deployMarketplace } from "./util/fixtures";
import { getLastBlockTimestamp } from "../common/utils/time";
import { createMintSignature, createSaleSignature } from "../common/utils/signature";

const TOKEN_ID = 3;
const tokenURI = 'ipfs://123123';
const PRICE = '1000000000000000000'; // 1 ETH
let listingSignature, nodeSignature, saleData, timestamp, listingExpTimestamp, nodeExpTimestamp, expTimestamp, tokenData;

describe("ArttacaMarketplaceUpgradeable buy and transfer", function () {
  let factory, erc721, owner, user, collection, marketplace, operator;
  beforeEach(async () => {
      ({ factory, erc721, owner, user , collection, marketplace, operator } = await loadFixture(deployMarketplace));
      const tx = await collection.mintAndTransferByOwner(owner.address, TOKEN_ID, tokenURI);
      await tx.wait();
      tokenData = [
        TOKEN_ID,
        tokenURI,
        [[owner.address, 5000]]
      ]
      timestamp = await getLastBlockTimestamp();
      expTimestamp = timestamp + 100;
      listingExpTimestamp = expTimestamp + 100;
      nodeExpTimestamp = listingExpTimestamp + 100;
      listingSignature = await createSaleSignature(
        collection.address,
        owner,
        TOKEN_ID,
        PRICE,
        listingExpTimestamp
      );
      nodeSignature = await createSaleSignature(
        collection.address,
        operator,
        TOKEN_ID,
        PRICE,
        nodeExpTimestamp
      );

      saleData = [ PRICE, listingExpTimestamp, nodeExpTimestamp, listingSignature, nodeSignature ];
  });

  it("User can buy and transfer", async function () {

    collection.connect(owner).approve(marketplace.address, TOKEN_ID);

    const tx = await marketplace.connect(user).buyAndTransfer(
      collection.address,
      tokenData, 
      saleData,
      {value: PRICE}
    );
    await tx.wait();

    expect((await collection.tokensOfOwner(user.address)).length).to.equal(1);
    expect((await collection.tokensOfOwner(user.address))[0]).to.equal(TOKEN_ID);
    expect(await collection.tokenOfOwnerByIndex(user.address, 0)).to.equal(TOKEN_ID);
  });

  it("User cannot buy and transfer if token transfer is not approved", async function () {

    await expect(
      marketplace.connect(user).buyAndTransfer(
        collection.address,
        tokenData, 
        saleData,
        {value: PRICE}
      )
    ).to.rejectedWith("VM Exception while processing transaction: reverted with reason string 'ERC721: caller is not token owner nor approved'");

    expect((await collection.tokensOfOwner(user.address)).length).to.equal(0);
  });

  it("User cannot buy and transfer if sent less ETH than price", async function () {

    const WRONG_PRICE = '500000000000000000';

    await expect(
      marketplace.connect(user).buyAndTransfer(
        collection.address,
        tokenData, 
        saleData,
        {value: WRONG_PRICE}
      )
    ).to.rejectedWith("VM Exception while processing transaction: reverted with reason string 'ArttacaMarketplaceUpgradeable::buyAndMint: Value sent is insufficient.'");

    expect((await collection.tokensOfOwner(owner.address)).length).to.equal(1);
    expect((await collection.tokensOfOwner(user.address)).length).to.equal(0);
  });

  it("User cannot buy and transfer if expired sale signature", async function () {

    collection.connect(owner).approve(marketplace.address, TOKEN_ID);

    const expiredTimestamp = expTimestamp - 200;

    const expiredListingSignature = await createSaleSignature(
      collection.address,
      owner,
      TOKEN_ID,
      PRICE,
      expiredTimestamp
    );

    saleData = [ PRICE, expiredTimestamp, nodeExpTimestamp, expiredListingSignature, nodeSignature ];

    await expect(
      marketplace.connect(user).buyAndTransfer(
        collection.address,
        tokenData, 
        saleData,
        {value: PRICE}
      )
    ).to.rejectedWith("VM Exception while processing transaction: reverted with reason string 'ArttacaMarketplaceUpgradeable:buyAndMint:: Listing signature is probably expired.");

    expect((await collection.tokensOfOwner(owner.address)).length).to.equal(1);
    expect((await collection.tokensOfOwner(user.address)).length).to.equal(0);
  });

  it("User cannot buy and mint if wrong operator signature", async function () {

    collection.connect(owner).approve(marketplace.address, TOKEN_ID);

    const wrongOperatorSignature = await createSaleSignature(
      collection.address,
      user,
      TOKEN_ID,
      PRICE,
      expTimestamp
    );

    saleData = [ PRICE, listingExpTimestamp, nodeExpTimestamp, listingSignature, wrongOperatorSignature ];

    await expect(
      marketplace.connect(user).buyAndTransfer(
        collection.address,
        tokenData, 
        saleData,
        {value: PRICE}
      )
    ).to.rejectedWith("VM Exception while processing transaction: reverted with reason string 'ArttacaMarketplaceUpgradeable:buyAndMint:: Node signature is not from a valid operator.'");

    expect((await collection.tokensOfOwner(owner.address)).length).to.equal(1);
    expect((await collection.tokensOfOwner(user.address)).length).to.equal(0);
  });
});
