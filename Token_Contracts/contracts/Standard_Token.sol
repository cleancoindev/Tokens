/*Most, basic default, standardised Token contract.
Allows the creation of a token with a finite issued amount to the creator.

Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
Has additional event called TransferFrom that is not standard (instead of just Transfer in transferFrom()).
This is to recreate state using only events.
.*/

import "Token.sol";

contract Standard_Token is Token {

    address issuer;

    modifier ifissuer { if(issuer == tx.origin) _ }

    function Standard_Token(uint256 _initial_amount) {
        balances[msg.sender] = _initial_amount;
        total_supply = _initial_amount;
        issuer = tx.origin;
    }

    function issue(uint256 _new_amount) ifissuer returns (bool success) {
      balances[issuer] = _new_amount;
      total_supply += _new_amount;
      return true;
    }

    function setIssuer(address _new_issuer) ifissuer returns (bool success) {
      issuer = _new_issuer;
      return true;
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    //NOTE: This function will throw errors wrt changing storage where it should not, due to the optimizer errors, IF not careful.
    //As it is now, it works for both earlier and newer solc versions. (NO need to change anything)
    //In the future, the TransferFrom event will be moved to just before "return true;" in order to make it more elegant (once the new solc version is out of develop).
    //If you want to move parts of this function around and it breaks, you'll need at least:
    //Over commit: https://github.com/ethereum/solidity/commit/67c855c583042ddee6261a9921239a3afd086c14 (last successfully working commit)
    //See issue for details: https://github.com/ethereum/solidity/issues/333 & issue: https://github.com/ethereum/solidity/issues/281
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            TransferFrom(_from, _to, _value);
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    function totalSupply() constant returns (uint256 _total) {
        return total_supply;
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 total_supply;
}
