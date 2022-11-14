import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";

async function createMintSignature(
    contractAddress: string,
    signer: SignerWithAddress,
    tokenId: BigNumber,
    tokenURI: string,
    expirationTimestamp: number
): Promise<string> {
    const hash = ethers.utils.solidityKeccak256(
        ["address", "uint256", "string", "uint256"],
        [contractAddress, tokenId, tokenURI, expirationTimestamp]
    );
    return await signHash(signer, hash);
}

async function createSaleSignature(
    contractAddress: string,
    signer: SignerWithAddress,
    tokenId: BigNumber,
    price: string,
    expirationTimestamp: number
): Promise<string> {
    const hash = ethers.utils.solidityKeccak256(
        ["address", "uint256", "uint256", "uint256"],
        [contractAddress, tokenId, price, expirationTimestamp]
    );
    return await signHash(signer, hash);
}



function signHash(signer: SignerWithAddress, hash: string): Promise<string> {
    return signer.signMessage(ethers.utils.arrayify(hash));
}

export { createMintSignature, createSaleSignature }
