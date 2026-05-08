// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {GreenReceiptNFT} from "../src/GreenReceiptNFT.sol";

contract DeployGreenReceiptNFT is Script {
    function run() external returns (GreenReceiptNFT greenReceiptNFT) {
        vm.startBroadcast();
        greenReceiptNFT = new GreenReceiptNFT();
        vm.stopBroadcast();
    }
}
