pragma solidity ^0.4.24;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ERC20 {
    function balanceOf(address _owner) view public returns(uint256);
    function allowance(address _owner, address _spender) view public returns(uint256);
    function transfer(address _to, uint256 _value) public returns(bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool);
    function approve(address _spender, uint256 _value) public returns(bool);
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns(bool);
}

contract Subscribe_Ether is Ownable{

    using SafeMath for uint256;

    // subscribe fee (per second)
    uint256 public rate;
    //each subscribtion's due time
    mapping (address => uint256) public due;

    constructor(uint256 _rate) public {
        rate = _rate;
    }

    function setRate(uint256 _rate) external onlyOwner {
        rate = _rate;
    }

    event SubscribtionUpdated(address indexed buyer, uint256 newDue);

    function subscribe() payable public{
        address buyer = msg.sender;
        uint256 time = msg.value / rate;
        owner.transfer(msg.value);
        due[buyer] = (due[buyer] > now ? due[buyer] : now).add(time);
        emit SubscribtionUpdated(buyer, due[buyer]);
    }

}

contract Subscribe_ERC20 is Ownable{
    using SafeMath for uint256;
    // subscribe fee (per second)
    uint256 public rate;
    //each subscribtion's due time
    mapping (address => uint256) public due;

    ERC20 token;

    constructor(address _token, uint256 _rate) public {
        token = ERC20(_token);
        rate = _rate;
    }

    function setRate(uint256 _rate) external onlyOwner {
        rate = _rate;
    }

    event SubscribtionUpdated(address indexed buyer, uint256 newDue);

    function subscribe(uint256 time) public {
        address buyer = msg.sender;
        uint256 value = time.mul(rate);
        token.transferFrom(buyer, owner, value);
        due[buyer] = (due[buyer] > now ? due[buyer] : now).add(time);
        emit SubscribtionUpdated(buyer, due[buyer]);
    }

    function receiveApproval(address from, uint256 value, address _token, bytes data) public {
        address buyer = from;
        require(_token == address(token));
        token.transferFrom(buyer, owner, value);
        uint256 time = value / rate;
        due[buyer] = (due[buyer] > now ? due[buyer] : now).add(time);
        emit SubscribtionUpdated(buyer, due[buyer]);
    }

}
