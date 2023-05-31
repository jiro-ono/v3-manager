// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.8.0;

import "v3-core/interfaces/IUniswapV3Factory.sol";
import "v3-core/interfaces/IUniswapV3Pool.sol";
import "./Auth.sol";


contract V3Manager is Auth {
  IUniswapV3Factory public factory;
  address public maker;
  uint8 public protocolFee;

  constructor(
    address owner,
    address operator,
    address factoryAddress,
    address makerAddress,
    uint8 _protocolFee
  ) Auth(owner, operator) {
    factory = IUniswapV3Factory(factoryAddress);
    maker = makerAddress;
    protocolFee = _protocolFee;
  }


  // creating fee tiers, should be behind multisig / owner of this contract
    // will call enableFeeAmount on factory contract
  function createFeeTier(uint24 fee, int24 tickSpacing) external onlyOwner {
    IUniswapV3Factory(factory).enableFeeAmount(fee, tickSpacing);
  }

  // setting protocol fee, we'll have a single protocol fee for all pools to start
  // only multisig / owner can call this
  function setProtocolFee(uint8 _protocolFee) external onlyOwner {
    require(
      _protocolFee == 0 || (_protocolFee >= 4 && _protocolFee <= 10)
    );
    protocolFee = _protocolFee;
  }

  // setting maker / receiver contract for fee collection
  // only multisig / owner can call this
  function setMaker(address _maker) external onlyOwner {
    maker = _maker;
  }

  // apply protocol fee to pool, operators can call this
    // will call setFeeProtocol on each pool address
  function applyProtocolFee(address[] calldata pools) external onlyTrusted {
    // todo: let's see if _increment is better for gas -> https://github.com/sushiswap/StakingContract/blob/master/src/StakingContractMainnet.sol#L418
    for (uint256 i = 0; i < pools.length; i++) {
      IUniswapV3Pool pool = IUniswapV3Pool(pools[i]);
      pool.setFeeProtocol(protocolFee, protocolFee);
    }
  } 

  // collect fees from pools, operators can call this
  // send to a maker contract for fee breakdown / swaps
    // will call collectProtocol on each pool address
  function collectFees(address[] calldata pools, uint128[] calldata amount0Requested, uint128[] calldata amount1Requested) external onlyTrusted {
    for (uint256 i = 0; i < pools.length; i++) {
      IUniswapV3Pool pool = IUniswapV3Pool(pools[i]);
      pool.collectProtocol(maker, amount0Requested[i], amount1Requested[i]);
    }
  }
}