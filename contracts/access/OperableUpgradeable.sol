// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (access/OperableUpgradeable.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title OperableUpgradeable
 * @dev This contract keeps the information about operators of a contract.
 */
contract OperableUpgradeable is OwnableUpgradeable {

    mapping (address => bool) operators;

    function __OperableUpgradeable_init() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function addOperator(address operator) external onlyOwner {
        operators[operator] = true;
    }

    function removeOperator(address operator) external onlyOwner {
        operators[operator] = false;
    }

    modifier onlyOperator() {
        require(operators[_msgSender()], "OperableUpgradeable::onlyOperator: the caller is not an operator.");
        _;
    }
}