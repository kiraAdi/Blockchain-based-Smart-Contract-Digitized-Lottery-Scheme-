pragma solidity ^0.4.24;

import "./math/SafeMath.sol";
import "./ownership/Ownable.sol";

contract QChainLottery is Ownable {
    using SafeMath for uint256;

    event WinnerEthTransfer(
        address indexed winner,
        uint256 value
    );

    event OwnerEthTransfer(
        address indexed owner,
        uint256 value
    );

    string public title;
    uint256 public price;
    uint256 public endTime;
    uint256 public winnersCount;
    uint256 public gainProcent;

    uint256 public totalRaised;
    uint256 public totalTickets;

    address[] public lotteryTickets;
    address[] public winners;

    uint256 private randNonce = 0;
    bool private isEnded = false;

    constructor(
        string _title, 
        uint256 _price, 
        uint256 _endTime, 
        uint256 _winnersCount,
        uint256 _gain
    ) 
        public
    {
        require(_endTime > now, "Incorrect period of lottery");
        require(_winnersCount >= 1 && _winnersCount <= 10, "Incorrect number of winners: required from 1 to 10");
        require(_gain <= 50, "Incorrect gain: required from 0 to 50");

        title = _title;
        price = _price;
        endTime = _endTime;
        winnersCount = _winnersCount;
        gainProcent = _gain;
    }

    // if the transaction can take part in lottery
    modifier canPlaceBet() {
        require(now <= endTime);
        _;
    }

    // if lottery bet period has ended
    modifier canWithdrawal() {
        require(!lotteryIsEnded() && betPeriodIsEnded());
        _;
    }

    // if lottery has ended
    modifier isFinished() {
        require(lotteryIsEnded());
        _;
    }

    // @return true if Lottery Bet Period has ended
    function betPeriodIsEnded() public view returns (bool) {
        return now > endTime;
    }

    // @return true if Lottery has ended
    function lotteryIsEnded() public view returns (bool) {
        return isEnded;
    }

    // place a bet
    function placeBet() canPlaceBet payable external {
        uint256 valueForReturn = msg.value.sub(price);
        require(valueForReturn >= 0, "not enough ethers");

        lotteryTickets.push(msg.sender);
        totalTickets = totalTickets.add(1);
        totalRaised = totalRaised.add(price);

        // return extra eth
        msg.sender.transfer(valueForReturn);
    }

    // finish lottery and withdrawal eth to owner and winner
    function finishLottery() canWithdrawal external returns(bool) {

        uint256 prizeValue = address(this).balance
            .mul(100 - gainProcent)
            .div(100)
            .div(winnersCount);

        // transfer prizes to winners
        for (uint64 i = 0; i < winnersCount; i++) {
            address winner = lotteryTickets[randMod(winnersCount)];
            winners.push(winner);
            winner.transfer(prizeValue);
            emit WinnerEthTransfer(winner, prizeValue);
        }

        // transfer gain to owner
        uint256 valueForOwner = address(this).balance;
        owner.transfer(valueForOwner);
        emit OwnerEthTransfer(owner, valueForOwner);

        // change state and return
        return isEnded = true;
    }

    function getWinners() isFinished external view returns(address[]) {
        return winners;
    }

    function randMod(uint _mod) internal returns(uint256) {
        randNonce++;
        return uint(keccak256(now, msg.sender, randNonce)) % _mod;
    }

}
