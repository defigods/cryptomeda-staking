// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICMStaking.sol";
import "./interfaces/IUtils.sol";

contract CMStaking is ICMStaking, Ownable {
    struct Stake {
        address staker;
        uint256 share;
        uint256 lockupEndTime;
    }

    address public immutable override stakingToken;
    address public utils;

    Stake[] public stakes;
    uint256 public totalShare;

    modifier notifyReward() {
        IUtils(utils).notifyReward();
        _;
    }

    constructor(address _token) {
        require(_token != address(0), "Token cannot be zero address");
        stakingToken = _token;
    }

    function setHelper(address _utils) external onlyOwner {
        require(_utils != address(0), "Helper cannot be zero address");
        utils = _utils;
    }

    function stake(uint256 amount, uint256 lockupPeriod) external notifyReward {
        require(IUtils(utils).isActive(), "Not active season");
        require(amount > 0, "Amount should be bigger than zero");
        require(lockupPeriod > 0, "Lockup period should be bigger than zero");

        IERC20(stakingToken).transferFrom(msg.sender, address(this), amount);

        uint256 share = totalShare == 0
            ? amount
            : ((totalShare * amount) /
                (IERC20(stakingToken).balanceOf(address(this))));

        stakes.push(
            Stake({
                staker: msg.sender,
                share: share,
                lockupEndTime: block.timestamp + lockupPeriod
            })
        );
        totalShare += share;

        emit Staked(msg.sender, amount, lockupPeriod);
    }

    function withdraw(uint256 stakeId, uint256 amount)
        external
        notifyReward
        returns (uint256 amountOut)
    {
        amountOut = _withdraw(msg.sender, stakeId, amount);
        IERC20(stakingToken).transfer(msg.sender, amountOut);
    }

    function withdrawBatch(
        uint256[] calldata stakeIds,
        uint256[] calldata amounts
    ) external notifyReward returns (uint256[] memory amountOuts) {
        require(stakeIds.length == amounts.length, "Invalid argument");

        uint256 amount;
        for (uint256 i = 0; i < stakeIds.length; i++) {
            amountOuts[i] = _withdraw(msg.sender, stakeIds[i], amounts[i]);
            amount += amountOuts[i];
        }
        IERC20(stakingToken).transfer(msg.sender, amount);
    }

    function _withdraw(
        address account,
        uint256 stakeId,
        uint256 share
    ) private returns (uint256 amount) {
        Stake storage _stake = stakes[stakeId];
        require(_stake.staker == account, "Caller is not staker");
        require(
            block.timestamp >= _stake.lockupEndTime,
            "Lockup duration not passed yet"
        );

        uint256 balance = IERC20(stakingToken).balanceOf(address(this));
        uint256 availableShare = _stake.share > share ? share : _stake.share;

        amount = (balance * availableShare) / totalShare;
        totalShare -= availableShare;
        _stake.share -= availableShare;

        emit Withdraw(account, stakeId, amount);
    }
}
