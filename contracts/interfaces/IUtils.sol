// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IUtils {
    function startSeason(
        uint256,
        uint256,
        uint256
    ) external;

    function endSeason() external;

    function notifyReward() external;
}
