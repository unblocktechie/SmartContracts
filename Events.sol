//SPDX-License-Identifier: MIT
pragma solidity ^0.6.9;

contract Events {
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value);

    event Paused(
        address account);

    event Unpaused(
        address account);

    event WithdrawSuccess(
        address indexed sender,
        uint256 lpAmount,
        uint256 tokenAmount,
        uint256 tokenAmountInUSD,
        uint256 profit,
        uint256 timestamp
    );
    event GreyWithdraw(
        address indexed sender,
        uint256 withdrawShare,
        uint256 tokenAmount,
        uint256 tokenAmountInUSD,
        uint256 timestamp
    );

    event WithdrawRequested(
        address indexed sender,
        uint256 withdrawShare,
        uint256 tokenAmount,
        uint256 tokenAmountInUSD,
        uint256 profit,
        uint256 timestamp
    );

    event DepositLiquidty(
        address indexed sender,
        uint256 amountDeposited,
        uint256 amountDepositedInUSD,
        uint256 timeStamp
        );

    event LpAssigned(
        address indexed sender,
        uint256 amountDeposited,
        uint256 lpAmount,
        uint256 timeStamp
        );
    
    event UserMigrated(
        address indexed userAddress, 
        uint256 LpAmount,
        uint256 userInvestedAmount
        );
}
