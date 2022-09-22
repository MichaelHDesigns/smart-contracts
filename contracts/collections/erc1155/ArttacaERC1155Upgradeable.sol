// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (collections/erc721/ArttacaERC1155Upgradeable.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";

import "./IArttacaERC1155Upgradeable.sol";

/**
 * @title ArttacaERC1155Upgradeable
 * @dev This contract is an Arttaca ERC1155 upgradeable collection.
 */
contract ArttacaERC1155Upgradeable is OwnableUpgradeable, ERC1155BurnableUpgradeable, IArttacaERC1155Upgradeable {

    string name;
    string symbol;
    address[] public splits;
    uint[] public shares;
    mapping(uint => bytes) mintDataList;

    function __ArttacaERC1155_initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        address[] memory _splits,
        uint[] memory _shares
    ) public initializer {
        __ERC1155_init("");
        __Ownable_init();
        _transferOwnership(_owner);

        name = _name;
        symbol = _symbol;
        splits = _splits;
        shares = _shares;
    }

    function mintAndTransfer(address _to, uint _tokenId, uint _quantity) override external onlyOwner {
        _mint(_to, _tokenId, _quantity, "");
    }

    function mintAndTransfer(
        address _to, 
        uint _tokenId, 
        uint _quantity, 
        bytes calldata _mintData
    ) override external onlyOwner {
        mintDataList[_tokenId] = _mintData;
        _mint(_to, _tokenId, _quantity, "");
    }
}