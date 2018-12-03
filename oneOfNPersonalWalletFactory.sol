pragma solidity ^0.4.24;

contract oneOfNPersonalWallet {

    address public owner;
    address[] public operators;
    mapping (address => bool) public isOwner;
    address public recovery;
    uint256 public nonce;

    constructor(address[] _operators, address _recovery) public {
        for(uint i = 0; i < _operators.length; i++){
            operators.push(_operators[i]);
            isOwner[_operators[i]] = true;
        }
        recovery = _recovery;
    }

    function owners() public view returns(address[] memory _owners){
        _owners = new address[](operators.length);
        for(uint i = 0; i < operators.length; i++){
            _owners[i] = operators[i];
        }
    }

    function meta() public view returns(uint256 _meta){
        _meta = 1<<4 + operators.length << 10;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender]);
        _;
    }
    
    modifier onlyRecovery(){
        require(msg.sender == recovery);
        _;
    }

    function setRepresentative(address _owner) onlyRecovery external{
        owner = _owner;
    }

    function addOwner(address _owner) onlyRecovery external{
        operators.push(_owner);
        isOwner[_owner] = true;
    }

    function removeOwner(address _owner) onlyRecovery external{
        require(isOwner[_owner]);
        isOwner[_owner] = false;
        for (uint i=0; i<operators.length - 1; i++)
            if (operators[i] == _owner) {
                operators[i] = operators[operators.length - 1];
                break;
            }
        operators.length -= 1;
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
        require(isOwner[ecrecover(txHash, _v, _r, _s)]);
        nonce = nonce + 1;
        require(_to.call.value(_value)(_data));
        emit Execute(_to, _value, _data);
    }

    function () public payable{
    }

}

contract oneOfNPersonalWalletFactory {

    mapping(address => bool) public isWallet;

    function create(address[] _owners, address _recovery) public returns (address wallet) {
        wallet = new oneOfNPersonalWallet(_owners, _recovery);
        isWallet[wallet] = true;
    }
}
