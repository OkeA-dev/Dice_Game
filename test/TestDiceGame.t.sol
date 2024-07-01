//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DiceGame} from "../src/Dice.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {DeployDiceGame} from "../script/DeployDiceGame.s.sol";

contract TestDiceGame is Test {
    address  PLAYER = makeAddr("Iconart");
    uint256 constant STARTING_BALANCE = 10 ether;

    DiceGame public diceGame;
    HelperConfig public helperConfig;

    uint256 leastAmount;
    address vrfCoordinator;
    bytes32 keyHash;
    uint64 subscriptionId;
    uint32 callbackGasLimit;

    event CurrentPlayer(address indexed player, uint256 amoutStaked);

    function setUp() public {
        /* Initialise a deploy dice_game instance
            * Deployer the dice_game and store the value in approriate storage
        */
        
        DeployDiceGame deployer = new DeployDiceGame();
        (diceGame, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        leastAmount = config.leastAmount;
        vrfCoordinator = config.vrfCoordinator;
        keyHash = config.keyHash;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;

        vm.deal(PLAYER, STARTING_BALANCE);
    }

    function testDiceGameDontRecieveEnoughEth() public {
        vm.prank(PLAYER);
        vm.expectRevert(
            abi.encodeWithSelector(
                DiceGame.DiceGame__NotEnoughEthSent.selector,
                leastAmount
            )
        );
        diceGame.stakeBet();
    }

    function testDiceGameRecordedPlayerStake() public {
        vm.prank(PLAYER);
        diceGame.stakeBet{value: leastAmount}();
        assertEq(diceGame.getPlayerBalance(PLAYER), leastAmount);
    }

    function testDiceGameEventEmit() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, true, false, false, address(diceGame));
        emit CurrentPlayer(PLAYER, leastAmount);

        diceGame.stakeBet{value: leastAmount}();
        console.log(leastAmount);
        console.log(diceGame.getPlayerBalance(PLAYER));
    }
    
}