// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract VerifySignature {

    function verifyMint(
        address _signer,
        uint256 _tokenId,
        uint256 _maxSupply,
        uint256 _quantity,
        uint256 _expirationTimestamp,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                _signer,
                _tokenId,
                _maxSupply,
                _quantity,
                _expirationTimestamp
            )
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function splitMintData(bytes memory _bytes) internal pure returns (address, uint, uint, bytes memory) {
        require(_bytes.length >= 64, "VerifySignature::splitMintData: Incorrect mintData length.");
        address signer;
        uint256 expirationTime;
        uint256 maxSupply;
        assembly {
            signer := mload(add(add(_bytes, 0x20), 0))
            expirationTime := mload(add(add(_bytes, 0x20), 32))
            maxSupply := mload(add(add(_bytes, 0x20), 64))
        }
        return (signer, expirationTime, maxSupply, slice(_bytes, 96, 65));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_bytes.length >= (_start + _length));

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                tempBytes := mload(0x40)
                let lengthmod := and(_length, 31)
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            default {
                tempBytes := mload(0x40)
                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "VerifySignature::splitSignature: Invalid signature length.");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}