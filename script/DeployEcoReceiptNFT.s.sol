// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {EcoReceiptNFT} from "../src/EcoReceiptNFT.sol";

contract DeployEcoReceiptNFT is Script {
    function run() external returns (EcoReceiptNFT ecoReceiptNFT) {
        vm.startBroadcast();
        ecoReceiptNFT = new EcoReceiptNFT();
        vm.stopBroadcast();
    }
}
