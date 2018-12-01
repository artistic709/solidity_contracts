pragma solidity ^0.4.24;

contract personalWallet {

    address public owner;
    address public recovery;
    uint256 public nonce;

    constructor(address _owner, address _recovery) public {
        owner = _owner;
        recovery = _recovery;
    }

    function isOwner(address _owner) public view returns(bool){
        return(_owner == owner);
    }

    function owners() public view returns(address[] memory _owners){
        _owners = new address[](1);
        _owners[0] = owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyRecovery(){
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
        bytes32 digest = keccak256(abi.encodePacked(_to, _value, _data, _nonce));
        bytes32 txHash = keccak256(abi.encodePacked(prefix,digest));
        require(ecrecover(txHash, _v, _r, _s) == owner);
        nonce = nonce + 1;
        require(_to.call.value(_value)(_data));
        emit Execute(_to, _value, _data);
    }

    function () public payable{
    }

}

contract personalWalletFactory {

    mapping(address => bool) public isWallet;

    function create(address _owner, address _recovery) public returns (address wallet) {
        wallet = new personalWallet(_owner, _recovery);
        isWallet[wallet] = true;
    }
}
