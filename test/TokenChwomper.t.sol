// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.8.0;

import "utils/BaseTest.sol";

import "~/TokenChwomper.sol";
import "../utils/RouteProcessorHelper.sol";
import "interfaces/IERC20.sol";
import "interfaces/IRouteProcessor.sol";

import {console2} from "forge-std/console2.sol";

contract TokenChwomperTest is BaseTest {
  address public redSnwapper;
  address public routeProcessor;
  RouteProcessorHelper public routeProcessorHelper;
  TokenChwomper public tokenChwomper;

  address public mockOwner = 0x4200000000000000000000000000000000000000;
  address public mockOperator = 0x4200000000000000000000000000000000000001;

  function setUp() public override {
    forkPolygon();
    super.setUp();

    redSnwapper = constants.getAddress("polygon.redSnwapper");
    routeProcessor = constants.getAddress("polygon.routeprocessor3");
    routeProcessorHelper = new RouteProcessorHelper(constants.getAddress("polygon.v2Factory"), constants.getAddress("polygon.v3Factory"), routeProcessor, constants.getAddress("mainnet.weth"));
    tokenChwomper = new TokenChwomper(mockOperator, redSnwapper, constants.getAddress("polygon.wmatic"));
    tokenChwomper.setTrusted(mockOwner, true);
    tokenChwomper.transferOwnership(mockOwner);

    vm.prank(mockOwner);
    tokenChwomper.acceptOwnership();

    // send tokens to tokenChwomper
    // 1k of each token, using wormhole bridge address for prank
    vm.startPrank(0x5a58505a96D1dbf8dF91cB21B54419FC36e93fdE);
    IERC20(constants.getAddress("polygon.usdc")).transfer(address(tokenChwomper), 1000000000);
    IERC20(constants.getAddress("polygon.wmatic")).transfer(address(tokenChwomper), 1000000000000000000000);
    vm.stopPrank();
  }

  function testWithdraw() public {
    // withdraw 1000 usdc, 1000 matic
    vm.startPrank(mockOwner);
    tokenChwomper.withdraw(constants.getAddress("polygon.usdc"), mockOwner, 1000000000);
    tokenChwomper.withdraw(constants.getAddress("polygon.wmatic"), mockOwner, 1000000000000000000000);
    vm.stopPrank();

    assertEq(IERC20(constants.getAddress("polygon.usdc")).balanceOf(mockOwner), 1000000000);
    assertEq(IERC20(constants.getAddress("polygon.wmatic")).balanceOf(mockOwner), 1000000000000000000000);
  }

  function testwrapEth() public {
  
  }

  function testSnwap() public {
    address tokenIn = constants.getAddress("polygon.wmatic");
    address tokenOut = constants.getAddress("polygon.usdc");

    uint256 amountIn = 1e18;
    uint256 amountOutMin = 0;

    uint256 beforeIn = IERC20(tokenIn).balanceOf(address(tokenChwomper));
    uint256 beforeOut = IERC20(tokenOut).balanceOf(address(tokenChwomper));

    bytes memory route = routeProcessorHelper.computeRoute(
      true,
      false,
      tokenIn,
      tokenOut,
      500,
      address(tokenChwomper)
    );

    bytes memory executorData = abi.encodeWithSelector(
      IRouteProcessor(routeProcessor).processRoute.selector,
      tokenIn,
      amountIn,
      tokenOut,
      amountOutMin,
      address(tokenChwomper),
      route
    );

    vm.prank(mockOperator);
    tokenChwomper.snwap(
      tokenIn,
      amountIn,
      address(tokenChwomper),
      tokenOut,
      amountOutMin,
      routeProcessor,
      executorData
    );

    assertEq(
      IERC20(tokenIn).balanceOf(address(tokenChwomper)),
      beforeIn - amountIn
    );
    assertGt(
      IERC20(tokenOut).balanceOf(address(tokenChwomper)),
      beforeOut
    );
  }

  function testSnwapMultiple() public {
    address tokenIn = constants.getAddress("polygon.wmatic");
    address tokenOut = constants.getAddress("polygon.usdc");

    uint256 amountIn = 1e18;
    uint256 amountOutMin = 0;

    uint256 beforeIn = IERC20(tokenIn).balanceOf(address(tokenChwomper));
    uint256 beforeOut = IERC20(tokenOut).balanceOf(address(tokenChwomper));

    bytes memory route = routeProcessorHelper.computeRoute(
      true,
      false,
      tokenIn,
      tokenOut,
      500,
      address(tokenChwomper)
    );

    bytes memory executorData = abi.encodeWithSelector(
      IRouteProcessor(routeProcessor).processRoute.selector,
      tokenIn,
      amountIn,
      tokenOut,
      amountOutMin,
      address(tokenChwomper),
      route
    );

    IRedSnwapper.InputToken[] memory inputs =
      new IRedSnwapper.InputToken[](1);
    IRedSnwapper.OutputToken[] memory outputs =
      new IRedSnwapper.OutputToken[](1);
    IRedSnwapper.Executor[] memory executors =
      new IRedSnwapper.Executor[](1);

    inputs[0] = IRedSnwapper.InputToken({
      token: tokenIn,
      amountIn: amountIn,
      transferTo: address(routeProcessor)
    });
    outputs[0] = IRedSnwapper.OutputToken({
      token: tokenOut,
      recipient: address(tokenChwomper),
      amountOutMin: amountOutMin
    });
    executors[0] = IRedSnwapper.Executor({
      executor: routeProcessor,
      value: 0,
      data: executorData
    });

    vm.startPrank(mockOperator);
    uint256[] memory amounts = tokenChwomper.snwapMultiple(
      inputs,
      outputs,
      executors
    );
    vm.stopPrank();

    assertEq(
      IERC20(tokenIn).balanceOf(address(tokenChwomper)),
      beforeIn - amountIn
    );
    assertEq(
      IERC20(tokenOut).balanceOf(address(tokenChwomper)),
      beforeOut + amounts[0]
    );
  }

  function testBuyWethWithRouteOperator() public {

  }


}