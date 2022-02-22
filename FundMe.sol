// SPDX-License-Identifier: MIT

//simple but effective crowdsourcing application where users can fund and admin can withdraw the funds to spend them on things
pragma solidity >=0.6.6 <0.9.0;

//interfaces have abstract functions pretty much
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

//safemath is no longer needed starting weith solidity 0.8
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    using SafeMathChainlink for uint256;
    //keep track of who sent us funding
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address owner;

    //everything in the constructor is immediately called when contract is deployed
    //need to define owner here bc if owner is defined in a function people could call it later which is bad
    constructor() public {
        owner = msg.sender;
    }

    // When we define a function as payable we are saying we can use this function to pay for things
    function fund() public payable {
        //msg.sender and msg.value are keywrods in every contract call and every transaction.
        //msg.sender is who made the function call and msg.value is how much they sent
        //pretend we want $5 usd
        uint256 minimumUSD = 5*10**18;
        //require statements are good practice. if fails then tx will revert.
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH!");
        addressToAmountFunded[msg.sender] += msg.value;
        //if someone funds multiple times then this array will be redundant but we ignore for now
        funders.push(msg.sender);
        //what the ETH -> USD conversion rate
    }

    function getVersion() public view returns (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

    function getPrice() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 answer,,,) = priceFeed.latestRoundData();
        //current answer has 8 decimal places but wei is 18 decimal places so multiply
        return uint256(answer * 10000000000);
    }
    //again using view because we are not making a state change
    // 1000000000 wei = 1 gwei
    function getConversionRate(uint256 ethAmount) public view returns (uint256){
        uint256 ethPrice = getPrice();
        //ethPrice and ethAmount are in wei so we need to divide by 10^18
        uint256 ethAmountInUsd = (ethPrice*ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    //modifiers say that when u run code, first do this require statement
    //then wherever the underscore is, run the rest of the code (so require could come after but in this case its first)
    modifier onlyOwner {
        require(msg.sender == owner, "not the owner");
        _;
    }
    //function to withdraw money from contract
    function withdraw() payable onlyOwner public {
        //this line says whoever called the withdraw function, transfer them all of our money
        //require msg.send == owner with modifer
        msg.sender.transfer(address(this).balance);

        //after withdraw, the mapping will be updated to show 0 funded from everyone
        for (uint256 funderIndex=0; funderIndex<funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //reset funders array
        funders = new address[](0);
    }
}