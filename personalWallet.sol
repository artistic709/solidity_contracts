pragma solidity ^0.4.24;

contract personalWallet {

    address public owner;
    address public recovery;
    uint256 public nonce;

    constructor(address _owner, address _recovery){
        owner = _owner;
        recovery = _recovery
    }

    function isOwner(address _owner) public view returns(bool){
        return(_owner == owner);
    }

    function owners() public view returns(address[] _owners){
        _owners.push(owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyrecovery(){
        require(msg.sender == recovery);
        _;
    }

    function setOwner(address _owner) onlyRecovery external{
        owner = _owner;
    }

    function setRecovery(address _recovery) onlyRecovery external{
        recovery = _recovery;
    }

    event Execute(address to, uint256 value, bytes data);

    function execute(address _to,uint256 _value,bytes _data) public onlyOwner{
        require(_to.call.value(_value)(_data));
        emit Execute(_to, _value, _data);
    }
    
    function delegateExecute(address _to, uint256 _value, bytes _data, uint256 _nonce, uint8 _v, bytes32 _r, bytes32 _s) public{
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 digest = keccak256(_to, _value, _data, _nonce);
        bytes32 txHash = keccak256(prefix,digest);
        require(ecrecover(txHash, _v, _r, _s) == owner);
        nonce = nonce + 1;
        require(_to.call.value(_value)(_data));
        emit Execute(_to, value, _data);
    }

    function ()public payable{
    }

}
