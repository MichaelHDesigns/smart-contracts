// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (lib/Ownership.sol)

pragma solidity ^0.8.4;

/**
 * @title Ownership Marketplace library.
 */
library Ownership {
    struct Split {
        address payable account;
        uint96 shares;
    }
}