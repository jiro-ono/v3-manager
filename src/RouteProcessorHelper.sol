// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import "/interfaces/IUniswapV2Factory.sol";
import "/interfaces/IUniswapV3Factory.sol";
import "interfaces/IUniswapV3Pool.sol";
import "interfaces/IUniswapV2Pair.sol";

contract RouteProcessorHelper {
  IUniswapV2Factory public v2Factory;
  IUniswapV3Factory public v3Factory;

  constructor (address _v2Factory, address _v3Factory) {
    v2Factory = IUniswapV2Factory(_v2Factory);
    v3Factory = IUniswapV3Factory(_v3Factory);
  }

  // only computes routes for v2, and v3 single hop swaps
  // mainly to be used for testing purposes
  function computeRoute(bool isV2, address tokenIn, address tokenOut, uint24 fee, address to) public view returns (bytes memory route) {
    address pair;
    address token0;
    address token1;
    uint8 direction;

    if (isV2) {
      pair = v2Factory.getPair(tokenIn, tokenOut);
      token0 = IUniswapV2Pair(pair).token0();
      token1 = IUniswapV2Pair(pair).token1();
    } else {
      pair = v3Factory.getPool(tokenIn, tokenOut, fee);
      token0 = IUniswapV3Pool(pair).token0();
      token1 = IUniswapV3Pool(pair).token1();
    }

    if (token0 == tokenIn) {
      direction = uint8(0x01);
    } else {
      direction = uint8(0x00);
    }

    route = abi.encodePacked(
      uint8(0x02), // always does commandCode processUserERC20
      tokenIn,
      uint8(0x01), // always does 1 route
      uint16(0xffff), // always does full amount
      uint8(isV2 ? 0x00 : 0x01), // poolType (0 = v2, 1 = v3)
      pair,
      direction,
      to
    );
  }
}


/*V3 Route

0x0282af49447d8a07e3bd95bd0d56f35241523fbab101ffff0159c055de24d3e16b5fdc0c91f85ab2ac831828d9004bb4c1b0745ef7b4642feeccd0740dec417ca0a0

0x02 -> commandCode (2 = processUserERC20)
0x82af49447d8a07e3bd95bd0d56f35241523fbab1 -> tokenIn
0x01 -> amount of routes taken
0xffff -> share of amountIn for current route in loop (0xffff is full amount)
0x01 -> poolType (0 = v2, 1 = v3)
0x59c055de24d3e16b5fdc0c91f85ab2ac831828d9 -> poolAddress
0x00 -> zeroForOne (0 = false, 1 = true or 0 = token0 to token1 and 1 = token1 to token0 in pool)
0x4bb4c1b0745ef7b4642feeccd0740dec417ca0a0 -> receipent
*/

/*
0x0282af49447d8a07e3bd95bd0d56f35241523fbab101ffff0159c055de24d3e16b5fdc0c91f85ab2ac831828d9004bb4c1b0745ef7b4642feeccd0740dec417ca0a0
0x0282af49447d8a07e3bd95bd0d56f35241523fbab101ffff0159c055de24d3e16b5fdc0c91f85ab2ac831828d9004bb4c1b0745ef7b4642feeccd0740dec417ca0a0
*/