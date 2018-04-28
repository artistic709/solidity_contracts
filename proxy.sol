pragma solidity ^0.4.20;

contract proxy {

  address public owner;

  function proxy(){
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function execute(address to,uint value,bytes data) public onlyOwner{
    to.call.value(value)(data);
  }
  
  function ()public payable{
  }

}
