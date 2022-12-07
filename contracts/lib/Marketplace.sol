// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (lib/Marketplace.sol)

pragma solidity ^0.8.4;

import "./Ownership.sol";

/**
 * @title Arttaca Marketplace library.
 */
library Marketplace {
    struct TokenData {
        uint id;
        string URI;
        Ownership.Royalties royalties;
    }

    struct MintData {
        address to;
        uint expTimestamp;
        bytes signature;
    }

    struct SaleData {
        uint price;
        uint listingExpTimestamp;
        uint nodeExpTimestamp;
        bytes listingSignature;
        bytes nodeSignature;
    }

    bytes32 public constant MINT_AND_TRANSFER_TYPEHASH = keccak256("Mint721(address collectionAddress, uint id,string tokenURI, Split[] splits) Split(address account, uint96 shares)");

    function hashMint(address collectionAddress, TokenData memory _tokenData, MintData memory _mintData) internal pure returns (bytes memory) {
        bytes32[] memory splitBytes = new bytes32[](_tokenData.royalties.splits.length);

        for (uint i = 0; i < _tokenData.royalties.splits.length; ++i) {
            splitBytes[i] = Ownership.hash(_tokenData.royalties.splits[i]);
        }

        return abi.encodePacked(
            MINT_AND_TRANSFER_TYPEHASH,
            collectionAddress,
            _tokenData.id,
            _tokenData.URI,
            keccak256(abi.encodePacked(splitBytes)),
            _tokenData.royalties.percentage,
            _mintData.expTimestamp
        );
    }

    bytes32 public constant LISTING_ERC721_TYPEHASH = keccak256("Listing721(address collectionAddress, uint id, uint price, uint96 expTimestamp)");

    function hashListing(address collectionAddress, TokenData memory _tokenData, SaleData memory _saleData, bool isNode) internal pure returns (bytes memory) {
        return abi.encodePacked(
            collectionAddress,
            _tokenData.id,
            _saleData.price,
            isNode ? _saleData.nodeExpTimestamp : _saleData.listingExpTimestamp
        );
    }
}