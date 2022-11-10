// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (collections/transfer-agent/TransferAgentUpgradeable.sol)

pragma solidity ^0.8.4;

import "../../access/OperableUpgradeable.sol";
import "../erc721/IArttacaERC721Upgradeable.sol";
import "../erc1155/IArttacaERC1155Upgradeable.sol";

/**
 * @title TransferAgentUpgradeable
 * @dev This contract centralizes the transfers responsibility for all the collections in Arttaca marketplace.
 */
contract TransferAgentUpgradeable is OperableUpgradeable {

    function __TransferAgent_init() external initializer {
        __OperableUpgradeable_init(msg.sender);
    }

    function erc721safeTransferFrom(IArttacaERC721Upgradeable token, address from, address to, uint256 tokenId) external onlyOperator {
        token.safeTransferFrom(from, to, tokenId);
    }

    function erc1155safeTransferFrom(IArttacaERC1155Upgradeable token, address from, address to, uint256 id, uint256 value, bytes calldata data) external onlyOperator {
        token.safeTransferFrom(from, to, id, value, data);
    }
}