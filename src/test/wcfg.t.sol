/// wcfg.t.sol

// Copyright (C) 2015-2019  DappHub, LLC,
// Copyright (C) 2019 lucasvo

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.5.12;

import "ds-test/test.sol";

import "../wcfg.sol";

contract WCFGUser {
    WCFG  wcfg;

    constructor(WCFG wcfg_) public {
        wcfg = wcfg_;
    }

    function doTransferFrom(address from, address to, uint amount)
        public
        returns (bool)
    {
        return wcfg.transferFrom(from, to, amount);
    }

    function doTransfer(address to, uint amount)
        public
        returns (bool)
    {
        return wcfg.transfer(to, amount);
    }

    function doApprove(address recipient, uint amount)
        public
        returns (bool)
    {
        return wcfg.approve(recipient, amount);
    }

    function doAllowance(address owner, address spender)
        public
        view
        returns (uint)
    {
        return wcfg.allowance(owner, spender);
    }

    function doBalanceOf(address who) public view returns (uint) {
        return wcfg.balanceOf(who);
    }

    function doApprove(address usr)
        public
        returns (bool)
    {
        return wcfg.approve(usr, uint(-1));
    }
    function doMint(uint wad) public {
        wcfg.mint(address(this), wad);
    }
    function doBurn(uint wad) public {
        wcfg.burn(address(this), wad);
    }
    function doMint(address usr, uint wad) public {
        wcfg.mint(usr, wad);
    }
    function doBurn(address usr, uint wad) public {
        wcfg.burn(usr, wad);
    }

}

contract Hevm {
    function warp(uint256) public;
}

contract wcfgTest is DSTest {
    uint constant initialBalanceThis = 1000;
    uint constant initialBalanceCal = 100;

    Hevm hevm;
    WCFG wcfg;
    address user1;
    address user2;
    address self;


    uint amount = 2;
    uint fee = 1;
    uint nonce = 0;
    uint deadline = 0;
    address cal = 0x78Df63f83d8CFfaeB2f5522102113a4Cb44bD857;
    address del = 0xc351B89C286288B9201835f78dbbccaDA357671e;
    bytes32 r = 0x33e75ec358ed0bb00057fbc7fa96a83abe26acbd0fbe93d05e652f17a5424df4;
    bytes32 s = 0x0b708d5abfb8efbe26b3a6a217faa7a5ff146641a9a66686f1a8603ee0bfd08a;
    uint8 v = 28;
    bytes32 _r = 0xf2d069ada54f7a6d2e162611b772749e827378352de614e687e11152dad0c373;
    bytes32 _s = 0x1b3582502f3b5d4a9aed712a148d14f71be757336189c4fc722d2473fd4aad9f;
    uint8 _v = 28;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);
        wcfg = createwcfg();
        wcfg.mint(address(this), initialBalanceThis);
        wcfg.mint(cal, initialBalanceCal);
        user1 = address(new WCFGUser(wcfg));
        user2 = address(new WCFGUser(wcfg));
        self = address(this);
    }

    function createwcfg() internal returns (WCFG) {
        return new WCFG(1);
    }

    function testSetupPrecondition() public {
        assertEq(wcfg.balanceOf(self), initialBalanceThis);
    }

    function testTransferCost() public logs_gas {
        wcfg.transfer(address(0), 10);
    }

    function testAllowanceStartsAtZero() public logs_gas {
        assertEq(wcfg.allowance(user1, user2), 0);
    }

    function testValidTransfers() public logs_gas {
        uint sentAmount = 250;
        emit log_named_address("wcfg11111", address(wcfg));
        wcfg.transfer(user2, sentAmount);
        assertEq(wcfg.balanceOf(user2), sentAmount);
        assertEq(wcfg.balanceOf(self), initialBalanceThis - sentAmount);
    }

    function testFailWrongAccountTransfers() public logs_gas {
        uint sentAmount = 250;
        wcfg.transferFrom(user2, self, sentAmount);
    }

    function testFailInsufficientFundsTransfers() public logs_gas {
        uint sentAmount = 250;
        wcfg.transfer(user1, initialBalanceThis - sentAmount);
        wcfg.transfer(user2, sentAmount + 1);
    }

    function testApproveSetsAllowance() public logs_gas {
        emit log_named_address("Test", self);
        emit log_named_address("wcfg", address(wcfg));
        emit log_named_address("Me", self);
        emit log_named_address("User 2", user2);
        wcfg.approve(user2, 25);
        assertEq(wcfg.allowance(self, user2), 25);
    }

    function testChargesAmountApproved() public logs_gas {
        uint amountApproved = 20;
        wcfg.approve(user2, amountApproved);
        assertTrue(WCFGUser(user2).doTransferFrom(self, user2, amountApproved));
        assertEq(wcfg.balanceOf(self), initialBalanceThis - amountApproved);
    }

    function testFailTransferWithoutApproval() public logs_gas {
        wcfg.transfer(user1, 50);
        wcfg.transferFrom(user1, self, 1);
    }

    function testFailChargeMoreThanApproved() public logs_gas {
        wcfg.transfer(user1, 50);
        WCFGUser(user1).doApprove(self, 20);
        wcfg.transferFrom(user1, self, 21);
    }
    function testTransferFromSelf() public {
        wcfg.transferFrom(self, user1, 50);
        assertEq(wcfg.balanceOf(user1), 50);
    }
    function testFailTransferFromSelfNonArbitrarySize() public {
        // you shouldn't be able to evade balance checks by transferring
        // to yourself
        wcfg.transferFrom(self, self, wcfg.balanceOf(self) + 1);
    }
    function testMintself() public {
        uint mintAmount = 10;
        wcfg.mint(address(this), mintAmount);
        assertEq(wcfg.balanceOf(self), initialBalanceThis + mintAmount);
    }
    function testMintUser() public {
        uint mintAmount = 10;
        wcfg.mint(user1, mintAmount);
        assertEq(wcfg.balanceOf(user1), mintAmount);
    }
    function testFailMintUserNoAuth() public {
        WCFGUser(user1).doMint(user2, 10);
    }
    function testMintUserAuth() public {
        wcfg.rely(user1);
        WCFGUser(user1).doMint(user2, 10);
    }

    function testBurn() public {
        uint burnAmount = 10;
        wcfg.burn(address(this), burnAmount);
        assertEq(wcfg.totalSupply(), initialBalanceThis + initialBalanceCal - burnAmount);
    }
    function testBurnself() public {
        uint burnAmount = 10;
        wcfg.burn(address(this), burnAmount);
        assertEq(wcfg.balanceOf(self), initialBalanceThis - burnAmount);
    }
    function testBurnUserWithTrust() public {
        uint burnAmount = 10;
        wcfg.transfer(user1, burnAmount);
        assertEq(wcfg.balanceOf(user1), burnAmount);

        WCFGUser(user1).doApprove(self);
        wcfg.burn(user1, burnAmount);
        assertEq(wcfg.balanceOf(user1), 0);
    }
    function testBurnAuth() public {
        wcfg.transfer(user1, 10);
        wcfg.rely(user1);
        WCFGUser(user1).doBurn(10);
    }
    function testBurnUserAuth() public {
        wcfg.transfer(user2, 10);
        WCFGUser(user2).doApprove(user1);
        WCFGUser(user1).doBurn(user2, 10);
    }

    function testFailUntrustedTransferFrom() public {
        assertEq(wcfg.allowance(self, user2), 0);
        WCFGUser(user1).doTransferFrom(self, user2, 200);
    }
    function testTrusting() public {
        assertEq(wcfg.allowance(self, user2), 0);
        wcfg.approve(user2, uint(-1));
        assertEq(wcfg.allowance(self, user2), uint(-1));
        wcfg.approve(user2, 0);
        assertEq(wcfg.allowance(self, user2), 0);
    }
    function testTrustedTransferFrom() public {
        wcfg.approve(user1, uint(-1));
        WCFGUser(user1).doTransferFrom(self, user2, 200);
        assertEq(wcfg.balanceOf(user2), 200);
    }
    function testApproveWillModifyAllowance() public {
        assertEq(wcfg.allowance(self, user1), 0);
        assertEq(wcfg.balanceOf(user1), 0);
        wcfg.approve(user1, 1000);
        assertEq(wcfg.allowance(self, user1), 1000);
        WCFGUser(user1).doTransferFrom(self, user1, 500);
        assertEq(wcfg.balanceOf(user1), 500);
        assertEq(wcfg.allowance(self, user1), 500);
    }
    function testApproveWillNotModifyAllowance() public {
        assertEq(wcfg.allowance(self, user1), 0);
        assertEq(wcfg.balanceOf(user1), 0);
        wcfg.approve(user1, uint(-1));
        assertEq(wcfg.allowance(self, user1), uint(-1));
        WCFGUser(user1).doTransferFrom(self, user1, 1000);
        assertEq(wcfg.balanceOf(user1), 1000);
        assertEq(wcfg.allowance(self, user1), uint(-1));
    }

    function testwcfgAddress() public {
        assertEq(address(wcfg), address(0xE58d97b6622134C0436d60daeE7FBB8b965D9713));
    }

    function testTypehash() public {
        assertEq(wcfg.PERMIT_TYPEHASH(), 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9);
    }

    function testDomain_Separator() public {
        assertEq(wcfg.DOMAIN_SEPARATOR(), 0xd8c4cf6fb0cafceb796a57d02d0da83b5de9e840e36fe3e6558c8b9934eb62fc);
    }

    function testPermit() public {
        assertEq(wcfg.nonces(cal), 0);
        assertEq(wcfg.allowance(cal, del), 0);
        wcfg.permit(cal, del, 10000, uint(-1), v, r, s);
        assertEq(wcfg.allowance(cal, del), 10000);
        assertEq(wcfg.nonces(cal), 1);
    }

    function testFailPermitAddress0() public {
        _v = 0;
        wcfg.permit(address(0), del, 0, 0, v, r, s);
    }

    function testPermitWithExpiry() public {
        assertEq(wcfg.nonces(cal), 0);
        assertEq(wcfg.allowance(cal, del), 0);
        assertEq(now, 604411200);
        wcfg.permit(cal, del, 10000, 604411200 + 1 hours, _v, _r, _s);
        assertEq(wcfg.allowance(cal, del), 10000);
        assertEq(wcfg.nonces(cal), 1);
    }

    function testFailPermitWithExpiry() public {
        hevm.warp(now + 2 hours);
        assertEq(now, 604411200 + 2 hours);
        wcfg.permit(cal, del, 0, 1, _v, _r, _s);
    }

    function testFailReplay() public {
        wcfg.permit(cal, del, 0, uint(-1), v, r, s);
        wcfg.permit(cal, del, 0, uint(-1), v, r, s);
    }

}
