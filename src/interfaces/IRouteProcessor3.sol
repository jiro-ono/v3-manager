// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.8.0;

interface IRouteProcessor3 {
  
  event Route(
    address indexed from, 
    address to, 
    address indexed tokenIn, 
    address indexed tokenOut, 
    uint amountIn, 
    uint amountOutMin,
    uint amountOut
  );
  
  function processRoute(
    address tokenIn,
    uint256 amountIn,
    address tokenOut,
    uint256 amountOutMin,
    address to,
    bytes memory route
  ) external payable returns (uint256 amountOut);
}