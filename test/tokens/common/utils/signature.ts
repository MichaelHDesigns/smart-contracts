import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";

async function createMintSignature(
    contractAddress: string,
    signer: SignerWithAddress,
    to: string,
    tokenId: BigNumber,
    tokenURI: string,
    expirationTimestamp: number
): Promise<string> {
    const hash = ethers.utils.solidityKeccak256(
        ["address", "address", "uint256", "string", "uint256"],
        [contractAddress, to, tokenId, tokenURI, expirationTimestamp]
    );
    return await signHash(signer, hash);
}


function signHash(signer: SignerWithAddress, hash: string): Promise<string> {
    return signer.signMessage(ethers.utils.arrayify(hash));
}

export { createMintSignature }
