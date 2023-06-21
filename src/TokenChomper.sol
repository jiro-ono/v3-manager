// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import "/interfaces/IRouteProcessor3.sol";
import "interfaces/IERC20.sol";
import "./Auth.sol";

contract TokenChomper is Auth {
  // takes in ERC20 tokens and uses route processor to swap tokens to eth or other base assets
  // todo: prob wanna mix in trident and unwindooor v2 stuff into this so it can swap on some of those pools (fee tokens & rebasing)
  // using the RouteProcessor3 contract

  error TransferFailed();

  bytes4 private constant TRANSFER_SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

  address public immutable weth;
  IRouteProcessor3 public routeProcessor;

  constructor(
    address _operator,
    address _routeProcessor,
    address _weth
  ) Auth(_operator) {
    // initial owner is msg.sender
    routeProcessor = IRouteProcessor3(_routeProcessor);
    weth = _weth;
  }

  function updateRouteProcessor(address _routeProcessor) external onlyOwner {
    routeProcessor = IRouteProcessor3(_routeProcessor);
  }

  // swap to any output token
    // guarded by owner
  function processRoute(
    address tokenIn,
    uint256 amountIn,
    address tokenOut,
    uint256 amoutOutMin,
    bytes memory route
  ) external onlyOwner {
    // process route to any output token, slippage will be handled by the route processor
    IERC20(tokenIn).transfer(address(routeProcessor), amountIn);
    routeProcessor.processRoute(
      tokenIn, amountIn, tokenOut, amoutOutMin, address(this), route
    ); 
  }

  // swap to weth using route & routeprocessor
    // guarded by operator
  function buyWethWithRoute(
    address tokenIn,
    uint256 amountIn,
    uint256 amoutOutMin,
    bytes memory route
  ) external onlyTrusted {
    // to address will always be this contract
    // tokenOut will always be weth
    // slippage will be handled by the route processor
    routeProcessor.processRoute(
      tokenIn, amountIn, weth, amoutOutMin, address(this), route
    ); 
  }


  // withdraw token
    // guarded by owner
  // Allow the owner to withdraw the funds and bridge them to mainnet.
  function withdraw(address token, address to, uint256 _value) onlyOwner external {
    if (token != address(0)) {
      _safeTransfer(token, to, _value);
    } 
    else {
      (bool success, ) = to.call{value: _value}("");
      require(success);
    }
  }
  
  function _safeTransfer(address token, address to, uint value) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_SELECTOR, to, value));
    if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferFailed();
  }

  // In case we receive any unwrapped ethereum we can call this.
  function wrapEth() external {
    weth.call{value: address(this).balance}("");
  }

  function doAction(address to, uint256 _value, bytes memory data) onlyOwner external {
    (bool success, ) = to.call{value: _value}(data);
    require(success);
  }

  receive() external payable {}
}