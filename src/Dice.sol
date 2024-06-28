// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title A simple Dice_game Contract
 * @author Oke Abdulquadri
 * @notice This contract is for creating a simple dice game
 * @dev Implement Chainlink VRFv2
 * 
 */
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts@1.1.1/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts@1.1.1/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract DiceGame {

    error DiceGame__NotEnoughEthSent(uint256 leastAmount);
    error DiceGame__NoStakeRecorded();
    error DiceGame__TransferFailed();

    enum StakeStatus {
        YES,
        NO
    }

    uint256 private immutable i_leastAmount;
    StakeStatus private s_stakeStatus;
    mapping (address => uint256) private s_players;

    event CurrentPlayer(address indexed player, uint256 amoutStaked);

    constructor(uint256 _leastAmount) {
        i_leastAmount = _leastAmount;
    }
    function stakeBet() external payable {
        if(msg.value < i_leastAmount) {
            revert DiceGame__NotEnoughEthSent(i_leastAmount);
        }
        s_players[msg.sender] += msg.value;
        s_stakeStatus = StakeStatus.YES;

        emit CurrentPlayer(msg.sender, msg.value);
    }
    
    function unstakeBet() external payable {
        if (s_stakeStatus != StakeStatus.YES) {
            revert DiceGame__NoStakeRecorded();
        }
        uint256 amount = s_players[msg.sender];
        s_stakeStatus = StakeStatus.NO;
        s_players[msg.sender] = 0;
        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) {
            revert DiceGame__TransferFailed();
        }
    }
    function playDice() external {
        if (s_stakeStatus != StakeStatus.YES) {
            revert DiceGame__NoStakeRecorded();
        }

    }
    function winnerWithdrawal() external {}
    function OwnerWithdrawal() external {}
}