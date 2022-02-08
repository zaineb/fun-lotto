//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract FunLotto is VRFConsumerBase, Ownable {
    enum LOTTERY_STATE {
        OPEN,
        CALCULATING_WINNER,
        CLOSED
    }

    //local state
    address payable[] public players;
    address payable public recentWinner;
    LOTTERY_STATE public currentState;
    uint256 public randomNumber;

    //configurations
    uint256 lotteryFee;
    AggregatorV3Interface internal priceFeed;
    uint256 public fee;
    bytes32 public keyhash;
    uint256 public lotteryId;

    //events
    event LotteryOpened(uint256 lotteryId);
    event LotteryClosed();
    event WinnerDeclared(address winner, uint256 randomness);

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        currentState = LOTTERY_STATE.CLOSED;
        lotteryFee = 50 * 10**18;
        lotteryId = 0;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        fee = _fee;
        keyhash = _keyhash;
    }

    function OpenLottery() public onlyOwner {
        require(currentState == LOTTERY_STATE.CLOSED);
        currentState = LOTTERY_STATE.OPEN;
        lotteryId = lotteryId + 1;
        emit LotteryOpened(lotteryId);
    }

    function enterLottery() public payable {
        require(msg.value >= 0, "Not enough fund");
        require(currentState == LOTTERY_STATE.OPEN);
        players.push(payable(msg.sender));
    }

    function getLotteryFee() public view returns (uint256) {
        //covert $50 to eth
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 _fee = (lotteryFee * 10**18) / (uint256(price) * 10**18);
        return _fee;
    }

    function closeLottery() public onlyOwner {
        require(currentState == LOTTERY_STATE.OPEN);
        currentState = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit LotteryClosed();
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            currentState == LOTTERY_STATE.CALCULATING_WINNER,
            "You aren't there yet!"
        );
        require(_randomness > 0, "random-not-found");
        randomNumber = _randomness;
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);
        // Reset
        players = new address payable[](0);
        currentState = LOTTERY_STATE.CLOSED;
        emit WinnerDeclared(recentWinner, _randomness);
    }
}
