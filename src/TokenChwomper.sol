// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import "interfaces/IRedSnwapper.sol";
import "interfaces/IERC20.sol";
import "./Auth.sol";

/// @title TokenChwomper for selling accumulated tokens for weth or other base assets
/// @notice This contract will be used for fee collection and breakdown
/// @dev Uses Auth contract for 2-step owner process and trust operators to guard functions
contract TokenChwomper is Auth {
  address public immutable weth;
  IRedSnwapper public redSnwapper;

  bytes4 private constant TRANSFER_SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

  error TransferFailed();

  constructor(
    address _operator,
    address _redSnwapper,
    address _weth
  ) Auth(_operator) {
    // initial owner is msg.sender
    redSnwapper = IRedSnwapper(_redSnwapper);
    weth = _weth;
  }

  /// @notice Updates the RedSnwapper to be used for swapping tokens
  /// @dev make sure new RedSnwapper is backwards compatiable (should be)
  /// @param _redSnwapper The address of the new route processor
  function updateRedSnwapper(address _redSnwapper) external onlyOwner {
    redSnwapper = IRedSnwapper(_redSnwapper);
  }
  
  /// @notice Swaps tokens via the configured RedSnwapper
  /// @dev Must be called by a trusted operator
  /// @param tokenIn Address of the input token
  /// @param amountIn Amount of the input token to swap
  /// @param recipient Address to receive the output tokens
  /// @param tokenOut Address of the output token
  /// @param amountOutMin Minimum acceptable amount of output tokens (slippage protection)
  /// @param executor Address of the executor contract to perform the swap logic
  /// @param executorData Encoded data for the executor call
  /// @return amountOut The actual amount of output tokens received
  function snwap(
    address tokenIn,
    uint256 amountIn,
    address recipient,
    address tokenOut,
    uint256 amountOutMin,
    address executor,
    bytes calldata executorData
  ) external onlyTrusted returns (uint256 amountOut) {
     // Pre-fund RedSnwapper with input tokens
     _safeTransfer(tokenIn, address(redSnwapper), amountIn);

    // Execute snwap with zero amountIn
    amountOut = redSnwapper.snwap(
      tokenIn,
      0,
      recipient,
      tokenOut,
      amountOutMin,
      executor,
      executorData
    );
  }

  /// @notice Performs multiple swaps via the configured RedSnwapper
  /// @dev Must be called by a trusted operator
  /// @param inputTokens Array of input token parameters
  /// @param outputTokens Array of output token requirements
  /// @param executors Array of executor calls to perform
  /// @return amountOut Array of actual amounts of output tokens received
  function snwapMultiple(
    IRedSnwapper.InputToken[] calldata inputTokens,
    IRedSnwapper.OutputToken[] calldata outputTokens,
    IRedSnwapper.Executor[] calldata executors
  ) external onlyTrusted returns (uint256[] memory amountOut) {
   uint256 length = inputTokens.length;
    IRedSnwapper.InputToken[] memory _inputTokens = new IRedSnwapper.InputToken[](length);
    for (uint256 i = 0; i < length; ++i) {
        // Pre-fund RedSnwapper with input tokens
        _safeTransfer(
            inputTokens[i].token,
            address(redSnwapper),
            inputTokens[i].amountIn
        );
        // Build _inputTokens with zero amountIn
        _inputTokens[i] = IRedSnwapper.InputToken({
            token: inputTokens[i].token,
            amountIn: 0,
            transferTo: inputTokens[i].transferTo
        });
    }

    // Execute snwapMultiple
    amountOut = redSnwapper.snwapMultiple(
        _inputTokens,
        outputTokens,
        executors
    );
  }

  /// @notice Withdraw any token or eth from the contract
  /// @dev can only be called by owner
  /// @param token The address of the token to be withdrawn, 0x0 for eth
  /// @param to The address to send the token to
  /// @param _value The amount of the token to be withdrawn
  function withdraw(address token, address to, uint256 _value) onlyOwner external {
    if (token != address(0)) {
      _safeTransfer(token, to, _value);
    } 
    else {
      (bool success, ) = to.call{value: _value}("");
      require(success);
    }
  }
  
  function _safeTransfer(address token, address to, uint value) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_SELECTOR, to, value));
    if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferFailed();
  }

  /// @notice In case we receive any unwrapped eth (native token) we can call this
  /// @dev operators can call this 
  function wrapEth() onlyTrusted external {
    weth.call{value: address(this).balance}("");
  }

  /// @notice Available function in case we need to do any calls that aren't supported by the contract (unwinding lp positions, etc.)
  /// @dev can only be called by owner
  /// @param to The address to send the call to
  /// @param _value The amount of eth to send with the call
  /// @param data The data to be sent with the call
  function doAction(address to, uint256 _value, bytes memory data) onlyOwner external {
    (bool success, ) = to.call{value: _value}(data);
    require(success);
  }

  receive() external payable {}
}