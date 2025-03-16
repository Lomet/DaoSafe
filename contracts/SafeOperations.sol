// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SafeFeeManager.sol";
import "./SafeCore.sol";

abstract contract SafeOperations is SafeCore, SafeFeeManager {
    event Deposit(address indexed owner, address indexed token, uint256 amount);
    event Withdrawal(address indexed owner, address indexed token, uint256 amount, uint256 validUntil);
    event LockSwapped(address indexed owner, address[] newLockers);

    uint256 public openFee;
    uint256 public withdrawalRate;

    constructor(uint256 _openFee, uint256 _withdrawalRate) {
        openFee = _openFee;
        withdrawalRate = _withdrawalRate;
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
