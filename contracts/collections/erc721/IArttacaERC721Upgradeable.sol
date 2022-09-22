// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (collections/common/IArttacaERC721Upgradeable.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * @title Arttaca ERC721 interface, standard for Arttaca NFT collections.
 *
 * Contains the basic methods and functionalities that will be used for
 * Arttaca collections.
 */
interface IArttacaERC721Upgradeable is IERC721Upgradeable {

    /**
     * @dev Allows Owner to mint new assets in the collection.
     *
     * Requirements:
     *
     * - The `msg.sender` is the owner.
     * - The value '_to' must be different than a ZERO address.
     *
     * Emits a {Transfer} event for every new asset minted.
     */
    function mintAndTransfer(address _to, uint _tokenId) external;

    /**
     * @dev Allows anyone to mint assets if there's a valid owner signature.
     *
     * Requirements:
     *
     * - The `msg.sender` is the owner.
     * - The value '_to' must be different than a ZERO address.
     * - The value '_mintData' must contain valid signature and token information.
     *
     * Emits a {Transfer} event for every new asset minted.
     */
    function mintAndTransfer(address _to, uint _tokenId, bytes calldata _mintData) external;
}