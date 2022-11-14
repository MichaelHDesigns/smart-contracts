// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (lib/Marketplace.sol)

pragma solidity ^0.8.4;

/**
 * @title Arttaca Marketplace library.
 */
library Marketplace {

    struct TokenData {
        uint id;
        string URI;
    }

    struct MintData {
        address to;
        uint expirationTimestamp;
        bytes signature;
    }

    struct SaleData {
        uint price;
        uint expirationTimestamp;
        bytes ownerSignature;
        bytes nodeSignature;
    }
}