pragma solidity ^0.4.15;
contract guessnumber {
	// of course it's a useless contract
	address owner;
	string public name="guessnumbercoin";
	string public constant symbol = "🤔";
	uint8 public constant decimals = 0;
	uint256 _totalSupply;
	mapping (address => uint256) public balances;
	mapping (address => mapping (address => uint256)) allowed;
	mapping (address => bool) public activated;
	mapping (address => mapping( uint => uint)) private answer;

	function guessnumber() {
		owner=msg.sender;
		_totalSupply=0;
	}
	

	//ERC20 Interfaces↓
	event Transfer(address indexed _from, address indexed _to, uint _value);
	event Approval(address indexed _owner, address indexed _spender, uint _value);
	function totalSupply() constant returns (uint TotalSupply){
		return _totalSupply;
	}
	function balanceOf(address _owner) constant returns(uint256 balanceof){
		return balances[_owner];
	}
	function transfer(address _to, uint256 _amount) returns (bool success){
		if (balances[msg.sender] >= _amount 
			&& _amount > 0 
			&& balances[_to] + _amount > balances[_to]){
			balances[msg.sender] -= _amount;
			balances[_to] += _amount;
			return true;
			Transfer(msg.sender,_to,_amount);
		}
		else{
			return false;
		}
	}
	function transferFrom(address _from, address _to,uint256 _amount) returns (bool success){
		if (balances[_from] >= _amount
			&& allowed[_from][msg.sender] >= _amount
			&& _amount > 0 
			&& balances[_to] + _amount > balances[_to]) {
			balances[_from] -= _amount;
			allowed[_from][msg.sender] -= _amount;
			balances[_to] += _amount;
			return true;
			Transfer(_from,_to,_amount);
		} 
		else {
			return false;
		}
	}
	function approve(address _spender, uint256 _amount) returns (bool success) {
		allowed[msg.sender][_spender] = _amount;
		Approval(msg.sender, _spender, _amount);
		return true;
	}
	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}
	//ERC20 Interfaces↑


	// create a four-digit random number
	function start() returns (bool){
		require(activated[msg.sender]==false);

		uint seed = block.timestamp+block.difficulty+block.number;
		bool[] memory used = new bool[](9);
		for (uint i=0;i<4;i++){
            uint x=seed%9;
            seed/=10;
            while(used[x]==true){
                x=(x+4)%9;
            }
            used[x]=true;
			answer[msg.sender][i]=x+1;

		}
		activated[msg.sender]=true;
		return true;
	}

	// enter a four-digit number and get a hint
	// A = count of digits that meet the right number
	// B = count of numbers that exist but at a wrong place
	// eg: if the answer is 1234, then 3254 = 2A1B
	function guess(address player,uint _answer) constant returns(uint A,uint B){
		require(activated[player]==true);

		uint[] memory guessanswer = new uint[](4);
		uint a=0;
		uint b=0;
		for(uint i=0;i<4;i++){
			guessanswer[i]=_answer%10;
			_answer/=10;
		}
		for(uint j=0;j<4;++j){
			if(guessanswer[j]==answer[player][j]){
				a+=1;
			}
			for(uint k=0;k<4;++k){
				if(guessanswer[k]==answer[player][j]){
					b+=1;
				}
			}
		}
		b-=a;
		return (a,b);
	}

	// submit the correct answer to win a coin 
	function submit(uint _answer) returns(bool success){
		require(activated[msg.sender]==true);

		uint[] memory guessanswer = new uint[](4);
		for(uint i=0;i<4;i++){
			guessanswer[i]=_answer%10;
			_answer/=10;
		}
		for(uint j=0;j<4;j++){
			if(guessanswer[j]!=answer[msg.sender][j]){
				return false;
			}
		}
		balances[msg.sender]+=1;
		_totalSupply+=1;
		activated[msg.sender]=false;
		return true;
	}

	// collect donation (?
	function withdraw(){
		require(msg.sender==owner);
		owner.transfer (this.balance);
	}
}
