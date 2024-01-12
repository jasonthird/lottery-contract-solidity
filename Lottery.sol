// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.20

pragma solidity ^0.8.20;

struct Item {
    uint itemId;
    address[] itemTokens;
}

struct Person {
    uint personId;
    address addr;
    uint remainingTokens;
}

enum Stage {Init, Reg, Bid, Done}

contract Lottery{

    address[] public winners;
    mapping(address => Person) public tokenDetails;
    Item[] public items;
    Person[] bidders;
    uint public lotteryNumber = 0;
    Stage public stage = Stage.Init;

    address public beneficiary; // the owner and pressident of the contract

    modifier onlyOwner {
        require(msg.sender == beneficiary);
        _;
    }

    uint bidderCount = 0;

    constructor(uint _itemCount) {
        beneficiary = msg.sender;
        for(uint i = 0; i < _itemCount; i++) {
            items.push(Item(i, new address[](0)));
        }
    }

    function amountOfItems() public view returns(uint count) {
        return items.length;
    }

    function winnerGetter() public view returns(address[] memory) {
        return winners;
    }

    function addMoreItems(uint _itemCount) public onlyOwner {
        require(stage == Stage.Init);
        for(uint i = 0; i < _itemCount; i++) {
            items.push(Item(i, new address[](0)));
        }
    }

    modifier registerable {
        require(stage == Stage.Reg);
        require(msg.value >= 0.005 ether);
        require(msg.sender != beneficiary);
        require(tokenDetails[msg.sender].personId == 0);
        _;
    }

    function register() public payable registerable {
        //require that the person is not registered
        //register the bidder
        bidders.push(Person(bidderCount+1, msg.sender, 5));
        tokenDetails[msg.sender] = bidders[bidderCount];
        bidderCount++;
    }

    modifier biddable (uint _count) {
        require(stage == Stage.Bid);
        //check if the person is registered
        require(tokenDetails[msg.sender].personId != 0);
        //check if the person has enough tokens to bid
        require(tokenDetails[msg.sender].remainingTokens >= _count);
        _;
    }

    function bid(uint _itemId, uint _count) public biddable(_count) payable {
        //deduct the tokens from the person
        tokenDetails[msg.sender].remainingTokens -= _count;
        //add the tokens to the item
        items[_itemId].itemTokens.push(msg.sender);
    }

    event WinnerEvent(address winner,uint item, uint lotteryNumber);
    
    function revealWinners() public onlyOwner {
        require(stage == Stage.Done);
        require(winners.length <= items.length);

        //pick the winners
        uint randomIndex = 0;
        for(uint i = winners.length; i < items.length; i++) {
            if(items[i].itemTokens.length != 0) {
                randomIndex = (block.number / items.length + block.timestamp / items.length) % items[i].itemTokens.length;
                winners.push(items[i].itemTokens[randomIndex]);
                emit WinnerEvent(bidders[randomIndex].addr,i,lotteryNumber);
            }
            if(items[i].itemTokens.length == 0) {
                winners.push(address(0));
                emit WinnerEvent(address(0),i,lotteryNumber);
            }
        }
    }

    function advanceStage() public onlyOwner {
        require(uint(stage) < uint(Stage.Done));
        stage = Stage(uint(stage) + 1);
    }

    function withdraw() public onlyOwner(){
        //beneficiary steals the money
        payable(beneficiary).transfer(address(this).balance);
    }

    function reset() public onlyOwner(){
        //reset the state of the contract
        delete bidders;
        delete items;
        delete winners;
        bidderCount = 0;
        stage = Stage.Init;
        lotteryNumber++;
    }    

}