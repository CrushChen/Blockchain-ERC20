pragma solidity ^0.4.13;
contract Token {
    
    uint256 public totalSupply;

    
    function balanceOf(address _owner) constant returns (uint256 balance);

   
    function transfer(address _to, uint256 _value) returns (bool success);

    
    function transferFrom(address _from, address _to, uint256 _value) returns  (bool success);

    
    function approve(address _spender, uint256 _value) returns (bool success);

    
    function allowance(address _owner, address _spender) constant returns  (uint256 remaining);
    
    function MakeDeposit() public payable; 
    
    function ArrppproveTxSuccess() public; 
    
    function ApproveTxFail () public ; 
    
    function Arbitrate(string choice) public;
    
    function Timelock() public ; 

   
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

   
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {
    
    address public buyer= 0x1675945529F7eC5890194cd7a17a131d0C15b806;
    bool public buyer_agree; 
    bool desposit; 
    address public seller = 0xe34210Bb50b5EA08bB061f8919d914a69E455bDB;
    bool public seller_agree;
    uint256 public money; 
    address arbitrator; 
    string public judge_state = "undecided";
    uint public start_time;
    address public escrowre = 0x508Fc1CC3d455a7c39Fe095B46064c73CAF9e17d; 
    function transfer(address _to, uint256 _value) returns (bool success) {
       
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        
        require(balances[_from] >= _value && allowed[_from][msg.sender] >=  _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
    
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
   
    function approve(address _spender, uint256 _value) returns (bool success)   
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
     function MakeDeposit() public payable {
        require(msg.sender == buyer);
        money = msg.value;
        escrowre.transfer(msg.value);
        desposit = true;
     }
     
    function ArrppproveTxSuccess() public
    {   
        require(desposit == true); 
        if(msg.sender == seller)
        {
            seller_agree = true;
            if(buyer_agree == true)
            {
                // send money to seller
                judge_state = "success";
                transferFrom(escrowre,seller,money);
               // transferFrom();
            }
            else if(buyer_agree == false)
            {
                // dispute 
                Timelock();
            }
           
        }
        else if (msg.sender == buyer)
        {
            buyer_agree= true;
            if(seller_agree == true)
            {
                // send money to seller
                judge_state = "success";
                transferFrom(escrowre,seller,money);
            }
            else if(seller_agree == false)
            {
                // dispute
               // require(buyer_agree == false,"please call Arbitrate, you have 2 mintues left ");
                Timelock();
            }
        }
    }
    function ApproveTxFail () public 
    {
        require(desposit == true); 
        if(msg.sender == seller)
        {
            seller_agree == false;
            if(buyer_agree == true)
            {
                // dispute
                Timelock();
            }
            else if(buyer_agree == false)
            {
                // refund  ; send money to buyer  
                judge_state = "fail";
                transferFrom(escrowre,buyer,money);
            }
        }
        else if (msg.sender == buyer)
        {
            buyer_agree= false;
            if(seller_agree == true)
            {
                // dispute
                Timelock();
            }
            else if(seller_agree == false)
            {
                // send money to buyer 
                judge_state = "fail";
                transferFrom(escrowre,buyer,money);
            }
            
        }
    }
    
    
    function Arbitrate(string choice) public
    {
        if (now <= start_time + 2 minutes)
        {
         judge_state = choice;
            if (keccak256(judge_state) == keccak256("fail"))
            {
                transferFrom(escrowre,buyer,money);
            }
            else
            {
                transferFrom(escrowre,seller,money);
            }
        }
        else {
            judge_state ="fail";
        }
        
        
    }
    function Timelock() public 
    {
         start_time = now; 
    }
     

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract DAToken is StandardToken {
    string public name;                   
    uint8 public decimals;               
    string public symbol;                
   
    
    function DAToken(uint256 _initialAmount, string _tokenName, uint8 _decimalUnits, string _tokenSymbol) {
        balances[msg.sender] = _initialAmount; 
        totalSupply = _initialAmount;        
        name = _tokenName;                   
        decimals = _decimalUnits;          
        symbol = _tokenSymbol;            
    }
   
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        

        require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }
}