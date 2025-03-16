// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

abstract contract SafeCore is EIP712 {
    using ECDSA for bytes32;

    struct Close {
        bytes32 hashedPassword;
        address[] lockers;
    }

    struct Open {
        address owner;
        uint256 validUntil;
        bytes passwordSignature;
        bytes ownerSignature;
        bytes[] lockerSignatures;
    }

    struct Safe {
        Close closeData;
        mapping(address => uint256) tokenBalances;
    }

    mapping(address => Safe) internal safes;

    constructor() EIP712("MultiLockSafe", "1") {}

    function _validateOpenData(Open calldata openData, address token, uint256 amount) internal view {
        Safe storage safe = safes[openData.owner];
        require(safe.closeData.lockers.length > 0, "Safe not created");
        require(safe.tokenBalances[token] >= amount, "Insufficient balance");
        require(block.timestamp <= openData.validUntil, "Signature expired");

        bytes32 messageHash = keccak256(
            abi.encode(
                keccak256("Withdrawal(address owner,address token,uint256 amount,uint256 validUntil)"),
                openData.owner,
                token,
                amount,
                openData.validUntil
            )
        );

        require(_verifySignature(messageHash, openData.ownerSignature, openData.owner), "Invalid owner signature");

        address[] storage lockers = safe.closeData.lockers;
        for (uint256 i = 0; i < openData.lockerSignatures.length; i++) {
            address recovered = _hashTypedDataV4(messageHash).recover(openData.lockerSignatures[i]);
            bool validLocker = false;
            for (uint256 j = 0; j < lockers.length; j++) {
                if (lockers[j] == recovered) {
                    validLocker = true;
                    break;
                }
            }
            require(validLocker, "Invalid locker signature");
        }

        bytes32 hashedPassword = keccak256(openData.passwordSignature);
        require(hashedPassword == safe.closeData.hashedPassword, "Invalid password signature");
    }

    function _verifySignature(bytes32 messageHash, bytes memory signature, address expectedSigner) internal view returns (bool) {
        address recoveredSigner = _hashTypedDataV4(messageHash).recover(signature);
        return recoveredSigner == expectedSigner;
    }
}
