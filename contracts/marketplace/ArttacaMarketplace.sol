// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (marketplace/ArttacaMarketplaceUpgradeable.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../access/OperableUpgradeable.sol";
import "../collections/erc721/IArttacaERC721Upgradeable.sol";
import "../lib/Marketplace.sol";
import "../utils/VerifySignature.sol";

/**
 * @title ArttacaMarketplaceUpgradeable
 * @dev This contract 
 */
contract ArttacaMarketplaceUpgradeable is VerifySignature, PausableUpgradeable, OperableUpgradeable {

    function __ArttacaMarketplace_init() external initializer {
        __OperableUpgradeable_init(msg.sender);
    }

    function buyAndMint(Marketplace.MintData calldata _mintData, Marketplace.SaleData calldata _saleData) external payable {
        require(!paused(), "ArttacaMarketplaceUpgradeable::buyAndMint: cannot mint and buy while is paused.");
        require(msg.value >= _saleData.price, "ArttacaMarketplaceUpgradeable::buyAndMint: Value sent is insufficient.");

        require(block.timestamp <= _saleData.expirationTimestamp, "ArttacaMarketplaceUpgradeable:buyAndMint:: Signature is probably expired.");
        require(
            _verifySignature(
                abi.encodePacked(
                    _saleData.collectionAddress,
                    _mintData.tokenId,
                    _saleData.price,
                    _saleData.expirationTimestamp
                ),
                _mintData.signer,
                _saleData.signature
            ),
            "ArttacaMarketplaceUpgradeable:buyAndMint:: Signature is not valid."
        );

        AddressUpgradeable.sendValue(payable(_mintData.signer), msg.value);
        // todo add protocol fee
        // todo add splits

        IArttacaERC721Upgradeable(_saleData.collectionAddress).mintAndTransfer(_mintData);
    }

    function buyAndTransfer(Marketplace.SaleData calldata _saleData) external payable {
        require(!paused(), "ArttacaMarketplaceUpgradeable::mintAndBuy: cannot mint and buy while is paused.");
        require(msg.value >= _saleData.price, "ArttacaMarketplaceUpgradeable::mintAndBuy: Value sent is insufficient.");

        require(block.timestamp <= _saleData.expirationTimestamp, "ArttacaMarketplaceUpgradeable:mintAndBuy:: Signature is probably expired.");
        require(
            _verifySignature(
                abi.encodePacked(
                    _saleData.collectionAddress,
                    _saleData.tokenId,
                    _saleData.price,
                    _saleData.expirationTimestamp
                ),
                _saleData.signer,
                _saleData.signature
            ),
            "ArttacaMarketplaceUpgradeable:mintAndBuy:: Signature is not valid."
        );

        AddressUpgradeable.sendValue(payable(_saleData.signer), msg.value);
        // todo add protocol fee
        // todo add royalties

        IArttacaERC721Upgradeable(_saleData.collectionAddress).transferFrom(_saleData.signer, msg.sender, _saleData.tokenId);
    }

    function pause() external onlyOperator {
        _pause();
    }

    function unpause() external onlyOperator {
        _unpause();
    }
}