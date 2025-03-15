// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "./SafeFeeManager.sol";

abstract contract SafeStorage is SafeFeeManager, EIP712 {
    using ECDSA for bytes32;

    struct Close {
        bytes32 hashedPassword; // sign(sign(password))
        address[] lockers; // Security addresses
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
    uint256 public openFee;
    uint256 public withdrawalRate;

    event SafeOpened(address indexed owner, address[] lockers);
    event Deposit(address indexed owner, address indexed token, uint256 amount);
    event Withdrawal(address indexed owner, address indexed token, uint256 amount, uint256 validUntil);
    event LockSwapped(address indexed owner, address[] newLockers);

    constructor(uint256 _openFee, uint256 _withdrawalRate)
        EIP712("MultiLockSafe", "1")
    {
        openFee = _openFee;
        withdrawalRate = _withdrawalRate;
    }

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

    function _deposit(address owner, address token, uint256 amount) internal {
        Safe storage safe = safes[owner];
        require(safe.closeData.lockers.length > 0, "Safe not created");

        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        safe.tokenBalances[token] += amount;

        _updateTokenTimestamp(owner, token, safe.tokenBalances[token]);

        emit Deposit(owner, token, amount);
    }

    function _withdraw(Open calldata openData, address token, uint256 amount) internal {
        _validateOpenData(openData, token, amount);
        Safe storage safe = safes[openData.owner];

        uint256 fee = _calculateWithdrawalFee(openData.owner, token, withdrawalRate);
        require(msg.value >= fee, "Insufficient withdrawal fee");

        safe.tokenBalances[token] -= amount;
        _updateTokenTimestamp(openData.owner, token, safe.tokenBalances[token]);

        require(IERC20(token).transfer(openData.owner, amount), "Token transfer failed");

        emit Withdrawal(openData.owner, token, amount, openData.validUntil);
    }

    function _swapLock(Open calldata openData, Close calldata newClose) internal {
        _validateOpenData(openData, address(0), 0);
        Safe storage safe = safes[openData.owner];

        safe.closeData = newClose;

        emit LockSwapped(openData.owner, newClose.lockers);
    }
}
