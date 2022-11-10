// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (lib/Marketplace.sol)

pragma solidity ^0.8.4;

/**
 * @title Arttaca Marketplace library.
 */
library Marketplace {

    struct MintData {
        address signer;
        address to;
        uint tokenId;
        string tokenURI;
        uint expirationTimestamp;
        bytes signature;
    }

    struct SaleData {
        address signer;
        address collectionAddress;
        uint tokenId;
        uint price;
        uint expirationTimestamp;
        bytes signature;
    }
}