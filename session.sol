pragma solidity ^0.4.20;

contract proxy {

  address public _owner;

  function proxy(){
    _owner = msg.sender;
  }

  function owner()public view returns(address){
    return _owner;
  }

  modifier onlyOwner() {
    require(msg.sender == _owner);
    _;
  }

  function execute(address to,uint value,bytes data) public onlyOwner{
    to.call.value(value)(data);
  }
  
  function ()public payable{
  }

}

contract session is proxy{
  address controller;
  uint expireTime;

  function executeByController(address to,uint value,bytes data) public{
    require(msg.sender==controller);
    require(now <= expireTime);
    to.call.value(value)(data);
  }

  function renew() onlyOwner public{
    expireTime = now + 3 days;
  }

  function setController(address _controller) public onlyOwner{
    controller = _controller;
  }

  function session(){
    controller = msg.sender;
    expireTime = now + 3 days;
  }

}
