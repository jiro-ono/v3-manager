// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.8.0;

import "utils/BaseTest.sol";

import "/V3Manager.sol";

import {console2} from "forge-std/console2.sol";

contract V3ManagerTest is BaseTest {
  IUniswapV3Factory public factory;
  V3Manager public v3Manager;

  address public mockMaker = 0xeaf0227968E6EA31417734f36a7691FF2f779f81;
  address public mockOwner = 0x4200000000000000000000000000000000000000;
  address public mockOperator = 0x4200000000000000000000000000000000000001;
  uint8 public protocolFee = 4; 
  
  address[] public testPools = [
    0x21988C9CFD08db3b5793c2C6782271dC94749251, // MATIC-USDC
    0xFf5713FdbAD797b81539b5F9766859d4E050a6CC, // SUSHI-WETH
    0x1b0585Fc8195fc04a46A365E670024Dfb63a960C, // USDC-WETH
    0xf1A12338D39Fc085D8631E1A745B5116BC9b2A32  // MATIC-WETH
  ];

  function setUp() public override {
    forkPolygon();
    super.setUp();

    factory = IUniswapV3Factory(constants.getAddress("polygon.v3Factory"));

    v3Manager = new V3Manager(mockOwner, mockOperator, address(factory), mockMaker, protocolFee);
    
    // switch owner of factory to mockOwner
    vm.prank(factory.owner());
    factory.setOwner(address(v3Manager));
  }

  function testCreateFeeTier() public {
    // new fee & tick spacing
    uint24 fee = 1000;
    int24 tickSpacing = 20;

    vm.prank(mockOwner);
    v3Manager.createFeeTier(fee, tickSpacing);

    assertEq(factory.feeAmountTickSpacing(fee), tickSpacing);
  }

  // test bad create fee tier

  function testSetProtocolFee() public {

  }

  // test bad set protocol fee

  function testSetMaker() public {

  }

  function testApplyProtocolFeeSinglePool() public {

  }

  function testApplyProtocolFeeMultiplePools() public {

  }

  function testCollectFeesSinglePool() public {

  }

  function testCollectFeesMultiplePools() public {

  }

  // test owner & operator controls
}