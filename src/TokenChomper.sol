// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import "/interfaces/IRouteProcessor3.sol";
import "./Auth.sol";

contract TokenChomper is Auth {
  // takes in ERC20 tokens and chomps them up to spit out eth or other base assets
  // using the RouteProcessor3 contract

  address public immutable weth;
  IRouteProcessor3 public immutable routeProcessor;

  constructor(
    address _operator,
    address _routeProcessor,
    address _weth
  ) Auth(_operator) {
    // initial owner is msg.sender
    routeProcessor = IRouteProcessor3(_routeProcessor);
    weth = _weth;
  }


  function buyWeth() external onlyTrusted {

  }

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
  
  // need to handle native eth withdraws

}