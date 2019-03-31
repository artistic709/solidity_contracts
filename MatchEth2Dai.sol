pragma solidity ^0.4.24;

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a / b;
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

// ERC20 token interface
contract ERC20 {
    function balanceOf(address _owner) view external returns(uint256);
    function allowance(address _owner, address _spender) view external returns(uint256);
    function transfer(address _to, uint256 _value) external returns(bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns(bool);
    function approve(address _spender, uint256 _value) external returns(bool);
}

// Ether Price Feed From Maker 
contract PriceFeed{
    function read() external view returns (bytes32);
}

contract MatchEth2Dai {
    using SafeMath for uint256;

    PriceFeed feed = PriceFeed(0x729D19f657BD0614b4985Cf1D82531c67569197B);
    ERC20 Dai = ERC20(0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359);

    struct Order{
        uint256 amount;
        address next;
    }

    mapping(address => Order) public orders;
    address public head;
    address public tail;
    bool public selling;

    function () public payable {
        sell();
    }

    function getRate() internal view returns(uint256){
        bytes32 rate = feed.read();
        return uint256(rate);
    }

    function sell() public payable {
        if(selling){
            enqueue(msg.sender, msg.value);
        }
        else{
            uint256 remaining = fillBuyOrder(msg.sender, msg.value);
            if(remaining > 0){
                selling = true;
                enqueue(msg.sender, remaining);
            }
        }
    }

    function buy(uint256 amount) public {
        require(Dai.transferFrom(msg.sender, address(this), amount));

        if(selling){
            uint256 remaining = fillSellOrder(msg.sender, amount);
            if(remaining > 0){
                selling = false;
                enqueue(msg.sender, remaining);
            }
        }
        else{
            enqueue(msg.sender, amount);
        }
    }

    function cancel() public {
        uint256 amount = orders[msg.sender].amount;
        orders[msg.sender].amount = 0;
        if(selling){
            msg.sender.transfer(amount);
        }
        else{
            Dai.transfer(msg.sender, amount);
        }
    }

    function fillBuyOrder(address seller, uint256 amount) internal returns(uint256) {
        uint256 rate = getRate();
        uint256 daiGain = 0;
        address _head = head;
        while(_head != address(0) && amount != 0) {
            uint256 subtotal = orders[_head].amount.mul(10**18).div(rate);
            if(amount >= subtotal){
                amount = amount.sub(subtotal);
                _head.transfer(subtotal);
                daiGain = daiGain.add(orders[_head].amount);
                address _next = orders[_head].next;
                orders[_head].amount = 0;
                orders[_head].next = address(0);
                _head = _next;
            }
            else{
                _head.transfer(amount);
                uint256 gain = amount.mul(rate).div(10**18);
                daiGain = daiGain.add(gain);
                orders[_head].amount = orders[_head].amount.sub(gain);
                amount = 0;
            }
        }
        head = _head;
        Dai.transfer(seller, daiGain);
        return amount;
    }

    function fillSellOrder(address buyer, uint256 amount) internal returns(uint256) {
        uint256 rate = getRate();
        uint256 ethGain = 0;
        address _head = head;
        while(_head != address(0) && amount != 0) {
            uint256 subtotal = orders[_head].amount.mul(rate).div(10**18);
            if(amount >= subtotal){
                amount = amount.sub(subtotal);
                Dai.transfer(_head, subtotal);
                ethGain = ethGain.add(orders[_head].amount);
                address _next = orders[_head].next;
                orders[_head].amount = 0;
                orders[_head].next = address(0);
                _head = _next;

            }
            else{
                Dai.transfer(_head, amount);
                uint256 gain = amount.mul(10**18).div(rate);
                ethGain = ethGain.add(gain);
                orders[_head].amount = orders[_head].amount.sub(gain);
                amount = 0;
            }
        }
        head = _head;
        buyer.transfer(ethGain);
        return amount;
    }

    function enqueue (address person, uint256 amount) internal {
        if(orders[person].amount == 0) {
            orders[person].amount = amount;
            if(head == address(0)){
                head = person;
                tail = person;
            }
            else{
                orders[tail].next = person;
            }
            tail = person;
        }
        else{
            orders[person].amount = orders[person].amount.add(amount);
        }
    }

}
