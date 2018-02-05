pragma solidity ^0.4.18;


library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}



contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


contract RenewableFixedSupplyToken is ERC20Interface, Owned, ApproveAndCallFallBack {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public constant decimals = 18;
    uint public generation;
    uint public _totalSupply;
    address public father;
    address[] public ancestors;
    bool linked;

    mapping(address => bool) isAncestor;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event Burn(address indexed from, uint tokens);


    function RenewableFixedSupplyToken(uint _supply) public {
        symbol = "RFST";
        name = "Renewable Fixed Supply Token";
        _totalSupply = _supply.mul(10**18);
        balances[owner] = _totalSupply;
        Transfer(address(0), owner, _totalSupply);
    }

    function Link(address _father) public onlyOwner{
        require(!linked);
        father = _father;
        RenewableFixedSupplyToken f = RenewableFixedSupplyToken(father);
        generation = f.generation();

        for(uint i=0;i<generation;i++){
            address a = f.ancestors(i);
            ancestors.push(a);
            isAncestor[a]=true;
        }
        ancestors.push(father);
        isAncestor[father]=true;
        generation += 1;
        linked = true;
    }


    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }

    function burnFrom(address from, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
        Burn(from, tokens);
        return true;
    }


    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    

    
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public{
        require(isAncestor[token]);
        require(RenewableFixedSupplyToken(token).burnFrom(from,tokens));
        _totalSupply=_totalSupply.add(tokens);
        balances[from]=balances[from].add(tokens);
        Transfer(address(0),from,tokens);
    }

    function () public payable {
        revert();
    }

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}
