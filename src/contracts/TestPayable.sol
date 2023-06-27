// SPDX-License-Identifier: MIT pragma solidity ^0.8.0;
contract TestPayable {
    string public sentence = "This is payable";
    event Pay(address payer, uint256 amount); constructor() {}
    receive() external payable {}
    function pay() external payable {
       emit Pay(msg.sender, msg.value);
    }
    function dontPay() external {} 
 }