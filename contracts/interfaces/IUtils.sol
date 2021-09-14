// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IUtils {
    function startSeason(
        uint256,
        uint256,
        uint256
    ) external;

    function isActive() external view returns (bool);

    function notifyReward() external;

    event SeasonStarted(uint256 reward, uint256 startTime, uint256 endTime);
}
