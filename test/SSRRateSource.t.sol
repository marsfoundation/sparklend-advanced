// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { SSRRateSource } from "../src/SSRRateSource.sol";

contract SUSDSMock {

    uint256 public ssr;

    constructor(uint256 _ssr) {
        ssr = _ssr;
    }

    function setSSR(uint256 _ssr) external {
        ssr = _ssr;
    }

}

contract SSRRateSourceTest is Test {

    // To calculate: bc -l <<< 'scale=27; e( l(1.05)/(60 * 60 * 24 * 365) )'
    uint256 constant FIVE_PCT_APY_SSR = 1.000000001547125957863212448e27;
    uint256 constant FIVE_PCT_APY_APR = 0.048790164207174267760128000e27;

    SUSDSMock susds;

    SSRRateSource rateSource;

    function setUp() public {
        susds = new SUSDSMock(FIVE_PCT_APY_SSR);

        rateSource = new SSRRateSource(address(susds));
    }

    function test_constructor() public {
        assertEq(address(rateSource.susds()), address(susds));
        assertEq(rateSource.decimals(),       27);
    }

    function test_bad_ssr_value() public {
        susds.setSSR(1e27 - 1);

        vm.expectRevert(stdError.arithmeticError);
        rateSource.getAPR();
    }

    function test_getAPR() public {
        assertEq(rateSource.getAPR(), FIVE_PCT_APY_APR);

        susds.setSSR(1e27);

        assertEq(rateSource.getAPR(), 0);
    }

}
