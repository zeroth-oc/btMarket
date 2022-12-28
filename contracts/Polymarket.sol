// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract BetMarket {
    address public owner;
    uint256 public totalMarkets = 0;

    //constants 
    uint tax = 100000000000000; // tax 0.0001 eth 

    //constants
    uint internal minimumBet = 100000000000000000; // min 0.1 eth
    
    constructor() {
        owner = msg.sender;
    }
    mapping(uint256 => Markets) public markets;


    struct Markets {
        uint256 id;
        string  market;
        uint256 timestamp;
        uint256 endTimestamp;
        address createdBy;
        string creatorImageHash;
        AmountAdded[] yesCount;
        AmountAdded[] noCount;
        uint256 totalAmount;
        uint256 totalYesAmount;
        uint256 totalNoAmount;
        bool eventCompleted;
        string description;
        string resolverUrl;
    }

    struct AmountAdded {
        address user;
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => uint256) public winningAmount;
    address[] public winningAddresses;
    
    event MarketCreated(
        uint256 id,
        string market,
        uint256 timestamp,
        address createdBy,
        string creatorImageHash,
        uint256 totalAmount,
        uint256 totalYesAmount,
        uint256 totalNoAmount
    );

    
    receive() external payable{}



    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    
    function createMarket(
        string memory _market,
        string memory _creatorImageHash,
        string memory _description,
        string memory _resolverUrl,
        uint256 _endTimestamp
    ) public {
        require(msg.sender == owner, "Unauthorized");
        uint256 timestamp = block.timestamp;

        Markets storage market = markets[totalMarkets];
        market.id = totalMarkets++;
        market.market = _market;
        market.timestamp = timestamp;
        market.createdBy = msg.sender;
        market.creatorImageHash = _creatorImageHash;
        market.totalAmount = 0;
        market.totalYesAmount = 0;
        market.totalNoAmount = 0;
        market.description = _description;
        market.resolverUrl = _resolverUrl;
        market.endTimestamp = _endTimestamp;


        emit MarketCreated(
            totalMarkets,
            _market,
            timestamp,
            msg.sender,
            _creatorImageHash,
            0,
            0,
            0
        );
    }
    
    function addYesBet(uint256 _marketId) public payable {
        require(msg.value != 0, "you cant stake 0 wei");
        //bet must be above a certain minimum 
        require(msg.value >= minimumBet);
        Markets storage market = markets[_marketId];
        (bool sent, ) = address(this).call{value: msg.value}("");
        require(sent, "failed to send");

        AmountAdded memory amountAdded = AmountAdded(
            msg.sender,
            msg.value,
            block.timestamp
        );

        market.totalYesAmount += msg.value;
        market.totalAmount += msg.value;
        market.yesCount.push(amountAdded);
    }

    function addNoBet(uint256 _marketId) public payable {
        require(msg.value != 0, "you cant stake 0 wei");
        //bet must be above a certain minimum 
        require(msg.value >= minimumBet);
        Markets storage market = markets[_marketId];
        (bool sent, ) = address(this).call{value: msg.value}("");
        require(sent, "failed to send");

        AmountAdded memory amountAdded = AmountAdded(
            msg.sender,
            msg.value,
            block.timestamp
        );

        market.totalNoAmount += msg.value;
        market.totalAmount += msg.value;
        market.noCount.push(amountAdded);
    }

    function getGraphData(uint256 _marketId)
        public
        view
        returns (AmountAdded[] memory, AmountAdded[] memory)
    {
        Markets storage market = markets[_marketId];
        return (market.yesCount, market.noCount);
    }


    function distributeWinningAmount(uint256 _marketId, bool eventOutcome)
        public
        payable
    {
        require(msg.sender == owner, "Unauthorized");

        Markets storage market = markets[_marketId];
        if (eventOutcome) {
            for (uint256 i = 0; i < market.yesCount.length; i++) {
                uint256 amount = ((market.totalNoAmount *
                    market.yesCount[i].amount) / market.totalYesAmount) - tax;
                winningAmount[market.yesCount[i].user] += (amount +
                    market.yesCount[i].amount);
                winningAddresses.push(market.yesCount[i].user);
            }

            for (uint256 i = 0; i < winningAddresses.length; i++) {
                address payable _address = payable(winningAddresses[i]);
                bool sent = (_address).send(winningAmount[_address]);
                require(sent, "failed to distribute");
                delete winningAmount[_address];
            }
            delete winningAddresses;
        } else {
            for (uint256 i = 0; i < market.noCount.length; i++) {
                uint256 amount = ((market.totalYesAmount *
                    market.noCount[i].amount) / market.totalNoAmount) - tax;
                winningAmount[market.noCount[i].user] += (amount +
                    market.noCount[i].amount);
                winningAddresses.push(market.noCount[i].user);
            }

            for (uint256 i = 0; i < winningAddresses.length; i++) {
                address payable _address = payable(winningAddresses[i]);
                bool sent = (_address).send(winningAmount[_address]);
                require(sent, "failed to distribute");
                delete winningAmount[_address];
            }
            delete winningAddresses;
        }
        market.eventCompleted = true;
    }
  
}
