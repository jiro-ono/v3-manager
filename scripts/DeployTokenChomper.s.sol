// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "~/TokenChomper.sol";

contract DeployTokenChomper is Script {
  address _owner = vm.envAddress("OWNER_ADDRESS");
  address _operator = vm.envAddress("OPERATOR_ADDRESS");

  function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    vm.startBroadcast(deployerPrivateKey);

    address routeProcessor = vm.envAddress("ROUTE_PROCESSOR_ADDRESS");
    address weth = vm.envAddress("WETH_ADDRESS");

    TokenChomper tokenChomper = new TokenChomper(_operator, routeProcessor, weth);
  }
}