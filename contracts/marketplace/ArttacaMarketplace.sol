// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (marketplace/ArttacaMarketplaceUpgradeable.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../access/OperableUpgradeable.sol";
import "../lib/Marketplace.sol";
import "../utils/VerifySignature.sol";

interface ERC721 {
    function mintAndTransfer(Marketplace.TokenData calldata _tokenData, Marketplace.MintData calldata _mintData) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function owner() external returns (address);
    function ownerOf(uint) external returns (address);
}

/**
 * @title ArttacaMarketplaceUpgradeable

 * @dev This contract 
 */
contract ArttacaMarketplaceUpgradeable is VerifySignature, PausableUpgradeable, OperableUpgradeable {

    /* Recipient of protocol fees. */
    address public protocolFeeRecipient;

    function __ArttacaMarketplace_init() external initializer {
        __OperableUpgradeable_init(msg.sender);
        _addOperator(msg.sender);
    }

    function getHash() external returns (bytes32) {
        return Ownership.SPLIT_HASH;
    }

    function getHashes(Ownership.Split[] memory splits) external returns (bytes32, Ownership.Split memory, bytes32[] memory) {
        bytes32[] memory splitBytes = new bytes32[](splits.length);

        for (uint i = 0; i < splits.length; ++i) {
            splitBytes[i] = Ownership.hash(splits[i]);
        }
        return (
            Ownership.SPLIT_HASH,
            splits[0],
            splitBytes
        );
    }

    function buyAndMint(
        address collectionAddress, 
        Marketplace.TokenData calldata _tokenData, 
        Marketplace.MintData calldata _mintData, 
        Marketplace.SaleData calldata _saleData
    ) external payable {
        require(!paused(), "ArttacaMarketplaceUpgradeable::buyAndMint: cannot mint and buy while is paused.");
        require(msg.value >= _saleData.price, "ArttacaMarketplaceUpgradeable::buyAndMint: Value sent is insufficient.");

        require(block.timestamp <= _saleData.listingExpTimestamp, "ArttacaMarketplaceUpgradeable:buyAndMint:: Listing signature is probably expired.");
        require(block.timestamp <= _saleData.nodeExpTimestamp, "ArttacaMarketplaceUpgradeable:buyAndMint:: Node signature is probably expired.");
        ERC721 collection = ERC721(collectionAddress);
        require(
            _verifySignature(
                Marketplace.hashListing(collectionAddress, _tokenData, _saleData, false),
                collection.owner(),
                _saleData.listingSignature
            ),
            "ArttacaMarketplaceUpgradeable:buyAndMint:: Listing signature is not valid."
        );

        bytes32 messageHash = keccak256(Marketplace.hashListing(collectionAddress, _tokenData, _saleData, true));
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        address nodeSignerRecovered = recoverSigner(ethSignedMessageHash, slice(_saleData.nodeSignature, 0, 65));

        require(
            isOperator(nodeSignerRecovered),
            "ArttacaMarketplaceUpgradeable:buyAndMint:: Node signature is not from a valid operator."
        );

        AddressUpgradeable.sendValue(payable(collection.owner()), msg.value);
        // todo add protocol fee
        // todo add splits

        collection.mintAndTransfer(_tokenData, _mintData);
    }

    function buyAndTransfer(
        address collectionAddress,
        Marketplace.TokenData calldata _tokenData,
        Marketplace.SaleData calldata _saleData
    ) external payable {
        require(!paused(), "ArttacaMarketplaceUpgradeable::buyAndMint: cannot mint and buy while is paused.");
        require(msg.value >= _saleData.price, "ArttacaMarketplaceUpgradeable::buyAndMint: Value sent is insufficient.");

        require(block.timestamp <= _saleData.listingExpTimestamp, "ArttacaMarketplaceUpgradeable:buyAndMint:: Listing signature is probably expired.");
        require(block.timestamp <= _saleData.nodeExpTimestamp, "ArttacaMarketplaceUpgradeable:buyAndMint:: Node signature is probably expired.");

        ERC721 collection = ERC721(collectionAddress);
        address tokenOwner = collection.ownerOf(_tokenData.id);
        require(
            _verifySignature(
                abi.encodePacked(
                    collectionAddress,
                    _tokenData.id,
                    _saleData.price,
                    _saleData.listingExpTimestamp
                ),
                tokenOwner,
                _saleData.listingSignature
            ),
            "ArttacaMarketplaceUpgradeable:buyAndMint:: Owner signature is not valid."
        );

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                collectionAddress,
                _tokenData.id,
                _saleData.price,
                _saleData.nodeExpTimestamp
            )
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        address nodeSignerRecovered = recoverSigner(ethSignedMessageHash, slice(_saleData.nodeSignature, 0, 65));

        require(
            isOperator(nodeSignerRecovered),
            "ArttacaMarketplaceUpgradeable:buyAndMint:: Node signature is not from a valid operator."
        );

        AddressUpgradeable.sendValue(payable(tokenOwner), msg.value);
        // todo add protocol fee
        // todo add royalties

        collection.safeTransferFrom(tokenOwner, msg.sender, _tokenData.id);
    }

    /**
     * @dev Change the protocol fee recipient (owner only)
     * @param newProtocolFeeRecipient New protocol fee recipient address
     */
    function changeProtocolFeeRecipient(address newProtocolFeeRecipient) public onlyOwner{
        protocolFeeRecipient = newProtocolFeeRecipient;
    }

    function pause() external onlyOperator {
        _pause();
    }

    function unpause() external onlyOperator {
        _unpause();
    }

    uint256[50] private __gap;
}