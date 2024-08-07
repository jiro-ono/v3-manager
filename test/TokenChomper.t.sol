// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.8.0;

import "utils/BaseTest.sol";

import "/TokenChomper.sol";
import "../utils/RouteProcessorHelper.sol";
import "interfaces/IERC20.sol";

import {console2} from "forge-std/console2.sol";

contract TokenChomperTest is BaseTest {
  RouteProcessorHelper public routeProcessorHelper;
  TokenChomper public tokenChomper;


  address public mockOwner = 0x4200000000000000000000000000000000000000;
  address public mockOperator = 0x4200000000000000000000000000000000000001;

  function setUp() public override {
    forkPolygon();
    super.setUp();
    
    routeProcessorHelper = new RouteProcessorHelper(constants.getAddress("polygon.v2Factory"), constants.getAddress("polygon.v3Factory"), constants.getAddress("mainnet.rp"), constants.getAddress("mainnet.weth"));
    tokenChomper = new TokenChomper(mockOperator, constants.getAddress("polygon.routeprocessor3"), constants.getAddress("polygon.wmatic"));
    tokenChomper.setTrusted(mockOwner, true);
    tokenChomper.transferOwnership(mockOwner);

    vm.prank(mockOwner);
    tokenChomper.acceptOwnership();

    // send tokens to tokenChomper
    // 1k of each token, using wormhole bridge address for prank
    vm.startPrank(0x5a58505a96D1dbf8dF91cB21B54419FC36e93fdE);
    IERC20(constants.getAddress("polygon.usdc")).transfer(address(tokenChomper), 1000000000);
    IERC20(constants.getAddress("polygon.wmatic")).transfer(address(tokenChomper), 1000000000000000000000);
    vm.stopPrank();
  }

  function testWithdraw() public {
    // withdraw 1000 usdc, 1000 matic
    vm.startPrank(mockOwner);
    tokenChomper.withdraw(constants.getAddress("polygon.usdc"), mockOwner, 1000000000);
    tokenChomper.withdraw(constants.getAddress("polygon.wmatic"), mockOwner, 1000000000000000000000);
    vm.stopPrank();

    assertEq(IERC20(constants.getAddress("polygon.usdc")).balanceOf(mockOwner), 1000000000);
    assertEq(IERC20(constants.getAddress("polygon.wmatic")).balanceOf(mockOwner), 1000000000000000000000);
  }

  function testwrapEth() public {
  
  }

  function testProcessRoute() public {
    // test with no slippage protection
    // swapping the wmatic for usdc
    address tokenIn = constants.getAddress("polygon.wmatic");
    address tokenOut = constants.getAddress("polygon.usdc");

    console2.log("before test swap");
    console2.log("tokenIn balance: ", IERC20(tokenIn).balanceOf(address(tokenChomper)));
    console2.log("tokenOut balance: ", IERC20(tokenOut).balanceOf(address(tokenChomper)));

    vm.startPrank(mockOperator);
    bytes memory testRouteCompute = routeProcessorHelper.computeRoute(
      true,
      false,
      tokenIn,
      tokenOut,
      500,
      address(tokenChomper)
    );
    tokenChomper.processRoute(tokenIn, 1000000000000000000000, tokenOut, 0, testRouteCompute);
    vm.stopPrank();

    console2.log("results of test swap");
    console2.log("tokenIn balance: ", IERC20(tokenIn).balanceOf(address(tokenChomper)));
    console2.log("tokenOut balance: ", IERC20(tokenOut).balanceOf(address(tokenChomper)));
  }

  function testBuyWethWithRouteOperator() public {

  }


}