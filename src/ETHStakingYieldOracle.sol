// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { Ownable } from 'aave-v3-core/contracts/dependencies/openzeppelin/contracts/Ownable.sol';

contract ETHStakingYieldOracle is Ownable {

    event BridgeUpdated(address indexed bridge, bool authorized);
    event MaxAPRUpdated(uint256 maxAPR);
    event APRUpdated(uint256 apr);

    mapping (address => bool) public bridges;

    uint256 public maxAPR;

    uint256 internal _apr;

    constructor() Ownable() {}

    function setAuthorizedBridge(address bridge, bool authorized) external onlyOwner {
        bridges[bridge] = authorized;

        emit BridgeUpdated(bridge, authorized);
    }

    function setMaxAPR(uint256 _maxAPR) external onlyOwner {
        maxAPR = _maxAPR;

        emit MaxAPRUpdated(_maxAPR);
    }

    function onReceiveData(bytes calldata data) external {
        require(bridges[msg.sender], "ETHStakingYieldOracle/not-authorized");
        uint256 apr = abi.decode(data, (uint256));
        require(apr <= maxAPR, "ETHStakingYieldOracle/invalid-apr");

        _apr = apr;

        emit APRUpdated(apr);
    }

    function getAPR() external view returns (uint256) {
        return _apr;
    }

}