// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { PriceSourceMock } from "./mocks/PriceSourceMock.sol";

import { WSTETHExchangeRateOracle } from "../src/WSTETHExchangeRateOracle.sol";

contract STETHMock {

    uint256 exchangeRate;

    constructor(uint256 _exchangeRate) {
        exchangeRate = _exchangeRate;
    }

    function getPooledEthByShares(uint256 amount) external view returns (uint256) {
        return exchangeRate * amount / 1e18;
    }

    function setExchangeRate(uint256 _exchangeRate) external {
        exchangeRate = _exchangeRate;
    }

}

contract WSTETHExchangeRateOracleTest is Test {

    STETHMock       steth;
    PriceSourceMock ethSource;

    WSTETHExchangeRateOracle oracle;

    function setUp() public {
        steth     = new STETHMock(1.2e18);
        ethSource = new PriceSourceMock(2000e8, 8);
        oracle    = new WSTETHExchangeRateOracle(address(steth), address(ethSource));
    }

    function test_constructor() public {
        assertEq(address(oracle.steth()),     address(steth));
        assertEq(address(oracle.ethSource()), address(ethSource));
        assertEq(oracle.decimals(),           8);
    }

    function test_invalid_decimals() public {
        ethSource.setLatestAnswer(2000e18);
        ethSource.setDecimals(18);
        vm.expectRevert("WSTETHExchangeRateOracle/invalid-decimals");
        new WSTETHExchangeRateOracle(address(steth), address(ethSource));
    }

    function test_latestAnswer_zeroEthUsd() public {
        ethSource.setLatestAnswer(0);
        assertEq(oracle.latestAnswer(), 0);
    }

    function test_latestAnswer_negativeEthUsd() public {
        ethSource.setLatestAnswer(-1);
        assertEq(oracle.latestAnswer(), 0);
    }

    function test_latestAnswer_zeroExchangeRate() public {
        steth.setExchangeRate(0);
        assertEq(oracle.latestAnswer(), 0);
    }

    // Note: Exchange rate cannot overflow to negative because it multiplies by
    //       the _sharesAmount parameter and divides by total shares.

    function test_latestAnswer() public {
        // 1.2 * 2000 = 2400
        assertEq(oracle.latestAnswer(), 2400e8);

        // 1 * 2000 = 2000
        steth.setExchangeRate(1e18);
        assertEq(oracle.latestAnswer(), 2000e8);

        // 0.5 * 1200 = 600
        steth.setExchangeRate(0.5e18);
        ethSource.setLatestAnswer(1200e8);
        assertEq(oracle.latestAnswer(), 600e8);
    }

}
