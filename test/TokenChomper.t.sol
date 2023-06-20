// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.8.0;

import "utils/BaseTest.sol";

import "/TokenChomper.sol";
import "/RouteProcessorHelper.sol";
import "interfaces/IERC20.sol";

import {console2} from "forge-std/console2.sol";

contract TokenChomperTest is BaseTest {
  TokenChomper public tokenChomper;

  address public mockOwner = 0x4200000000000000000000000000000000000000;
  address public mockOperator = 0x4200000000000000000000000000000000000001;

  function setUp() public override {
    forkPolygon();
    super.setUp();
    
    tokenChomper = new TokenChomper(mockOperator, constants.getAddress("polygon.routeprocessor3"), constants.getAddress("polygon.wmatic"));
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
    bytes memory testRouteCompute = RouteProcessorHelper.computeV3Route();

    console2.logBytes(testRouteCompute);
  }

  function testProcessRouteOwner() public {
    // test with no slippage protection
    // swapping the wmatic for usdc
    address tokenIn = constants.getAddress("polygon.wmatic");
    uint256 amountIn = 1000000000000000000;
    address tokenOut = constants.getAddress("polygon.usdc");
    uint256 amountOutMin = 0;



    vm.startPrank(mockOwner);


  }

  function testBuyWethWithRouteOperator() public {

  }


}
