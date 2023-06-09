// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "./Constants.sol";

abstract contract BaseTest is Test {
    Constants internal constants;

    address payable internal deployer;
    address payable internal alice;
    address payable internal bob;
    address payable internal carol;

    function setUp() public virtual {
        deployer = payable(tx.origin);
        alice = createUser("alice", address(0x1));
        bob = createUser("bob", address(0x2));
        carol = createUser("carol", address(0x3));

        constants = new Constants();
        constants.initAddressLabels(vm);
    }

    function createUser(string memory label, address account) internal returns (address payable) {
        vm.deal(account, 100 ether);
        vm.label(account, label);
        return payable (account);
    }

    function advanceBlocks(uint256 delta) internal returns (uint256 blockNumber) {
        blockNumber = block.number + delta;
        vm.roll(blockNumber);
    }

    function advanceTime(uint256 delta) internal returns (uint256 timestamp) {
        timestamp = block.timestamp + delta;
        vm.warp(timestamp);
    }

    function forkMainnet() internal {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));
    }

    function forkOptimism() internal {
        vm.createSelectFork(vm.envString("OPTIMISM_RPC_URL"));
    }

    function forkArbitrum() internal {
        vm.createSelectFork(vm.envString("ARBITRUM_RPC_URL"));
    }

    function forkPolygon() internal {
        vm.createSelectFork(vm.envString("POLYGON_RPC_URL"));
    }

    function forkFantom() internal {
        vm.createSelectFork(vm.envString("FANTOM_RPC_URL"));
    }

}
