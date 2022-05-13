// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../NFTToken.sol";
import {DSTest} from "@ds/test.sol";
import {Vm} from "@std/Vm.sol";

contract NFTTest is DSTest {
    
    NFTToken public NFTtoken;
    Vm public constant vm = Vm(HEVM_ADDRESS);

    uint96 constant FUND_AMOUNT = 1 * 10**18;

    // Initialized as blank, fine for testing
    uint64 subId;
    bytes32 keyHash; // gasLane

    event ReturnedRandomness(uint256[] randomWords);

    function setUp() public {}

    function test() public {
       assertTrue(true);
    }
}
