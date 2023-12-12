// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { PotRateSource } from "../src/PotRateSource.sol";

contract PotMock {

    uint256 public dsr;

    constructor(uint256 _dsr) {
        dsr = _dsr;
    }

    function setDSR(uint256 _dsr) external {
        dsr = _dsr;
    }

}

contract PotRateSourceTest is Test {

    // To calculate: bc -l <<< 'scale=27; e( l(1.05)/(60 * 60 * 24 * 365) )'
    uint256 constant FIVE_PCT_APY_DSR = 1.000000001547125957863212448e27;
    uint256 constant FIVE_PCT_APY_APR = 0.048790164207174267760128000e27;

    PotMock pot;

    PotRateSource rateSource;

    function setUp() public {
        pot = new PotMock(FIVE_PCT_APY_DSR);

        rateSource = new PotRateSource(address(pot));
    }

    function test_constructor() public {
        assertEq(address(rateSource.pot()), address(pot));
    }

    function test_bad_dsr_value() public {
        pot.setDSR(1e27 - 1);

        vm.expectRevert(stdError.arithmeticError);
        rateSource.getAPR();
    }

    function test_getAPR() public {
        assertEq(rateSource.getAPR(), FIVE_PCT_APY_APR);

        pot.setDSR(1e27);

        assertEq(rateSource.getAPR(), 0);
    }

}
