// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface ICMStaking {
    function token() external returns (address);

    event SeasonStarted();
    event SeasonEnded();
    event Staked();
}
