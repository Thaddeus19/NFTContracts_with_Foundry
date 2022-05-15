// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.4;

import "../NFTToken.sol";
import {Vm} from "@std/Vm.sol";
import "@std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTTest is IERC721Receiver, Test {
    using stdStorage for StdStorage;
    NFTToken NFTtoken;

    function setUp() public {
        NFTtoken = new NFTToken("https://gateway.pinata.cloud/ipfs/QmZ8ncNkicBLb8Mz7yuK442b3YaPkMzuUarBYsSgDLNHny/");
    }

    function testFailMintNoPaid() public {
        NFTtoken.mint();
        vm.expectRevert("wrongpayment()");
    }

    function testCorrectMintPrice() public {
        NFTtoken.mint{value: 1 ether}();
    }

    function testMintAndSuppply() public {
        NFTtoken.mint{value: 1 ether}();
        NFTtoken.mint{value: 1 ether}();
        uint256 supply = NFTtoken.totalSupply();
        assertEq(supply, 2);
    }
    function testBalanceOwner() public {
        address alice = address(3);
        hoax(alice, 2 ether);
        NFTtoken.mint{value: 1 ether}();
        uint256 slotOfNewOwner = stdstore.target(address(NFTtoken)).sig(NFTtoken.ownerOf.selector).with_key(1).find();

        uint160 ownerOfTokenOne = uint160(uint256((vm.load(address(NFTtoken),bytes32(abi.encode(slotOfNewOwner))))));
        assertEq(address(ownerOfTokenOne), alice);
    }

    function testFailMaxSupplyReached() public {
        uint256 slot = stdstore.target(address(NFTtoken)).sig("_nextTokenId()").find();
        bytes32 loc = bytes32(slot);
        bytes32 mockedCurrentTokenId = bytes32(abi.encode(1000));
        vm.store(address(NFTtoken), loc, mockedCurrentTokenId);
        address alice = vm.addr(1);
        vm.prank(alice);
        uint256 supply = NFTtoken.maxSupply();
        emit log_uint(supply);
        NFTtoken.mint{value: 1 ether}();
        vm.expectRevert("maxsupplyexceeded()");
    }

    function testFailMintToZeroAddress() public {
        address zero = address(0);
        hoax(zero, 2 ether);
        NFTtoken.mint{value: 1 ether}();
        vm.expectRevert("ERC721: mint to the zero address");
    }

    function testBalanceIncremented() public { 
        address alice = vm.addr(3);
        startHoax(alice, 2 ether);
        NFTtoken.mint{value: 1 ether}();
        uint256 slot_1 = stdstore.target(address(NFTtoken)).sig(NFTtoken.balanceOf.selector).with_key(alice).find();
        uint256 firstBalance = uint256(vm.load(address(NFTtoken), bytes32(slot_1)));
        assertEq(firstBalance, 1);
        NFTtoken.mint{value: 1 ether}();
        uint256 slot_2 = stdstore.target(address(NFTtoken)).sig(NFTtoken.balanceOf.selector).with_key(alice).find();
        uint256 secondBalance = uint256(vm.load(address(NFTtoken), bytes32(slot_2)));
        assertEq(secondBalance, 2);
    }

    function testFailUnSafeContractReceiver() public {
        vm.etch(address(1), bytes("mock code"));
        vm.prank(address(1));
        NFTtoken.mint{value: 1 ether}();
    }

    function testWithdraw() public {
        uint256 balance_before = address(this).balance;
        NFTtoken.mint{value:1 ether}();
        uint value = NFTtoken.cost();
        uint256 contract_balance = address(NFTtoken).balance;
        assertEq(contract_balance, value); 
        NFTtoken.withdraw();
        uint256 balance_after = address(this).balance;
        assertEq(balance_before, balance_after);
    }

    function testFailWithdraw() public {
        NFTtoken.mint{value: 1 ether}();
        uint256 value = NFTtoken.cost();
        uint256 contract_balance = address(NFTtoken).balance;
        assertEq(contract_balance, value);
        address alice = vm.addr(4);
        hoax(alice, 1 ether);
        NFTtoken.withdraw();
        vm.expectRevert("havenoadminrole()");
    }

    function testHiddenUri() public {
        string memory metadata = NFTtoken.hideUri();
        address bob = vm.addr(10);
        startHoax(bob, 2 ether);
        NFTtoken.mint{value: 1 ether}();
        string memory uri = NFTtoken.tokenURI(1);
        assertEq(uri, metadata);
    }

    function testreveal() public {
        address bob = vm.addr(8);
        hoax(bob, 2 ether);
        NFTtoken.mint{value: 1 ether}();
        NFTtoken.setreveal();  
        string memory meta = "https://gateway.pinata.cloud/ipfs/QmZ8ncNkicBLb8Mz7yuK442b3YaPkMzuUarBYsSgDLNHny/1.json";
        string memory uri = NFTtoken.tokenURI(1);  
        assertEq(uri, meta);   
   }

   function testFailWithPausedContract() public {
       NFTtoken.setPaused(true);
       address bob = vm.addr(6);
       startHoax(bob, 2 ether);
       NFTtoken.mint{value: 1 ether}();
       vm.expectRevert("thecontractispaused()");
   }
    function testremovecontractpause() public {
       NFTtoken.setPaused(true);
       address bob = vm.addr(6);
       hoax(bob, 2 ether);
       bool status = NFTtoken.paused();
       assertEq(status, true);
       NFTtoken.setPaused(false);
       vm.prank(bob);
       NFTtoken.mint{value: 1 ether}();
       uint256 supply = NFTtoken.totalSupply();
       assertEq(supply, 1);
   }

   function testFailMetadataQuery() public {
       address bob = vm.addr(6);
       startHoax(bob, 2 ether);
       NFTtoken.tokenURI(1);
       vm.expectRevert("nonexistenttoken()");
   }
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    receive() external payable {}
}
