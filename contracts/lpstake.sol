// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/base/LiquidityManagement.sol";
import "hardhat/console.sol";

contract lpstake {
    address owner;
    uint8 immutable _decimalsUSDC = 6;
    ISwapRouter public immutable swapRouter;

    // address public constant USDC =0xD87Ba7A50B2E7E660f678A895E4B72E7CB4CCd9C ;//goerli
    // address public constant DAI=0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60 ;//goerli
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;//mainnet
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;//mainnet
    uint24 public constant poolFee = 100;

    INonfungiblePositionManager public immutable nonfungiblePositionManager;

    /// @notice Represents the deposit of an NFT
    struct Deposit {
        address owner;
        uint128 liquidity;
        address token0;
        address token1;
    }

    /// @dev deposits[tokenId] => Deposit
    mapping(uint => Deposit) public deposits;
    uint public tokenId;




    constructor(ISwapRouter _swapRouter,INonfungiblePositionManager _nonfungiblePositionManager) {
        swapRouter = _swapRouter;//0xE592427A0AEce92De3Edee1F18E0157C05861564
        nonfungiblePositionManager=_nonfungiblePositionManager;//0xC36442b4a4522E871399CD717aBDD847Ab11FE88
        owner = msg.sender;
    }

    function depositTokens(uint256 _amount) public {
        // amount should be > 0
        require(_amount>0);
        uint256 division= _amount/2;

        TransferHelper.safeTransferFrom(USDC, msg.sender, address(this), _amount);

        TransferHelper.safeApprove(USDC, address(swapRouter),_amount);

        uint256 daiDivision = swapExactInputSingle(division,USDC,DAI);
        // update staking balance
        mintNewPosition(daiDivision,division);
    }


    function swapExactInputSingle(uint256 amountIn,address inToken,address outToken) internal returns (uint256 amountOut) {
          
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: inToken,
                tokenOut: outToken,
                fee: 3000,
                // recipient: msg.sender,
                recipient:address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
    }

    // function onERC721Received(
    //     address operator,
    //     address,
    //     uint _tokenId,
    //     bytes calldata
    // ) external override returns (bytes4) {
    //     _createDeposit(operator, _tokenId);
    //     return this.onERC721Received.selector;
    // }

    function _createDeposit(address owner, uint _tokenId) internal {
        (
            ,
            ,
            address token0,
            address token1,
            ,
            ,
            ,
            uint128 liquidity,
            ,
            ,
            ,

        ) = nonfungiblePositionManager.positions(_tokenId);
        // set the owner and data for position
        // operator is msg.sender
        deposits[_tokenId] = Deposit({
            owner: owner,
            liquidity: liquidity,
            token0: token0,
            token1: token1
        });

        console.log("Token id", _tokenId);
        console.log("Liquidity", liquidity);

        tokenId = _tokenId;
    }

    function mintNewPosition(uint _amount0ToMint, uint _amount1ToMint)
        internal
        returns (
            uint _tokenId,
            uint128 liquidity,
            uint amount0,
            uint amount1
        )
    {
        // For this example, we will provide equal amounts of liquidity in both assets.
        // Providing liquidity in both assets means liquidity will be earning fees and is considered in-range.
        // uint amount0ToMint = 100 * 1e18;
        // uint amount1ToMint = 100 * 1e6;
         uint amount0ToMint = _amount0ToMint;
        uint amount1ToMint =_amount1ToMint;

        // Approve the position manager
        TransferHelper.safeApprove(
            DAI,
            address(nonfungiblePositionManager),
            amount0ToMint
        );
        TransferHelper.safeApprove(
            USDC,
            address(nonfungiblePositionManager),
            amount1ToMint
        );

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: DAI,
                token1: USDC,
                fee: poolFee,
                // By using TickMath.MIN_TICK and TickMath.MAX_TICK, 
                // we are providing liquidity across the whole range of the pool. 
                // Not recommended in production.
                tickLower: TickMath.MIN_TICK,
                tickUpper: TickMath.MAX_TICK,
                amount0Desired: amount0ToMint,
                amount1Desired: amount1ToMint,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            });

        // Note that the pool defined by DAI/USDC and fee tier 0.01% must 
        // already be created and initialized in order to mint
        (_tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager
            .mint(params);

        // Create a deposit
        _createDeposit(msg.sender, _tokenId);


        // Remove allowance and refund in both assets.
        if (amount0 < amount0ToMint) {
            TransferHelper.safeApprove(
                DAI,
                address(nonfungiblePositionManager),
                0
            );
            uint refund0 = amount0ToMint - amount0;
            TransferHelper.safeTransfer(DAI, msg.sender, refund0);
        }

        if (amount1 < amount1ToMint) {
            TransferHelper.safeApprove(
                USDC,
                address(nonfungiblePositionManager),
                0
            );
            uint refund1 = amount1ToMint - amount1;
            TransferHelper.safeTransfer(USDC, msg.sender, refund1);
        }
    }

    function collectAllFees() external returns (uint256 amount0, uint256 amount1) {
        // set amount0Max and amount1Max to uint256.max to collect all fees
        // alternatively can set recipient to msg.sender and avoid another transaction in `sendToOwner`
        INonfungiblePositionManager.CollectParams memory params =
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        (amount0, amount1) = nonfungiblePositionManager.collect(params);

        console.log("fee 0", amount0);
        console.log("fee 1", amount1);
    }

    


  
}
