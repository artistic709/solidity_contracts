pragma solidity ^0.4.24;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract cloudmine is Ownable{
        using SafeMath for uint256;
        uint256 ethIn = 1;
        uint256 ethFromPool = 1;
        uint256 accumDiff = 1;
        uint256 start;
        address sparkpool = 0x5A0b54D5dc17e0AadC383d2db43B0a0D3E029c4c;
        
        constructor() public {
                start = now;
        }
        
        event deposit(address from,uint256 amount,uint256 timestamp);
        
        function ()public payable{
                ethIn = ethIn.add(msg.value);
                uint256 incomingHash = block.difficulty.mul(msg.value);
                accumDiff = accumDiff.add(incomingHash);
                
                if(msg.sender == sparkpool){
                        ethFromPool = ethFromPool.add(msg.value);
                }
                emit deposit(msg.sender,msg.value,now);
        }
        function HashRate() public view returns(uint256 avg){
                return(accumDiff / 3 ether / (now - start));
        }
        function withdraw(address destination) public onlyOwner{
                destination.transfer(address(this).balance);
        }
        
}



library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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
