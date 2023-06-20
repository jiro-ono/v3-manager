// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

library RouteProcessorHelper {

  function computeV3Route() public pure returns (bytes memory route) {

    // get commandCode
      // 1 = processMyERC20
      // 2 = processUserERC20
      // 3 = processNative
      // 4 = processOnePool
      // 5 = processInsideBento
      // 6 = applyPermit
    route = abi.encodePacked(uint8(0x02));

    // get tokenIn
    route = abi.encodePacked(route, 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    
    // get amount of routes to take
    route = abi.encodePacked(route, uint8(0x01));
    
    // get amount of shares for current route
    route = abi.encodePacked(route, uint16(0xffff));
    
    // get poolType
      // 0 = v2
      // 1 = v3
      // 2 = wrapNative
      // 3 = bentoBridge
      // 4 = trident
    route = abi.encodePacked(route, uint8(0x01));
    
    // get pool address
    route = abi.encodePacked(route, 0x59c055de24d3E16B5fDc0C91F85AB2ac831828d9);

    // get zeroForOne for v3 or direction for v2
    route = abi.encodePacked(route, uint8(0x00));

    // get receipent for v3 or to for v2
    route = abi.encodePacked(route, 0x4bb4c1B0745ef7B4642fEECcd0740deC417ca0a0);
    
    return route;
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