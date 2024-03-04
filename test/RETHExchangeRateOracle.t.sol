// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { PriceSourceMock } from "./mocks/PriceSourceMock.sol";

import { RETHExchangeRateOracle } from "../src/RETHExchangeRateOracle.sol";

contract RETHMock {

    uint256 exchangeRate;

    constructor(uint256 _exchangeRate) {
        exchangeRate = _exchangeRate;
    }

    function getExchangeRate() external view returns (uint256) {
        return exchangeRate;
    }

    function setExchangeRate(uint256 _exchangeRate) external {
        exchangeRate = _exchangeRate;
    }

}

contract RETHExchangeRateOracleTest is Test {

    RETHMock        reth;
    PriceSourceMock ethSource;

    RETHExchangeRateOracle oracle;

    function setUp() public {
        reth      = new RETHMock(1.2e18);
        ethSource = new PriceSourceMock(2000e8, 8);
        oracle    = new RETHExchangeRateOracle(address(reth), address(ethSource));
    }

    function test_constructor() public {
        assertEq(address(oracle.reth()),      address(reth));
        assertEq(address(oracle.ethSource()), address(ethSource));
        assertEq(oracle.decimals(),           8);
    }

    function test_invalid_decimals() public {
        ethSource.setLatestAnswer(2000e18);
        ethSource.setDecimals(18);
        vm.expectRevert("RETHExchangeRateOracle/invalid-decimals");
        new RETHExchangeRateOracle(address(reth), address(ethSource));
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
        reth.setExchangeRate(0);
        assertEq(oracle.latestAnswer(), 0);
    }

    function test_latestAnswer_negativeExchangeRate() public {
        // RETH ER can't go negative, but it can have a silent overflow
        assertLt(int256(uint256(int256(-1))), 0);
        reth.setExchangeRate(uint256(int256(-1)));
        assertEq(oracle.latestAnswer(), 0);
    }

    function test_latestAnswer() public {
        // 1.2 * 2000 = 2400
        assertEq(oracle.latestAnswer(), 2400e8);

        // 1 * 2000 = 2000
        reth.setExchangeRate(1e18);
        assertEq(oracle.latestAnswer(), 2000e8);

        // 0.5 * 1200 = 600
        reth.setExchangeRate(0.5e18);
        ethSource.setLatestAnswer(1200e8);
        assertEq(oracle.latestAnswer(), 600e8);
    }

}
