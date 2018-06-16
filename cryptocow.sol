pragma solidity ^0.4.18;

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
  function Ownable() public {
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
  event Transfer(address indexed from, address indexed to, uint256 value);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20Token is Ownable, ERC20Interface {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;
  mapping(address => mapping(address => uint256)) internal allowed;

  function balanceOf(address _owner) public view returns (uint256){
    return balances[_owner];
  }
  function _transfer(address _from,address _to,uint256 _value)internal returns(bool){
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
    return _transfer(_from,_to,_value);
  }
}

contract CryptoCow is ERC20Token{
  using SafeMath for uint256;

  uint256 constant PSN=1642182;
  uint256 constant PSNH=821091;
  address public ceoAddress;
  uint256 public marketEggs;
  function CryptoCow(uint256 initialSupply,string _name, string _symbol, uint8 _decimals) public payable{
    totalSupply = initialSupply;
    balances[0xbeef] = initialSupply;
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
  function ()public payable{
    buyToken();
  }
  event Award(address awardee,uint256 amount);

  function award(address _awardee,uint256 _amount)public onlyOwner{
    totalSupply=totalSupply.add(_amount);
    balances[_awardee]=balances[_awardee].add(_amount);
    emit Award(_awardee,_amount);
  }

  function selltoken(uint256 _amount) public{
    uint256 tokenValue = calculateTokenSell(_amount);
    _transfer(msg.sender,0xbeef,_amount);
    msg.sender.transfer(tokenValue);
  }

  function buyToken() public payable{
    uint256 tokenBought=calculateTokenBuy(msg.value,SafeMath.sub(this.balance,msg.value));
    _transfer(0xbeef,msg.sender,tokenBought);
  }
  //model stoled from EtherShrimpFarm
  function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public pure returns(uint256){
    //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
    //PSN.mul(bs).div(PSNH.add(PSN.mul(rs).add(PSNH.mul(rt)).div(rt)))
    return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
  }
  function calculateTokenSell(uint256 eggs) public view returns(uint256){
    return calculateTrade(eggs,balances[0xbeef],this.balance);
  }
  function calculateTokenBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
    return calculateTrade(eth,contractBalance,balances[0xbeef]);
  }
  function calculateTokenBuySimple(uint256 eth) public view returns(uint256){
    return calculateTokenBuy(eth,this.balance);
  }
  function getBalance() public view returns(uint256){
    return this.balance;
  }
}