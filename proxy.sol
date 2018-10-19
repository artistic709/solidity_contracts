pragma solidity ^0.4.24;

contract proxy {

  address public owner;

  function proxy(){
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  event Execute(address to,uint value,bytes data);
  function execute(address to,uint value,bytes data) public onlyOwner{
    to.call.value(value)(data);
    emit Execute(to, value, data);
  }
  
  function ()public payable{
  }

}
