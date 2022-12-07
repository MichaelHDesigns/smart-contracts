// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (contracts/splits/AbstractSplitsUpgradeable.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../lib/Ownership.sol";

/**
 * @title Arttaca AbstractSplitsUpgradeable
 * 
 * @dev Basic splits definition for Arttaca collections.
 */
abstract contract AbstractSplitsUpgradeable is IERC2981Upgradeable, ERC721Upgradeable, OwnableUpgradeable {

    uint96 internal feeNumerator = feeNumerator;
    mapping(uint => Ownership.Split[]) internal tokenSplits;

    function __Splits_init(uint96 _royaltyPct) internal onlyInitializing {
        __Splits_init_unchained(_royaltyPct);
    }

    function __Splits_init_unchained(uint96 _royaltyPct) internal onlyInitializing {
        _setDefaultRoyalty(_royaltyPct);
    }

    function royaltyInfo(uint _tokenId, uint _salePrice) public view virtual override returns (address, uint) {
        _requireMinted(_tokenId);
        uint royaltyAmount = (_salePrice * feeNumerator) / _feeDenominator();

        return (owner(), royaltyAmount);
    }

    function getSplits(uint _tokenId) public view returns (Ownership.Split[] memory) {
        _requireMinted(_tokenId);
        return tokenSplits[_tokenId];
    }

    function _setSplits(uint _tokenId, Ownership.Split[] memory _splits) internal {
        require(_checkSplits(_splits), "AbstractSplits::_setSplits: Total shares should less or equal than 10000.");
        if (tokenSplits[_tokenId].length > 0) delete tokenSplits[_tokenId];
        for (uint i; i < _splits.length; i++) {
            tokenSplits[_tokenId].push(_splits[i]);
        }
    }

    function _checkSplits(Ownership.Split[] memory _splits) internal pure returns (bool) {
        uint totalShares;
        for (uint i = 0; i < _splits.length; i++) {
            require(_splits[i].account != address(0x0), "AbstractSplits::_setSplits: Invalid account.");
            require(_splits[i].shares > 0, "AbstractSplits::_setSplits: Shares value must be greater than 0.");
            totalShares += _splits[i].shares;
        }
        return totalShares <= _feeDenominator();
    }

    function _setDefaultRoyalty(uint96 _feeNumerator) internal virtual {
        require(_feeNumerator <= _feeDenominator(), "AbstractSplits::_setDefaultRoyalty: Royalty fee must be lower than fee denominator.");
        feeNumerator = _feeNumerator;
    }

    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }
}