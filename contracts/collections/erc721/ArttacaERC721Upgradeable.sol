// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (collections/erc721/ArttacaERC721Upgradeable.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import "./IArrtacaERC721Upgradeable.sol";

/**
 * @title ArttacaERC721Upgradeable
 * @dev This contract is an Arttaca ERC721 upgradeable collection.
 */
contract ArttacaERC721Upgradeable is OwnableUpgradeable, ERC721Upgradeable, IArrtacaERC721Upgradeable {

    address[] public splits;
    uint[] public shares;
    mapping(uint => bytes) mintDataList;

    function __ArttacaERC721_initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        address[] memory _splits,
        uint[] memory _shares
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init();
        _transferOwnership(_owner);

        splits = _splits;
        shares = _shares;
    }

    function mintAndTransfer(address _to, uint _tokenId) override external onlyOwner {
        _mint(_to, _tokenId);
    }

    function mintAndTransfer(address _to, uint _tokenId, bytes calldata _mintData) override external onlyOwner {
        mintDataList[_tokenId] = _mintData;
        _mint(_to, _tokenId);
    }
}