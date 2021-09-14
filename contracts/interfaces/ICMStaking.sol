// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface ICMStaking {
    function stakingToken() external view returns (address);

    event Staked(address indexed account, uint256 amount, uint256 lockupPeriod);
    event Withdraw(
        address indexed account,
        uint256 indexed stakeId,
        uint256 amount
    );
}
