// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (collections/erc721/ArttacaERC1155Factory.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import "./ArttacaERC1155Upgradeable.sol";
import "./ArttacaERC1155Beacon.sol";

/**
 * @title ArttacaERC1155Factory
 * @dev This contract is a factory to create ERC1155 collections.
 */
contract ArttacaERC1155Factory is Ownable {

    mapping(uint => address) private collections;
    uint public collectionsCount;
    ArttacaERC1155Beacon immutable beacon;

    /**
     * @dev Emitted when a new ArttacaERC1155 contract is created.
     */
    event Arrtaca721Created(
        address indexed collectionAddress,
        address indexed owner,
        string name,
        string symbol,
        address[] splits,
        uint[] shares
    );

    constructor(address _initBlueprint) {
        beacon = new ArttacaERC1155Beacon(_initBlueprint);
    }

    function createCollection(
        string memory _name,
        string memory _symbol,
        address[] memory _splits,
        uint[] memory _shares
    ) external onlyOwner returns (address) {

        BeaconProxy collection = new BeaconProxy(
            address(beacon),
            abi.encodeWithSelector(
                ArttacaERC1155Upgradeable(address(0)).__ArttacaERC1155_initialize.selector,
                msg.sender,
                _name,
                _symbol,
                _splits,
                _shares
            )
        );
        address newCollectionAddress = address(collection);
        collections[collectionsCount] = newCollectionAddress;
        collectionsCount++;

        emit Arrtaca721Created(
            newCollectionAddress,
            _msgSender(),
            _name,
            _symbol,
            _splits,
            _shares
        );

        return newCollectionAddress;
    }

    function getCollectionAddress(uint _index) public view returns (address) {
        return collections[_index];
    }

    function getBeacon() public view returns (address) {
        return address(beacon);
    }

    function getImplementation() public view returns (address) {
        return beacon.implementation();
    }
}
