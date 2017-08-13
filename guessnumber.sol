pragma solidity ^0.4.15;
contract guessnumber {
	// of course it's a useless contract
	address owner;
	string name;
	mapping (address => uint256) public coinBalance;
	mapping (address => bool) public activated;
	mapping (address => mapping( uint => uint)) private answer;

	function guessnumber(){
		owner=msg.sender;
		name="guessnumbercoin";
	}
	
	// create a four-digit random number
	function start() returns (bool){
		require(activated[msg.sender]==false);

		uint seed = block.timestamp+block.difficulty+block.number;
		
		for (uint i=0;i<4;i++){

			answer[msg.sender][i]=(seed % (10**(i+1)))/(10**i);

			for(uint j=0;j<i;j++){
				if(answer[msg.sender][i]==answer[msg.sender][j]){
					answer[msg.sender][i]=(answer[msg.sender][i]+7)%10;
					j=0;
				}
			}
		}
		activated[msg.sender]=true;
		return true;
	}

	// enter a four-digit number and get a hint
	// A = count of digits that meet the right number
	// B = count of numbers that exist but at a wrong place
	// eg: if the answer is 1234, then 3254 = 2A1B
	function guess(uint _answer) constant returns(uint A,uint B){
		require(activated[msg.sender]==true);
		require(_answer<=9876);
		require(_answer>=1234);
		uint[] memory guessanswer = new uint[](4);
		uint a=0;
		uint b=0;
		for(uint i=0;i<4;i++){
			guessanswer[i]=(_answer % (10**(i+1)))/(10**i);
		}
		for(uint j=0;j<4;++j){
			if(guessanswer[j]==answer[msg.sender][j]){
				a+=1;
			}
			for(uint k=0;k<4;++k){
				if(guessanswer[k]==answer[msg.sender][j]){
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
		require(_answer<=9876);
		require(_answer>=1234);
		uint[] memory guessanswer = new uint[](4);
		for(uint i=0;i<4;i++){
			guessanswer[i]=(_answer % (10**(i+1)))/(10**i);
		}
		for(uint j=0;j<4;j++){
			if(guessanswer[j]!=answer[msg.sender][j]){
				return false;
			}
		}
		coinBalance[msg.sender]+=1;

		activated[msg.sender]=false;
		return true;
	}

	// collect donation (?
	function withdraw(){
		require(msg.sender==owner);
		owner.transfer (this.balance);
	}
}
