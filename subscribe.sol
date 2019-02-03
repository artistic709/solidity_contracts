pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0)
            return 0;
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
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

contract subscribe is Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) public due;

    // subscribe fee per day
    uint256 public rate;

    constructor(uint256 _rate) public {
        rate = _rate;
    }

    function setRate(uint256 _rate) external onlyOwner {
        rate = _rate;
    }

    event SUB(address indexed suber, uint256 newDue);

    function extend() public payable returns(uint256) {
        uint256 fee = msg.value;
        address suber = msg.sender;
        uint256 current = now > due[suber] ? now : due[suber];
        uint256 newDue = current.add(fee.mul(1 days).div(rate));
        due[suber] = newDue;
        emit SUB(suber, newDue);
        return newDue;
    }

    function () external payable{
        extend();
    }

    function collect() external onlyOwner {
        owner.transfer(address(this).balance);
    }

}
