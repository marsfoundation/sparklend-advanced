// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { PriceSourceMock } from "./mocks/PriceSourceMock.sol";

import { MorphoUpgradableOracle } from "../src/MorphoUpgradableOracle.sol";

contract MorphoUpgradableOracleTest is Test {

    event SourceChanged(address indexed oldSource, address indexed newSource);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address owner = makeAddr("owner");

    PriceSourceMock priceSource1;
    PriceSourceMock priceSource2;

    MorphoUpgradableOracle oracle;

    function setUp() public {
        priceSource1 = new PriceSourceMock(123e8,  8);
        priceSource2 = new PriceSourceMock(456e18, 18);

        oracle = new MorphoUpgradableOracle(owner, address(priceSource1));
    }

    function test_constructor() public {
        vm.expectEmit();
        emit OwnershipTransferred(address(0), owner);
        vm.expectEmit();
        emit SourceChanged(address(0), address(priceSource1));
        oracle = new MorphoUpgradableOracle(owner, address(priceSource1));

        assertEq(address(oracle.owner()),  owner);
        assertEq(address(oracle.source()), address(priceSource1));
    }

    function test_setSource_notOwner() public {
        vm.expectRevert(abi.encodeWithSignature('OwnableUnauthorizedAccount(address)', address(this)));
        oracle.setSource(address(priceSource2));
    }

    function test_setSource() public {
        assertEq(address(oracle.source()), address(priceSource1));
        assertEq(oracle.decimals(),        8);
        assertEq(oracle.decimals(),        priceSource1.decimals());
        (, int256 answer,,,) = oracle.latestRoundData();
        assertEq(answer,                   123e8);

        vm.expectEmit(address(oracle));
        emit SourceChanged(address(priceSource1), address(priceSource2));
        vm.prank(owner);
        oracle.setSource(address(priceSource2));

        assertEq(address(oracle.source()), address(priceSource2));
        assertEq(oracle.decimals(),        18);
        assertEq(oracle.decimals(),        priceSource2.decimals());
        (, answer,,,) = oracle.latestRoundData();
        assertEq(answer,                   456e18);
    }

}
