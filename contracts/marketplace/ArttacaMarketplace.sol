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
    function getBaseRoyalty() external returns (Ownership.Split memory);
    function getSplits(uint tokenId) external returns (Ownership.Split[] memory);
}

/**
 * @title ArttacaMarketplaceUpgradeable

 * @dev This contract 
 */
contract ArttacaMarketplaceUpgradeable is VerifySignature, PausableUpgradeable, OperableUpgradeable {

    // @dev Recipient of protocol fees.
    Ownership.Split protocolFee;

    function __ArttacaMarketplace_init(
        address owner,
        Ownership.Split memory _protocolFee
    ) external initializer {
        __OperableUpgradeable_init(owner);
        _addOperator(owner);

        protocolFee = _protocolFee;
    }

    function getHash() external returns (bytes32) {
        return Marketplace.MINT_AND_TRANSFER_TYPEHASH;
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

        uint saleProceedingsToSend = _saleData.price;
        uint protocolFeeAmount = (_saleData.price * protocolFee.shares) / _feeDenominator();
        AddressUpgradeable.sendValue(protocolFee.account, protocolFeeAmount);
        saleProceedingsToSend -= protocolFeeAmount;

        uint amountToSplit = saleProceedingsToSend;
        Ownership.Split[] memory splits = collection.getSplits(_tokenData.id);
        if (splits.length > 0) {
            for (uint i; i < splits.length; i++) {
                uint splitAmount = (amountToSplit * splits[i].shares) / _feeDenominator();
                AddressUpgradeable.sendValue(splits[i].account, splitAmount);
                saleProceedingsToSend -= splitAmount;
            }
        } else {
            AddressUpgradeable.sendValue(payable(collection.owner()), amountToSplit);
        }

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

        uint saleProceedingsToSend = _saleData.price;
        uint protocolFeeAmount = (_saleData.price * protocolFee.shares) / _feeDenominator();
        AddressUpgradeable.sendValue(protocolFee.account, protocolFeeAmount);
        saleProceedingsToSend -= protocolFeeAmount;

        Ownership.Split memory baseRoyalty = collection.getBaseRoyalty();
        uint royaltyAmount = (_saleData.price * baseRoyalty.shares) / _feeDenominator();

        Ownership.Split[] memory splits = collection.getSplits(_tokenData.id);
        if (splits.length > 0) {
            for (uint i; i < splits.length; i++) {
                uint splitAmount = (royaltyAmount * splits[i].shares) / _feeDenominator();
                AddressUpgradeable.sendValue(splits[i].account, splitAmount);
                saleProceedingsToSend -= splitAmount;
            }
        } else {
            AddressUpgradeable.sendValue(baseRoyalty.account, royaltyAmount);
            saleProceedingsToSend -= royaltyAmount;
        }

        AddressUpgradeable.sendValue(payable(tokenOwner), saleProceedingsToSend);

        collection.safeTransferFrom(tokenOwner, msg.sender, _tokenData.id);
    }

    /**
     * @dev Change the protocol fee recipient (owner only)
     * @param _protocolFee New protocol fee recipient address
     */
    function changeProtocolFee(Ownership.Split memory _protocolFee) public onlyOwner {
        protocolFee = _protocolFee;
    }

    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    function pause() external onlyOperator {
        _pause();
    }

    function unpause() external onlyOperator {
        _unpause();
    }


    uint256[50] private __gap;
}