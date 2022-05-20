// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@forge-std/Test.sol";
import "@forge-std/Vm.sol";
import "@forge-std/console.sol";
import "../src/FuseAttack.sol";

contract FuseAttackPoC is Test {
    FuseAttacker fuseAttacker = new FuseAttacker();
    // EOA address
    address constant myAddress = address(1337);

    function setUp() public {
        vm.deal(myAddress, 5 ether);
    }

    function testFuseBasic() public {
        fuseAttacker.printUniswapTwapPrice(600);
        console.log(block.number);
        vm.roll(13537923);
        fuseAttacker.printUniswapTwapPrice(600);
        console.log(block.number);
        vm.roll(13537924);
        fuseAttacker.printUniswapTwapPrice(600);
        console.log(block.number);
        assert(true);
    }
}