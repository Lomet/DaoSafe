// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./SafeStorage.sol";

contract MultiLockSafe is SafeStorage {
    constructor(uint256 _openFee, uint256 _withdrawalRate)
        SafeStorage(_openFee, _withdrawalRate)
    {}

    function openSafe(Close calldata closeData) external payable {
        require(msg.value >= openFee, "Insufficient fee to open safe");
        require(closeData.lockers.length > 0, "Must provide at least one locker");

        Safe storage safe = safes[msg.sender];
        require(safe.closeData.lockers.length == 0, "Safe already exists");

        safe.closeData = closeData;

        emit SafeOpened(msg.sender, closeData.lockers);
    }

    function deposit(address token, uint256 amount) external {
        _deposit(msg.sender, token, amount);
    }

    function withdraw(Open calldata openData, address token, uint256 amount) external payable {
        _withdraw(openData, token, amount);
    }

    function swapLock(Open calldata openData, Close calldata newClose) external {
        _swapLock(openData, newClose);
    }
}
