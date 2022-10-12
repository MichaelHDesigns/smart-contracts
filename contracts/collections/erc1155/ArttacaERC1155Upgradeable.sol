// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (collections/erc721/ArttacaERC1155Upgradeable.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";

import "../../utils/VerifySignature.sol";
import "./IArttacaERC1155Upgradeable.sol";

/**
 * @title ArttacaERC1155Upgradeable
 * @dev This contract is an Arttaca ERC1155 upgradeable collection.
 */
contract ArttacaERC1155Upgradeable is OwnableUpgradeable, VerifySignature, ERC1155SupplyUpgradeable, ERC1155BurnableUpgradeable, ERC1155PausableUpgradeable, ERC2981Upgradeable, IArttacaERC1155Upgradeable {

    string name;
    string symbol;
    address[] public splits;
    uint[] public shares;

    function __ArttacaERC1155_initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        address[] memory _splits,
        uint[] memory _shares
    ) public initializer {
        __ERC1155_init("");
        __Ownable_init();
        __Pausable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        _transferOwnership(_owner);

        name = _name;
        symbol = _symbol;
        splits = _splits;
        shares = _shares;
    }

    function mintAndTransfer(address _to, uint _tokenId, uint _quantity, bytes calldata _data) override external onlyOwner {
        _mint(_to, _tokenId, _quantity, _data);
    }

    function mintAndTransfer(
        address _to, 
        uint _tokenId, 
        uint _quantity, 
        bytes calldata _mintData,
        bytes calldata _data
    ) override external onlyOwner {
        // (address signer, uint maxSupply, uint expirationTimestamp, bytes memory signature) = splitMintData(_mintData);
        // require(owner() == signer, "ArttacaERC721Upgradeable:mintAndTransfer:: Signer is not the owner.");
        // require(block.timestamp <= expirationTimestamp, "ArttacaERC721Upgradeable:mintAndTransfer:: Signature is expired.");
        // require(maxSupply >= totalSupply(_tokenId) + _quantity, "ArttacaERC721Upgradeable:mintAndTransfer:: Signed MaxSupply is not sufficient to comply with the requested quantity.");
        // require(
        //     verifyMint(address(this), signer, _to, _tokenId, maxSupply, _quantity, expirationTimestamp, signature),
        //     "ArttacaERC721Upgradeable:mintAndTransfer:: Signature is not valid."
        // );
        // todo consider maxsupply
        _mint(_to, _tokenId, _quantity, _data);
    }

    function pause() public virtual onlyOwner {
        _pause();
    }

    function unpause() public virtual onlyOwner {
        _unpause();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC1155Upgradeable, ERC2981Upgradeable) returns (bool) {
        return interfaceId == type(IArttacaERC1155Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Upgradeable, ERC1155SupplyUpgradeable, ERC1155PausableUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}