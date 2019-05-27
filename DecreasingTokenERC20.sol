pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
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
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
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

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y)
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }

    function pow(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 ans = 1;
        while(b != 0){
            if(b%2 == 1)
                ans = mul(ans,a);
            a = mul(a,a);
            b = b / 2;
        }
        return ans;
    }

}

/**
 * @title tokenRecipient
 * @dev An interface capable of calling `receiveApproval`, which is used by `approveAndCall` to notify the contract from this interface
 */
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

/**
 * @title DecreasingTokenERC20
 * @dev A simple ERC20 standard token with burnable function
 */
contract DecreasingTokenERC20 {
    using SafeMath for uint256;

    uint256 internal _totalSupply;
    uint256 internal base;
    uint256 internal today;

    // This creates an array with all balances
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) public allowed;

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() public {
        base = 1000000;
        today = now / 1 days;
    }

    function balanceOf(address _owner) view public returns(uint256) {
        uint256 _base = getbase()
        return balances[_owner] / _base;
    }

    function allowance(address _owner, address _spender) view public returns(uint256) {
        return allowed[_owner][_spender];
    }

    function totalSupply() view public returns(uint256){
        uint256 _base = getbase()
        return _totalSupply / _base;
    }

    function getbase() public view returns(uint256) {
        uint256 dayWentBy = now / 1 days - today;

        if(dayWentBy > 0)
            return base.mul(pow(100, dayWentBy)) / pow(99, dayWentBy);
        else
            return base;
    }

    modifier iter() {
        uint256 dayWentBy = now / 1 days - today;

        if(dayWentBy > 0){
            base = base.mul(pow(100, dayWentBy)) / pow(99, dayWentBy);
            today = now / 1 days;
        }
        _;
    }

    /**
     * @dev Basic transfer of all transfer-related functions
     * @param _from The address of sender
     * @param _to The address of recipient
     * @param _value The amount sender want to transfer to recipient
     */
    function _transfer(address _from, address _to, uint _value) internal {
        uint256 amount = _value.mul(base);
        balances[_from] = balances[_from].sub(amount);
        balances[_to] = balances[_to].add(amount);
        emit Transfer( _from, _to, _value);
    }

    /**
     * @notice Transfer tokens
     * @dev Send `_value` tokens to `_to` from your account
     * @param _to The address of the recipient
     * @param _value The amount to send
     * @return True if the transfer is done without error
     */
    function transfer(address _to, uint256 _value) public iter returns(bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @notice Transfer tokens from other address
     * @dev Send `_value` tokens to `_to` on behalf of `_from`
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value The amount to send
     * @return True if the transfer is done without error
     */
    function transferFrom(address _from, address _to, uint256 _value) public iter returns(bool) {
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * @notice Set allowance for other address
     * @dev Allows `_spender` to spend no more than `_value` tokens on your behalf
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @return True if the approval is done without error
     */
    function approve(address _spender, uint256 _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @notice Set allowance for other address and notify
     * @dev Allows contract `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     * @param _spender The contract address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     * @return True if it is done without error
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns(bool) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
        return false;
    }

    /**
     * @notice Destroy tokens
     * @dev Remove `_value` tokens from the system irreversibly
     * @param _value The amount of money will be burned
     * @return True if `_value` is burned successfully
     */
    function burn(uint256 _value) public iter returns(bool) {
        uint256 amount = _value.mul(base);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        totalSupply = totalSupply.sub(amount);
        emit Transfer(msg.sender, address(0), _value);
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * @notice Destroy tokens from other account
     * @dev Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     * @param _from The address of the sender
     * @param _value The amount of money will be burned
     * @return True if `_value` is burned successfully
     */
    function burnFrom(address _from, uint256 _value) public iter returns(bool) {
        uint256 amount = _value.mul(base);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(_from, address(0), _value);
        emit Burn(_from, _value);
        return true;
    }

    function transferMultiple(address[] _to, uint256[] _value) public iter returns(bool) {
        require(_to.length == _value.length);
        uint256 i = 0;
        while (i < _to.length) {
           _transfer(msg.sender, _to[i], _value[i]);
           i += 1;
        }
        return true;
    }
}

contract DT is DecreasingTokenERC20, Ownable {
    using SafeMath for uint256;

    // Token Info.
    string public constant name = "DecreasingToken";
    string public constant symbol = "DT";
    uint8 public constant decimals = 18;

    event Mint(address indexed _to, uint256 _amount);

    function mint(address _to, uint256 _amount) public iter onlyOwner{
        uint256 amount = _amount.mul(base);
        _totalSupply = _totalSupply.add(amount);
        balances[_to] = balances[_to].add(amount);
        emit Transfer(address(0), _to, _amount);
        emit Mint(_to, _amount);
    }

}
