import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { deployMarketplace } from "./util/fixtures";
import { getLastBlockTimestamp } from "../common/utils/time";
import { createMintSignature, createSaleSignature } from "../common/utils/signature";

const TOKEN_ID = 3;
const tokenURI = 'ipfs://123123';
const PRICE = '1000000000000000000'; // 1 ETH
let saleSignature, operatorSignature, saleData, timestamp, expTimestamp;
const tokenData = [
  TOKEN_ID,
  tokenURI
]

describe("ArttacaMarketplaceUpgradeable buy and transfer", function () {
  let factory, erc721, owner, user, collection, marketplace, operator;
  beforeEach(async () => {
      ({ factory, erc721, owner, user , collection, marketplace, operator } = await loadFixture(deployMarketplace));
      const tx = await collection.mintAndTransferByOwner(owner.address, TOKEN_ID, tokenURI);
      await tx.wait();
      timestamp = await getLastBlockTimestamp();
      expTimestamp = timestamp + 100;
      saleSignature = await createSaleSignature(
        collection.address,
        owner,
        TOKEN_ID,
        PRICE,
        expTimestamp
      );
      operatorSignature = await createSaleSignature(
        collection.address,
        operator,
        TOKEN_ID,
        PRICE,
        expTimestamp
      );

      saleData = [ PRICE, expTimestamp, saleSignature, operatorSignature ];
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

    const expiredSaleSignature = await createSaleSignature(
      collection.address,
      owner,
      TOKEN_ID,
      PRICE,
      expiredTimestamp
    );

    saleData = [ PRICE, expiredTimestamp, expiredSaleSignature, operatorSignature ];

    await expect(
      marketplace.connect(user).buyAndTransfer(
        collection.address,
        tokenData, 
        saleData,
        {value: PRICE}
      )
    ).to.rejectedWith("VM Exception while processing transaction: reverted with reason string 'ArttacaMarketplaceUpgradeable:buyAndMint:: Signature is probably expired.'");

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

    saleData = [ PRICE, expTimestamp, saleSignature, wrongOperatorSignature ];

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
