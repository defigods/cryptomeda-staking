// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICMStaking.sol";
import "./interfaces/IUtils.sol";

contract Utils is IUtils, Ownable {
    address public vault;
    uint256 public reward;
    uint256 public rewardPerSecond;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public lastClaimedTime;

    modifier onlyVault() {
        require(msg.sender == vault, "Caller is not the vault");
        _;
    }

    function setVault(address _vault) external onlyOwner {
        require(_vault != address(0), "Vault cannot be zero address");
        vault = _vault;
    }

    function startSeason(
        uint256 _reward,
        uint256 _startTime,
        uint256 _endTime
    ) external override onlyVault {
        require(_reward > 0, "Reward should be bigger than zero");
        require(block.timestamp > endTime, "Previous season is still active");
        require(_startTime >= block.timestamp, "Start time has already passed");
        require(
            _endTime > _startTime,
            "End time should be later than start time"
        );
        if (lastClaimedTime < endTime) {
            notifyReward();
        }

        reward = _reward;
        startTime = _startTime;
        endTime = _endTime;
        lastClaimedTime = startTime;
        rewardPerSecond = (reward * 1e10) / (endTime - startTime);
    }

    function notifyReward() public override {
        require(block.timestamp > lastClaimedTime, "Season is not active");
        uint256 lastTime = block.timestamp > endTime
            ? endTime
            : block.timestamp;
        uint256 _reward = (rewardPerSecond * (lastTime - lastClaimedTime)) /
            1e10;
        IERC20(ICMStaking(vault).stakingToken()).transfer(vault, _reward);
        lastClaimedTime = lastTime;
    }

    function isActive() external view override returns (bool) {
        return block.timestamp >= startTime && block.timestamp <= endTime;
    }
}
