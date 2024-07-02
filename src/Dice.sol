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
pragma solidity ^0.8.19;

/**
 * @title A simple Dice_game Contract
 * @author Oke Abdulquadri
 * @notice This contract is for creating a simple dice game
 * @dev Implement Chainlink VRFv2
 * 
 */
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract DiceGame is VRFConsumerBaseV2Plus{

    error DiceGame__NotEnoughEthSent(uint256 leastAmount);
    error DiceGame__NoStakeRecorded();
    error DiceGame__TransferFailed();

    enum StakeStatus {
        NO,
        YES
    }

    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUMWORDS =  1; 

    uint256 private immutable i_leastAmount; 
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint256 private  s_predictedNum;
    StakeStatus private s_stakeStatus;
    address private s_recentPlayer;
    mapping (address => uint256) private s_players; //players address to their balance
    mapping (address => uint256) private s_results;

    event CurrentPlayer(address indexed player, uint256 amoutStaked);

    constructor(
        uint256 _leastAmount,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit

    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_leastAmount = _leastAmount;
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_keyHash = _keyHash;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
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
    function playDice(uint16 _predictedNum) external returns (uint256 requestId) {
        if (s_stakeStatus != StakeStatus.YES) {
            revert DiceGame__NoStakeRecorded();
        }
        s_stakeStatus = StakeStatus.NO;
        s_recentPlayer = msg.sender;
        s_predictedNum = _predictedNum;
        requestId = i_vrfCoordinator.requestRandomWords({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                minimumRequestConfirmations: REQUEST_CONFIRMATION,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUMWORDS
        });

    }

    function fulfillRandomWords(uint256 /*requestId*/, uint256[] calldata randomWords) internal override {
        uint256 d6Value = (randomWords[0] % 6) + 1;
        
        if (s_predictedNum == d6Value) {
            uint256 amountWon = s_players[s_recentPlayer];
            (bool success,) = s_recentPlayer.call{value: amountWon * 2}("");
            if(!success) {
                revert DiceGame__TransferFailed();
            }
        } 
    }

    function getPlayerBalance(address _player) external view returns (uint256) {
        return s_players[_player];
    }
}