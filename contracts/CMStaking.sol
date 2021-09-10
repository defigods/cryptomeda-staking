// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "./interfaces/ICMStaking.sol";
import "./interfaces/IUtils.sol";

abstract contract CMStaking is ICMStaking, Ownable, EIP712 {
    using SafeMath for uint256;

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
        keccak256(
            "Staked(address indexed user,uint256 amount,uint256 lockupPeriod)"
        );

    constructor(address _token) {
        require(_token != address(0), "Token address should be non-zero");
        token = _token;
    }

    function startSeason(
        uint256 reward,
        uint256 startTime,
        uint256 endTime
    ) external onlyOwner {
        IUtils(utils).startSeason(reward, startTime, endTime);
        emit SeasonStarted();
    }

    function endSeason() external onlyOwner {
        IUtils(utils).endSeason();
        emit SeasonEnded();
    }

    function stake(
        uint256 amount,
        uint256 lockupPeriod,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(amount > 0, "Amount should be bigger than zero");

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

        IUtils(utils).notifyReward();

        uint256 share;
        if (totalShare == 0) {
            share = amount;
        } else {
            share = totalShare.mul(amount).div(
                IERC20(token).balanceOf(address(this))
            );
        }
        stakes.push(
            Stake({
                staker: msg.sender,
                share: share,
                stakeTime: block.timestamp,
                lockupPeriod: lockupPeriod
            })
        );
        totalShare = totalShare.add(share);

        emit Staked();
    }

    function withdraw(uint256 stakeId, uint256 amount)
        external
        returns (uint256 amountOut)
    {
        IUtils(utils).notifyReward();
        amountOut = _withdraw(msg.sender, stakeId, amount);
    }

    function withdraw(uint256[] memory stakeIds, uint256[] memory amounts)
        external
        returns (uint256[] memory amountOuts)
    {
        require(stakeIds.length == amounts.length, "Invalid argument");
        IUtils(utils).notifyReward();
        for (uint256 i = 0; i < stakeIds.length; i++) {
            amountOuts[i] = _withdraw(msg.sender, stakeIds[i], amounts[i]);
        }
    }

    function _withdraw(
        address account,
        uint256 stakeId,
        uint256 amount
    ) private returns (uint256) {
        Stake memory _stake = stakes[stakeId];
        if (_stake.staker != account) {
            return 0;
        }
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 availableAmount = balance.mul(_stake.share).div(totalShare);
        if (availableAmount > amount) {
            uint256 share = totalShare.mul(availableAmount.sub(amount)).div(
                IERC20(token).balanceOf(address(this))
            );
            totalShare = totalShare.sub(_stake.share).add(share);
            _stake.share = share;
            return amount;
        } else {
            _stake.share = 0;
            return availableAmount;
        }
    }
}
