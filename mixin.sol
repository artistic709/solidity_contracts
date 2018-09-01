pragma solidity ^0.4.24;

interface TokenERC20 {
    function transfer(address _to, uint256 _value) external returns(bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns(bool);
}


contract tokenMixin {
    using SafeMath for uint256;
    mapping(address => uint256) public balanceOf;
    address tokenAddress;
    TokenERC20 token;

    constructor(address _token) public{
        tokenAddress = _token;
        token = TokenERC20(tokenAddress);
    }

    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external{
        require(msg.sender == tokenAddress);
        require(token.transferFrom(_from,address(this),_value));
        balanceOf[_from] = balanceOf[_from].add(_value);

    }
    function deposit(uint256 _value) public {
        address _from = msg.sender;
        require(token.transferFrom(_from,address(this),_value));
        balanceOf[_from] = balanceOf[_from].add(_value);
    }
    function withdraw(uint256 _value) public {
        address _to = msg.sender;
        balanceOf[_to] = balanceOf[_to].sub(_value);
        require(token.transfer(_to,_value));
    }

    function mix (address[] from, address[] to, uint256[] out, uint256[] _in, uint8[] v,bytes32[] r,bytes32[] s) public {
        
        uint256 totalOut;
        uint256 totalIn;

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 digest = keccak256(from, to, out, _in,address(this));
        bytes32 txHash = keccak256(prefix,digest);

        for (uint256 i = 0; i < from.length; i++){
            require(ecrecover(txHash,v[i],r[i],s[i]) == from[i]);
        }
        for (i = 0; i < from.length; i++){
            address f = from[i];
            balanceOf[f] = balanceOf[f].sub(out[i]);
            totalOut = totalOut.add(out[i]);
        }
        for(i = 0; i < to.length; i++){
            address t =to[i];
            balanceOf[t] = balanceOf[t].sub(_in[i]);
            totalIn = totalIn.add(out[i]);
        }
        require(totalIn == totalOut);
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
