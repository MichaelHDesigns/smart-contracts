// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (collections/erc721/ArttacaERC721Factory.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import "./ArttacaERC721Upgradeable.sol";
import "./ArttacaERC721Beacon.sol";

/**
 * @title ArttacaERC721Factory
 * @dev This contract is a factory to create ERC721 collections.
 */
contract ArttacaERC721FactoryUpgradeable is Initializable {

    mapping(uint => address) private collections;
    uint public collectionsCount;
    ArttacaERC721Beacon beacon;

    /**
     * @dev Emitted when a new ArttacaERC721 contract is created.
     */
    event Arrtaca721Created(
        address indexed collectionAddress,
        address indexed owner,
        string name,
        string indexed symbol,
        string baseURI,
        address[] splits,
        uint[] shares
    );

    function __ArttacaERC721Factory_initialize(
        address _initBlueprint
    ) public initializer onlyInitializing {

        __ArttacaERC721Factory_initialize_unchained(_initBlueprint);
    }

    function __ArttacaERC721Factory_initialize_unchained(address _initBlueprint) public onlyInitializing {
        beacon = new ArttacaERC721Beacon(_initBlueprint);
    }

    function createCollection(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address[] memory _splits,
        uint[] memory _shares
    ) external returns (address) {

        BeaconProxy collection = new BeaconProxy(
            address(beacon),
            abi.encodeWithSelector(
                ArttacaERC721Upgradeable(address(0)).__ArttacaERC721_initialize.selector,
                msg.sender,
                _name,
                _symbol,
                _baseURI, 
                _splits,
                _shares
            )
        );
        address newCollectionAddress = address(collection);
        collections[collectionsCount] = newCollectionAddress;
        collectionsCount++;

        emit Arrtaca721Created(
            newCollectionAddress,
            msg.sender,
            _name,
            _symbol,
            _baseURI,
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

    uint256[50] private __gap;
}
