// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract SimpleWallet {

    struct Transaction {
        address from;
        address to;
        uint timestamp;
        uint amount;
    }

    Transaction[] public transactionHistory;
    address public owner;
    string public str;
    bool public stop;
    uint public startTime ; 

    event Transfer(address receiver, uint amount);
    event Receive(address sender, uint amount);
    event ReceiveUser(address sender, address receiver, uint amount);

    modifier onlyOwner() {
        require(msg.sender==owner, "Unauthorized Access");
        _;
    }

    modifier getSuspiciousUser(address _sender) {
        require(suspiciousUser[_sender] < 5, "Suspicious activity found. Try sometime later.");
        _;
    }

    modifier isEmergencyDeclared() {
        require(stop == false, "Emergency is declared.");
        _;
    }

    mapping(address => uint) suspiciousUser;

    constructor() {
        owner = msg.sender;
        startTime = block.timestamp;
    }

    function toggleStop() external onlyOwner {
        stop = !stop;
    }

    function changeOwner(address newOwner) public onlyOwner isEmergencyDeclared {
        owner = newOwner;
    }

    function transferToContract() external payable getSuspiciousUser(msg.sender) {
        require(block.timestamp> startTime+300, "This will work after 5 mins of startTime.");
        transactionHistory.push(Transaction({
            from : msg.sender, 
            to : address(this), 
            timestamp : block.timestamp,
            amount : msg.value
        }));
        payable (msg.sender).transfer(msg.value);
    }

    function transferToUserViaContract(address payable _to, uint _weiAmount) external onlyOwner {
        require(address(this).balance>=_weiAmount, "Insufficient balance");
        require(_to != address(0), "Address format is incorrect");
        _to.transfer(_weiAmount);
        transactionHistory.push(Transaction({
            from : msg.sender, 
            to : _to, 
            timestamp : block.timestamp,
            amount : _weiAmount
        }));
        emit Transfer(_to, _weiAmount);
    }

    function withdrawFromContract(uint _weiAmount) external onlyOwner {
        require(address(this).balance>=_weiAmount, "Insufficient balance");
        payable(owner).transfer(_weiAmount);
        transactionHistory.push(Transaction({
            from : address(this), 
            to : owner, 
            timestamp : block.timestamp,
            amount : _weiAmount
        }));
    }

    function getContractBalanceInWei() external view returns (uint) {
        return address(this).balance; 
    }

    function transferToUserViaMsgValue(address payable  _to) external payable {
        require(address(this).balance>=msg.value, "Insufficient value");
        require(_to != address(0), "Address format is incorrect");
        _to.transfer(msg.value);
    }

    function receiveFromUser() external payable {
        require(msg.sender.balance>=msg.value, "Insufficient value");
        require(msg.value>0, "Amount should be greater than 0");
        payable(owner).transfer(msg.value);
        emit ReceiveUser(msg.sender, owner, msg.value);
    }

    function getOwnerBalanceInWei() external view returns (uint) {
        return owner.balance; 
    }

    receive() external payable {
        emit Receive(msg.sender, msg.value);
        transactionHistory.push(Transaction({
            from : msg.sender, 
            to : address(this), 
            timestamp : block.timestamp,
            amount : msg.value
        }));
    }

    fallback() external payable  {
        suspiciousActivity(msg.sender);
    }

    function suspiciousActivity(address _sender) public {
        suspiciousUser[_sender] += 1;
    }

    function getTransactionHistory() external view returns (Transaction[] memory) {
        return transactionHistory;
    }

    function emergencyWithdrawl() external {
        require(stop==true, "Emergency is not declared");
        payable (owner).transfer(address(this).balance);
    }

}