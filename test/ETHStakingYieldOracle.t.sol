// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { ETHStakingYieldOracle } from "../src/ETHStakingYieldOracle.sol";

contract ETHStakingYieldOracleTest is Test {

    address owner         = makeAddr("owner");
    address bridge        = makeAddr("bridge");
    address randomAddress = makeAddr("randomAddress");

    ETHStakingYieldOracle oracle;

    event BridgeUpdated(address indexed bridge, bool authorized);
    event MaxAPRUpdated(uint256 maxAPR);
    event APRUpdated(uint256 apr);

    function setUp() public {
        oracle = new ETHStakingYieldOracle();
        oracle.transferOwnership(owner);
    }

    function test_constructor() public {
        assertEq(oracle.owner(), owner);
    }

    function test_setAuthorizedBridge_not_owner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(randomAddress);
        oracle.setAuthorizedBridge(bridge, true);
    }

    function test_setAuthorizedBridge() public {
        assertEq(oracle.bridges(bridge), false);

        vm.expectEmit();
        emit BridgeUpdated(bridge, true);
        vm.prank(owner);
        oracle.setAuthorizedBridge(bridge, true);

        assertEq(oracle.bridges(bridge), true);

        vm.expectEmit();
        emit BridgeUpdated(bridge, false);
        vm.prank(owner);
        oracle.setAuthorizedBridge(bridge, false);

        assertEq(oracle.bridges(bridge), false);
    }

    function test_setMaxAPR_not_owner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(randomAddress);
        oracle.setMaxAPR(1e27);
    }

    function test_setMaxAPR() public {
        assertEq(oracle.maxAPR(), 0);

        vm.expectEmit();
        emit MaxAPRUpdated(1e27);
        vm.prank(owner);
        oracle.setMaxAPR(1e27);

        assertEq(oracle.maxAPR(), 1e27);
    }

    function _initBridge() internal {
        vm.startPrank(owner);
        oracle.setMaxAPR(1e27);
        oracle.setAuthorizedBridge(bridge, true);
        vm.stopPrank();
    }

    function test_onReceiveData_not_bridge() public {
        _initBridge();

        vm.expectRevert("ETHStakingYieldOracle/not-authorized");
        vm.prank(randomAddress);
        oracle.onReceiveData(abi.encode(uint256(0.03e27)));
    }

    function test_onReceiveData_invalid_apr() public {
        _initBridge();

        vm.expectRevert("ETHStakingYieldOracle/invalid-apr");
        vm.prank(bridge);
        oracle.onReceiveData(abi.encode(uint256(1e27 + 1)));
    }

    function test_onReceiveData() public {
        _initBridge();

        assertEq(oracle.getAPR(), 0);

        vm.expectEmit();
        emit APRUpdated(0.03e27);
        vm.prank(bridge);
        oracle.onReceiveData(abi.encode(uint256(0.03e27)));

        assertEq(oracle.getAPR(), 0.03e27);
    }

}
