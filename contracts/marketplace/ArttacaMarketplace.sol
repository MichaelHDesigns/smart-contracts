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
    function getRoyalties(uint tokenId) external returns (Ownership.Royalties memory);
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

    function buyAndMint(
        address collectionAddress, 
        Marketplace.TokenData calldata _tokenData, 
        Marketplace.MintData calldata _mintData, 
        Marketplace.SaleData calldata _saleData
    ) external payable {
        require(!paused(), "ArttacaMarketplaceUpgradeable::buyAndMint: cannot mint and buy while is paused.");
        require(msg.value >= _saleData.price, "ArttacaMarketplaceUpgradeable::buyAndMint: Value sent is insufficient.");

        ERC721 collection = ERC721(collectionAddress);

        _verifySaleSignatures(_tokenData, _saleData, collectionAddress, collection.owner());

        uint saleProceedingsToSend = _saleData.price - _takeProtocolFee(_saleData.price);

        Ownership.Royalties memory royalties = collection.getRoyalties(_tokenData.id);
        if (royalties.splits.length > 0) {
            _distributeSplits(royalties.splits, saleProceedingsToSend);
        } else {
            AddressUpgradeable.sendValue(payable(collection.owner()), saleProceedingsToSend);
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

        _verifySaleSignatures(_tokenData, _saleData, collectionAddress, tokenOwner);

        uint saleProceedingsToSend = _saleData.price;
        saleProceedingsToSend -= _takeProtocolFee(_saleData.price);

        Ownership.Split memory baseRoyalty = collection.getBaseRoyalty();
        Ownership.Royalties memory royalties = collection.getRoyalties(_tokenData.id);
        if ((royalties.splits[0].account == tokenOwner && royalties.splits.length == 1) || 
            (baseRoyalty.account == tokenOwner && royalties.splits.length == 0)){ // if no royalties and token owner same contract owner
            AddressUpgradeable.sendValue(payable(tokenOwner), saleProceedingsToSend);
        } else if (royalties.splits.length > 0) { // if there are splits defined proceed to distribute
            uint royaltyAmount = (_saleData.price * royalties.percentage) / _feeDenominator();
            _distributeSplits(royalties.splits, royaltyAmount);
            saleProceedingsToSend -= royaltyAmount;
            AddressUpgradeable.sendValue(payable(tokenOwner), saleProceedingsToSend);
        } else { // if no split defined, and user is not the creator
            uint royaltyAmount = (_saleData.price * baseRoyalty.shares) / _feeDenominator();
            AddressUpgradeable.sendValue(baseRoyalty.account, royaltyAmount);
            saleProceedingsToSend -= royaltyAmount;
            AddressUpgradeable.sendValue(payable(tokenOwner), saleProceedingsToSend);
        }

        collection.safeTransferFrom(tokenOwner, msg.sender, _tokenData.id);
    }

    function _takeProtocolFee(uint _price) internal returns (uint protocolFeeAmount) {
        protocolFeeAmount = (_price * protocolFee.shares) / _feeDenominator();
        AddressUpgradeable.sendValue(protocolFee.account, protocolFeeAmount);
    }

    function _distributeSplits(Ownership.Split[] memory splits, uint _amountToSplit) internal {
        uint amountToSend = _amountToSplit;
        for (uint i; i < splits.length; i++) {
            uint splitAmount = (_amountToSplit * splits[i].shares) / _feeDenominator();
            if(i == splits.length - 1) {
                AddressUpgradeable.sendValue(splits[i].account, amountToSend);
            } else {
                AddressUpgradeable.sendValue(splits[i].account, splitAmount);
                amountToSend -= splitAmount;
            }
        }
    }

    function _verifySaleSignatures(
        Marketplace.TokenData calldata _tokenData, 
        Marketplace.SaleData calldata _saleData,
        address collectionAddress,
        address listingSigner
    ) internal view {
        require(block.timestamp <= _saleData.listingExpTimestamp, "ArttacaMarketplaceUpgradeable:buyAndMint:: Listing signature is probably expired.");
        require(block.timestamp <= _saleData.nodeExpTimestamp, "ArttacaMarketplaceUpgradeable:buyAndMint:: Node signature is probably expired.");
        
        require(
            _verifySignature(
                Marketplace.hashListing(collectionAddress, _tokenData, _saleData, false),
                listingSigner,
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