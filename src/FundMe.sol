// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    AggregatorV3Interface private immutable i_priceFeed;
    address private immutable i_owner;
    uint256 public constant MIN_USD = 5e18;
    address[] private s_senders;
    mapping (address funder => uint256 amountFunded) private s_addressToAmountFunded;

    constructor(address _priceFeedAddress) {
        i_owner = msg.sender;
        i_priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function fund() public payable {
        require(msg.value.getConversionRate(i_priceFeed) > MIN_USD, "Didn't send enough money");
        s_senders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function cheapWithdraw() public isOwner {
        uint256 sendersLength = s_senders.length;
         for (uint256 i = 0; i < sendersLength; i++) {
            address funder = s_senders[i];
            s_addressToAmountFunded[funder] = 0;
        }
        s_senders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Send failed");
    }

    function withdraw() public isOwner {
        // senders = new address[](0);
        // payable(msg.sender).transfer(address(this).balance);

        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        for (uint256 i = 0; i < s_senders.length; i++) {
            address funder = s_senders[i];
            s_addressToAmountFunded[funder] = 0;
        }
        s_senders = new address[](0);

        (bool callSuccess, bytes memory dataReturened) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Send failed");
    }

    function getVersion() public view returns(uint256) {
        return i_priceFeed.version();
    }

   modifier isOwner() {
    // require(msg.sender == i_owner);
    if(msg.sender != i_owner) {
        revert FundMe__NotOwner();
    }
    _;
   }

   // GETTERS
   function getSenders() external view returns(address[] memory) {
       return s_senders;
   }

   function getSender(uint256 index) external view returns(address) {
       return s_senders[index];
   }

   function getAddressToAmountFunded(address fundingAddress) external view returns(uint256) {
       return s_addressToAmountFunded[fundingAddress];
   }

   function getOwner() external view returns(address) {
    return i_owner;
   }
}
