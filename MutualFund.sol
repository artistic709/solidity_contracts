pragma solidity ^0.4.24;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
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

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Interface {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 value, address token, bytes data) public;
}

contract ERC20Token is ERC20Interface {
    using SafeMath for uint256;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    function balanceOf(address _owner) public view returns (uint256){
        return balances[_owner];
    }
    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    function transfer(address _to, uint256 _value) public returns (bool) {
        return _transfer(msg.sender,_to,_value);
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(msg.sender != _from);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return _transfer(_from, _to, _value);
    }

    event Approval(address indexed from, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Mint(address indexed to, uint256 value);

    function _burn(address _from, uint256 _value) internal returns(bool){
        balances[_from] = balances[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Transfer(msg.sender, address(0), _value);
        emit Burn(_from, _value);
        return true;
    }

    function _mint(address _to, uint256 _value) internal returns(bool){
        balances[_to] = balances[_to].add(_value);
        totalSupply = totalSupply.add(_value);
        emit Transfer(address(0), msg.sender, _value);
        emit Mint(_to, _value);
        return true;
    }

    function approveAndCall(address _spender, uint _value, bytes data) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _value, this, data);
        return true;
    }
}

contract MutualFund is ERC20Token, Ownable{
    using SafeMath for uint256;

    ERC20Interface[] public components;
    mapping(address => bool) public isComponent;
    mapping(address => uint256) public poolUnits;

    constructor(ERC20Interface[] _components)public{
        name = "MutualFund1";
        symbol = "MF1";
        decimals = 18;
        for(uint256 i = 0; i < _components.length; i++){
            components.push(_components[i]);
            isComponent[address(_components[i])] = true;
        }
    }

    function initialize(uint256[] units) external onlyOwner {
        require(totalSupply == 0 && units.length == components.length);

        for(uint256 i = 0; i < components.length; i++){
            require(components[i].transferFrom(msg.sender, address(this), units[i]));
            poolUnits[components[i]] = units[i];
        }
        _mint(msg.sender,10**18);
    }

    modifier initialized() {
        require(totalSupply > 0);
        _;
    }

    function issue(uint256 amount) external initialized {
        for(uint256 i = 0; i < components.length; i++){
            address token = address(components[i]);
            uint256 x = poolUnits[token].mul(amount).div(totalSupply);
            poolUnits[token] = poolUnits[token].add(x);
            require(components[i].transferFrom(msg.sender, address(this), x));
        }
        _mint(msg.sender, amount);
    }

    function redeem(uint256 _amount) external initialized {
        uint256 amount = _amount.mul(197).div(200);
        for(uint256 i = 0; i < components.length; i++){
            address token = address(components[i]);
            uint256 x = poolUnits[token].mul(amount).div(totalSupply);
            poolUnits[token] = poolUnits[token].sub(x);
            require(components[i].transfer(msg.sender, x));
        }
        _burn(msg.sender, amount);
    }

    function update(address token)public{
        require(isComponent[token]);
        uint256 amount = ERC20Interface(token).balanceOf(address(this));
        if(amount > poolUnits[token]){
            poolUnits[token] = amount;
        }
    }

}
