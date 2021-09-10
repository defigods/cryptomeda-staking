// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/ICMStaking.sol";
import "./interfaces/IUtils.sol";

contract Utils is IUtils, Ownable {
    using SafeMath for uint256;

    // season info
    uint256 public reward;
    uint256 public startTime;
    uint256 public endTime;
    bool public isActive;

    function startSeason(
        uint256 _reward,
        uint256 _startTime,
        uint256 _endTime
    ) external override onlyOwner {
        require(!isActive, "Another season is active");
        require(_reward > 0, "Reward should be non-zero");
        require(_startTime > block.timestamp, "Start time already passed");
        require(
            _endTime > _startTime,
            "End time should be later than start time"
        );
        reward = _reward;
        startTime = _startTime;
        endTime = _endTime;
        isActive = true;
    }

    function endSeason() external override onlyOwner {
        require(isActive, "No active season");
        isActive = false;
    }

    function notifyReward() external override onlyOwner {
        require(isActive, "No active season");

        uint256 _now = block.timestamp;
        uint256 _reward = reward.mul(
            _now.sub(startTime).div(endTime.sub(startTime))
        );

        IERC20(ICMStaking(owner()).token()).transfer(owner(), _reward);
    }
}
