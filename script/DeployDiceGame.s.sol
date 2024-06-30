//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {DiceGame} from "../src/Dice.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployDiceGame is Script {
    function run() public {
        deployContract();
    }

    function deployContract() public returns (DiceGame, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast();
        DiceGame diceGame = new DiceGame(
            config.leastAmount,
            config.vrfCoordinator,
            config.keyHash,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        return (diceGame, helperConfig);
    }
}
