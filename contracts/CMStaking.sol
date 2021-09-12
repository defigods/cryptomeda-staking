// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "./interfaces/ICMStaking.sol";
import "./interfaces/IUtils.sol";

abstract contract CMStaking is ICMStaking, Ownable, EIP712 {
    struct Stake {
        address staker;
        uint256 share;
        uint256 stakeTime;
        uint256 lockupPeriod;
    }

    address immutable token;
    address public utils;

    Stake[] public stakes;
    uint256 public totalShare;

    bytes32 private constant STAKE_SIGNATURE_HASH =
        keccak256("Staked(address user,uint256 amount,uint256 lockupPeriod)");

    constructor(address _token) {
        require(_token != address(0), "Token cannot be zero address");
        token = _token;
    }

    function startSeason(
        uint256 reward,
        uint256 startTime,
        uint256 endTime
    ) external onlyOwner {
        IUtils(utils).startSeason(reward, startTime, endTime);
        emit SeasonStarted(reward, startTime, endTime);
    }

    function notifyReward() public {
        IUtils(utils).notifyReward();
    }

    function stake(
        uint256 amount,
        uint256 lockupPeriod,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(IUtils(utils).isActive(), "Not active season");
        require(amount > 0, "Amount should be bigger than zero");
        require(lockupPeriod > 0, "Lockup period should be bigger than zero");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparatorV4(),
                keccak256(
                    abi.encode(
                        STAKE_SIGNATURE_HASH,
                        keccak256(
                            "You can stake only through our platform, read more here: https://cryptomeda.tech/staking"
                        ),
                        msg.sender,
                        amount,
                        lockupPeriod
                    )
                )
            )
        );

        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == msg.sender, "INVALID_SIGNATURE");

        notifyReward();
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        uint256 share = totalShare == 0
            ? amount
            : ((totalShare * amount) /
                (IERC20(token).balanceOf(address(this))));

        stakes.push(
            Stake({
                staker: msg.sender,
                share: share,
                stakeTime: block.timestamp,
                lockupPeriod: lockupPeriod
            })
        );
        totalShare += share;

        emit Staked(msg.sender, amount, lockupPeriod);
    }

    function withdraw(uint256 stakeId, uint256 amount)
        external
        returns (uint256 amountOut)
    {
        notifyReward();
        amountOut = _withdraw(msg.sender, stakeId, amount);
        IERC20(token).transfer(msg.sender, amountOut);
    }

    function withdraw(uint256[] memory stakeIds, uint256[] memory amounts)
        external
        returns (uint256[] memory amountOuts)
    {
        require(stakeIds.length == amounts.length, "Invalid argument");
        notifyReward();

        uint256 amount;
        for (uint256 i = 0; i < stakeIds.length; i++) {
            amountOuts[i] = _withdraw(msg.sender, stakeIds[i], amounts[i]);
            amount += amountOuts[i];
        }
        IERC20(token).transfer(msg.sender, amount);
    }

    function _withdraw(
        address account,
        uint256 stakeId,
        uint256 share
    ) private returns (uint256 amount) {
        Stake memory _stake = stakes[stakeId];
        require(_stake.staker != account, "Caller is not staker");

        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 availableShare = _stake.share > share ? share : _stake.share;

        amount = (balance * availableShare) / totalShare;
        totalShare -= availableShare;
        _stake.share -= availableShare;

        emit Withdraw(account, stakeId, amount);
    }
}
