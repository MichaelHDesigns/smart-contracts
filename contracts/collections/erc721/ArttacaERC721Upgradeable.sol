// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (collections/erc721/ArttacaERC721Upgradeable.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

import "../../utils/VerifySignature.sol";
import "./IArttacaERC721Upgradeable.sol";

/**
 * @title ArttacaERC721Upgradeable
 * @dev This contract is an Arttaca ERC721 upgradeable collection.
 */
contract ArttacaERC721Upgradeable is OwnableUpgradeable, VerifySignature, ERC721BurnableUpgradeable, ERC721PausableUpgradeable, ERC721URIStorageUpgradeable, IArttacaERC721Upgradeable {

    address[] public splits;
    uint[] public shares;

    function __ArttacaERC721_initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        address[] memory _splits,
        uint[] memory _shares
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init();
        __Pausable_init();
        __ERC721Burnable_init();
        __ERC721URIStorage_init();
        _transferOwnership(_owner);

        splits = _splits;
        shares = _shares;
    }

    function mintAndTransfer(address _to, uint _tokenId) override external onlyOwner {
        _mint(_to, _tokenId);
    }

    function mintAndTransfer(address _to, uint _tokenId, bytes calldata _mintData) override external {
        (address signer, uint maxSupply, uint expirationTimestamp, bytes memory signature) = splitMintData(_mintData);
        require(owner() == signer, "ArttacaERC721Upgradeable:mintAndTransfer:: Signer is not the owner.");
        require(block.timestamp <= expirationTimestamp, "ArttacaERC721Upgradeable:mintAndTransfer:: Signature is expired.");
        require(
            verifyMint(signer, _tokenId, maxSupply, 1, expirationTimestamp, signature),
            "ArttacaERC721Upgradeable:mintAndTransfer:: Signature is not valid."
        );
        _mint(_to, _tokenId);
    }

    function pause() public virtual onlyOwner {
        _pause();
    }

    function unpause() public virtual onlyOwner {
        _unpause();
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}