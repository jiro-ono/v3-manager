// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.8.0;

import "utils/BaseTest.sol";

import "/V3Manager.sol";
import "interfaces/IERC20.sol";

import {console2} from "forge-std/console2.sol";

contract V3ManagerTest is BaseTest {
  IUniswapV3Factory public factory;
  V3Manager public v3Manager;

  address public mockMaker = 0xeaf0227968E6EA31417734f36a7691FF2f779f81;
  address public mockOwner = 0x4200000000000000000000000000000000000000;
  address public mockOperator = 0x4200000000000000000000000000000000000001;
  uint8 public protocolFee = 4; 
  
  address[] public poolsToTest = [
    0x21988C9CFD08db3b5793c2C6782271dC94749251, // MATIC-USDC
    0xFf5713FdbAD797b81539b5F9766859d4E050a6CC // SUSHI-WETH
  ];

  struct PreCollectedFees {
      uint128 amount0;
      uint128 amount1;
  }
  mapping(address => PreCollectedFees) preCollectedFeesMap;

  function setUp() public override {
    forkPolygon();
    super.setUp();

    factory = IUniswapV3Factory(constants.getAddress("polygon.v3Factory"));

    v3Manager = new V3Manager(mockOperator, address(factory), mockMaker, protocolFee);
    v3Manager.transferOwnership(mockOwner);

    vm.prank(mockOwner);
    v3Manager.acceptOwnership();
    
    // switch owner of factory to mockOwner
    vm.prank(factory.owner());
    factory.setOwner(address(v3Manager));
  }

  // ========================
  // Test main functionality
  // ========================

  function testCreateFeeTier() public {
    // new fee & tick spacing
    uint24 fee = 1000;
    int24 tickSpacing = 20;

    vm.prank(mockOwner);
    v3Manager.createFeeTier(fee, tickSpacing);

    assertEq(factory.feeAmountTickSpacing(fee), tickSpacing);
  }

  function testSetProtocolFeeAndApply() public {
    // new protocol fee
    uint8 newProtocolFee = 7;

    vm.prank(mockOwner);
    v3Manager.setProtocolFee(newProtocolFee);

    assertEq(v3Manager.protocolFee(), newProtocolFee);

    // update a pools protocolFee
    vm.prank(mockOperator);
    v3Manager.applyProtocolFee(poolsToTest);

    for (uint256 i = 0; i < poolsToTest.length; i++) {
      (, , , , , uint8 feeProtocol, ) = IUniswapV3Pool(poolsToTest[0]).slot0();
      assertEq(feeProtocol, (newProtocolFee + (newProtocolFee << 4)));
    }
  }

  function testSetMaker() public {
    // new maker
    address newMaker = 0x4200000000000000000000000000000000000003;

    vm.prank(mockOwner);
    v3Manager.setMaker(newMaker);

    assertEq(v3Manager.maker(), newMaker);
  }

  function testCollectFees() public {
    // grab pre-collection fees pending to be collected
    for (uint256 i = 0; i < poolsToTest.length; i++) {
      (uint128 amount0, uint128 amount1) = IUniswapV3Pool(poolsToTest[i]).protocolFees();
      // during collection slot is not fully cleared, so we need to subtract 1 from each amount 
      amount0--;
      amount1--;
      preCollectedFeesMap[poolsToTest[i]] = PreCollectedFees(amount0, amount1);
    }

    // collect fees from pools
    vm.prank(mockOperator);
    v3Manager.collectFees(poolsToTest);

    // check that fees were collected
    for (uint256 i = 0; i < poolsToTest.length; i++) {
      IERC20 token0 = IERC20(IUniswapV3Pool(poolsToTest[i]).token0());
      IERC20 token1 = IERC20(IUniswapV3Pool(poolsToTest[i]).token1());
      
      uint128 amount0 = uint128(token0.balanceOf(v3Manager.maker()));
      uint128 amount1 = uint128(token1.balanceOf(v3Manager.maker()));

      assertEq(amount0, preCollectedFeesMap[poolsToTest[i]].amount0);
      assertEq(amount1, preCollectedFeesMap[poolsToTest[i]].amount1);
    }
  }

  // ================
  // Gas Snapshots
  // ================

  function testGasSnapshotCollectFees() public {
    vm.prank(mockOperator);
    v3Manager.collectFees(poolsToTest);
  }

  // ================
  // Test bad inputs
  // ================
  function testCreateBadFee() public {
    // new fee & tick spacing
    uint24 fee = 1000001;
    int24 tickSpacing = 20;

    vm.prank(mockOwner);
    vm.expectRevert();
    v3Manager.createFeeTier(fee, tickSpacing);
  }

  function testCreateBadTickSpacing() public {
    // new fee & tick spacing
    uint24 fee = 1000;
    int24 tickSpacing = 16385;

    vm.prank(mockOwner);
    vm.expectRevert();
    v3Manager.createFeeTier(fee, tickSpacing);
  }

  function testBadProtocolFee() public {
    // new protocol fee
    uint8 newProtocolFee = 20;

    vm.prank(mockOwner);
    vm.expectRevert(); 
    v3Manager.setProtocolFee(newProtocolFee);
  }

  // ===========
  // Test onlyOwner & onlyOperator modifiers
  // ===========
  function testBadOnlyOwnerCall() public {
    vm.prank(mockOperator);
    vm.expectRevert();
    v3Manager.setProtocolFee(5);
  }

  function testBadOnlyOperatorCall() public {
    vm.prank(0x4200000000000000000000000000000000000005);
    vm.expectRevert();
    v3Manager.applyProtocolFee(poolsToTest);
  }

  // ===========
  // Test ownership transfer process
  // ===========
  function testTransferOwnership2Step() public {
    // transfer ownership to new address
    address newOwner = 0x4200000000000000000000000000000000000005;
    vm.prank(mockOwner);
    v3Manager.transferOwnership(newOwner);

    assertEq(v3Manager.pendingOwner(), newOwner);

    // accept ownership from new address
    vm.prank(newOwner);
    v3Manager.acceptOwnership();

    assertEq(v3Manager.owner(), newOwner);
  }

  function testTransferOwnershipBad2Step() public {
    // transfer ownership to new address
    address newOwner = 0x4200000000000000000000000000000000000005;
    address newOwner2 = 0x4200000000000000000000000000000000000007;
    vm.prank(mockOwner);
    v3Manager.transferOwnership(newOwner);

    assertEq(v3Manager.pendingOwner(), newOwner);

    // accept ownership from wrong address
    vm.prank(newOwner2);
    vm.expectRevert();
    v3Manager.acceptOwnership();

    assertEq(v3Manager.owner(), mockOwner);

    // now set pending as newOwner2 & try again
    vm.prank(mockOwner);
    v3Manager.transferOwnership(newOwner2);

    assertEq(v3Manager.pendingOwner(), newOwner2);

    // accept ownership from new address
    vm.prank(newOwner2);
    v3Manager.acceptOwnership();

    assertEq(v3Manager.owner(), newOwner2);
  }
}