// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (collections/erc721/ArttacaERC721Upgradeable.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";

import "../../utils/VerifySignature.sol";
import "./IArttacaERC721Upgradeable.sol";

/**
 * @title ArttacaERC721Upgradeable
 * @dev This contract is an Arttaca ERC721 upgradeable collection.
 */
contract ArttacaERC721Upgradeable is OwnableUpgradeable, VerifySignature, ERC721BurnableUpgradeable, ERC721PausableUpgradeable, ERC721URIStorageUpgradeable, ERC721EnumerableUpgradeable, ERC2981Upgradeable, IArttacaERC721Upgradeable {

    address[] public splits;
    uint[] public shares;
    string public baseURI;

    function __ArttacaERC721_initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        string memory _baseURIParam,
        address[] memory _splits,
        uint[] memory _shares,
        uint96 _royaltyPercentage
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init();
        __Pausable_init();
        __ERC721Burnable_init();
        __ERC721URIStorage_init();
        __ERC2981_init();
        _transferOwnership(_owner);
        _setDefaultRoyalty(address(this), _royaltyPercentage);

        baseURI = _baseURIParam;
        splits = _splits;
        shares = _shares;
    }

    function mintAndTransfer(address _to, uint _tokenId) override external onlyOwner {
        _mint(_to, _tokenId);
    }

    function getAddress() external view returns (address) {
        return address(this);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _baseURIParam) external onlyOwner {
        baseURI = _baseURIParam;
    }

    function mintAndTransfer(MintData calldata _mintData) override external {
        require(owner() == _mintData.signer, "ArttacaERC721Upgradeable:mintAndTransfer:: Signer is not the owner.");
        require(block.timestamp <= _mintData.expirationTimestamp, "ArttacaERC721Upgradeable:mintAndTransfer:: Signature is expired.");
        require(
            _verifySignature(
                abi.encodePacked(
                    address(this),
                    _mintData.to,
                    _mintData.tokenId,
                    _mintData.tokenURI,
                    _mintData.expirationTimestamp
                ),
                _mintData.signer,
                _mintData.signature
            ),
            "ArttacaERC721Upgradeable:mintAndTransfer:: Signature is not valid."
        );
        _mint(_mintData.to, _mintData.tokenId);
        _setTokenURI(_mintData.tokenId, _mintData.tokenURI);
    }

    function tokensOfOwner(address _owner) public view returns(uint[] memory ) {
        uint tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            uint index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function pause() public virtual onlyOwner {
        _pause();
    }

    function unpause() public virtual onlyOwner {
        _unpause();
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
        require(!paused(), "ERC721Pausable: token transfer while paused");
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC2981Upgradeable) returns (bool) {
        return interfaceId == type(IArttacaERC721Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721PausableUpgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}