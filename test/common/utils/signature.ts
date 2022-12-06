import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";

const SPLIT_HASH = "0xb64bc59e7eded47b351c02a7b4cb52e4089e1395e8496c8256c7209069520dbf"
const MINT_AND_TRANSFER_TYPEHASH = "0x58feed951fddab635bb89928bb51b1cb73ecca5c4497956c1fd113ba2f06374c"

function hashSplits(splits: any[]): string {
    const splitBytes = [];

    for (let i = 0; i < splits.length; i++) {
        splitBytes.push(ethers.utils.solidityKeccak256(
            ["bytes32", "address", "uint96"], 
            [SPLIT_HASH, splits[i][0], splits[i][1]]
        ))
    }

    return ethers.utils.solidityKeccak256(["bytes32[]"], [splitBytes])
}

async function createMintSignature(
    contractAddress: string,
    signer: SignerWithAddress,
    tokenId: BigNumber,
    tokenURI: string,
    expTimestamp: number,
    splits: any[]
): Promise<string> {
    const hash = ethers.utils.solidityKeccak256(
        ["bytes32", "address", "uint256", "string", "bytes32", "uint256"],
        [MINT_AND_TRANSFER_TYPEHASH, contractAddress, tokenId, tokenURI, hashSplits(splits), expTimestamp]
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
