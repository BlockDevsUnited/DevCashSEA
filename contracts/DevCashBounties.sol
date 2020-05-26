pragma solidity ^0.5.0;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DevCashBountyCreator{
    address DCASH = 0x0fca8Fdb0FB115A33BAadEc6e7A141FFC1bC7d5a;
    address[] public IndividualBounties;
    address[] public SingleBounties;
    address[] public MultiBounties;

    function newIndividualBounty(uint _amount, address BountyHunter) public {
       IndividualBounty I = new IndividualBounty(DCASH, BountyHunter);
        ERC20(DCASH).transferFrom(msg.sender,address(I),_amount);
        IndividualBounties.push(address(I));
    }
    function newSingleBounty(uint _amount) public{
        SingleBounty S = new SingleBounty(DCASH);
        ERC20(DCASH).transferFrom(msg.sender,address(S),_amount);
        SingleBounties.push(address(S));
    }
    function newMultiBounty(uint _amount,uint numBounties) public {
        MultiBounty M = new MultiBounty(DCASH,numBounties);
        ERC20(DCASH).transferFrom(msg.sender,address(M),_amount);
        MultiBounties.push(address(M));
    }

}

contract IndividualBounty{
    address BountyHunter;
    address Issuer;
    string submission;
    address DCASH;

    constructor(address _DCASH, address _BountyHunter) public {
        Issuer = tx.origin;
        DCASH = _DCASH;
        BountyHunter = _BountyHunter;
    }

    function approve() public{
        require(msg.sender==Issuer);
        uint balance = ERC20(DCASH).balanceOf(address(this));
        ERC20(DCASH).transfer(BountyHunter,balance);
    }

    function claim(string memory _submission) public {
        require(msg.sender == BountyHunter);
        submission = _submission;
    }
}

contract SingleBounty{
    address Issuer;
    mapping(address=>string) public submissions;
    address[] public claimants;
    address DCASH;

    constructor(address _DCASH) public {
        Issuer = tx.origin;
        DCASH = _DCASH;
    }

    function claim(string memory _submission) public {
        bytes memory EmptyStringTest = bytes(submissions[msg.sender]);
        require(EmptyStringTest.length!=0);
        submissions[msg.sender] = _submission;
        claimants.push(msg.sender);
    }

    function approve(uint _claim) public{
        require(msg.sender==Issuer);
        uint balance = ERC20(DCASH).balanceOf(address(this));
        address claimant = claimants[_claim];
        ERC20(DCASH).transfer(claimant,balance);
    }
}

contract MultiBounty{
    mapping(address=>string) public submissions;
    address[] public claimants;
    address Issuer;
    address DCASH;
    uint public numBounties;

    address[] public beenAwarded;
    uint public awarded;


    constructor(address _DCASH, uint _numBounties) public {
        Issuer = tx.origin;
        DCASH = _DCASH;
        numBounties = _numBounties;
    }

    function approve(uint claim) public{
        require(msg.sender==Issuer && numBounties>0);
        address BountyHunter = claimants[claim];
        uint individualBounty = ERC20(DCASH).balanceOf(address(this))/numBounties--;
        ERC20(DCASH).transfer(BountyHunter,individualBounty);

        beenAwarded.push(BountyHunter);
        awarded++;
    }

     function claim(string memory _submission) public {
        bytes memory EmptyStringTest = bytes(submissions[msg.sender]);
        require(EmptyStringTest.length==0);
        submissions[msg.sender] = _submission;
        claimants.push(msg.sender);
    }
}
