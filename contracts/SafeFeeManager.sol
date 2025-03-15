// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

abstract contract SafeFeeManager {
    struct TokenTracking {
        uint256 lastNonZeroTimestamp;
        uint256 balance;
    }

    mapping(address => mapping(address => TokenTracking)) internal tokenTracking;

    function _updateTokenTimestamp(address owner, address token, uint256 newBalance) internal {
        if (newBalance == 0) {
            tokenTracking[owner][token].lastNonZeroTimestamp = 0;
        } else if (tokenTracking[owner][token].balance == 0) {
            tokenTracking[owner][token].lastNonZeroTimestamp = block.timestamp;
        }
        tokenTracking[owner][token].balance = newBalance;
    }

    function _calculateWithdrawalFee(address owner, address token, uint256 ratePerSecond) internal view returns (uint256) {
        uint256 lastTime = tokenTracking[owner][token].lastNonZeroTimestamp;
        if (lastTime == 0) return 0;
        uint256 duration = block.timestamp - lastTime;
        return duration * ratePerSecond;
    }
}
