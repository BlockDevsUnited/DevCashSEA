
pragma solidity ^0.5.0;

//CHANGES 
//createPersonalBounty                                              DONE
//createOpenBounty                                                  DONE
//award open bounty directly (without submission)                   DONE
//collapse creators/hunters/arbitrators into one address list.      DONE
//award personal bounty directly to bounty hunter                   POSTPONED
//make sure events are right                                        DONE
//collapse repeating code                                           POSTPONED
//make sure funds never get sent to 0x  
//submissions structure                                             DONE
    //feedback and resubmissions                                    DONE

//make bounty optionally reclaimable                                POSTPONED

//make sure we know that a bounty is inactive                       DONE

//add functions getSubmission, getRevision

//update the relcaim logic
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

contract ERC20Approve {
 function approve(address spender, uint256 value) public returns (bool);
}

contract bountyChest{
    constructor () public {
        ERC20Approve(0x4a0C2edcd5B772cbF4BB8B8F456A372a6d35F3b2).approve(msg.sender,2**256-1);
    }
}
contract Icondition{
      enum ConditionState { Uninitialized, Unfulfilled, Fulfilled, Aborted }

      function createCondition(
        bytes32 _id,
        address _typeRef
    )
        external
        returns (uint size);
    
     function getConditionState(bytes32 _id)
        external
        view
        returns (ConditionState);
   
}
contract ubountyCreator{
    Icondition conditionManager;
    event created(uint uBountyIndex, uint bountyAmount, uint bountiesAvailable);        //add a
    
    event submitted( uint uBountyIndex, uint submissionIndex);          
    event revised( uint uBountyIndex,uint submissionIndex, uint revisionIndex);
    
    event approved( uint uBountyIndex, uint submissionIndex, string feedback);
    event rejected( uint uBountyIndex, uint submissionIndex, string feedback);
    event revisionRequested( uint uBountyIndex, uint submissionIndex, string feedback);
    
    event rewarded( uint uBountyIndex, address Hunter, uint rewardAmount);        
    event reclaimed( uint uBountyIndex, uint reclaimedAmount);               
    event completed( uint uBountyIndex);
    
    event feeChange( uint oldFee, uint newFee);

    address public devcash = 0x4a0C2edcd5B772cbF4BB8B8F456A372a6d35F3b2;
    address public admin;
    uint public fee = 10000000;

    struct submission{
        uint32 submitterIndex;
        string submissionString;
        bool approved;
        mapping(uint=>revision) revisions;
        uint8 numRevisions;
        address bountyResolver;
        bytes32 agreementID;
    }
    
    struct revision{
        uint8 revisionIndex;
        string revisionString;
    }

    struct ubounty{
        uint8 available;          //rename to avaiable
        uint8 numSubmissions;
        uint32 hunterIndex;
        uint32 creatorIndex;
        uint32 bountyChestIndex;
        uint48 deadline;
        string name;
        string description;
        address bountyResolver;
        
        mapping(uint => submission) submissions;
    }

    function getSubmissionString(uint ubountyIndex, uint submissionIndex) public view returns(string memory) {
        return ubounties[ubountyIndex].submissions[submissionIndex].submissionString;
    }

    function getSubmitter(uint ubountyIndex, uint submissionIndex) public view returns(uint){
        return ubounties[ubountyIndex].submissions[submissionIndex].submitterIndex;
    }

    mapping(address=>uint32) bountyChests;
    address[] public bCList; //list of bounty chest addresses
    uint[] public freeBC; // list of unused bounty chests
    function numBC() public view returns(uint){
        return bCList.length;
    }


    mapping(address => uint32) public users;
    address[] public userList;
    function numUsers() public view returns(uint){
        return userList.length;
    }

    mapping(uint => ubounty) public ubounties;
    uint public numUbounties;

    constructor(address _condition) public {
        admin = msg.sender;
        userList.push(address(0));
        bCList.push(address(0));
        conditionManager=Icondition(_condition);
    }
        
        //rename numleft to numavailable
    function postOpenBounty(
        string memory name,
        string memory description,
        uint8 available,
        uint amount,
        uint48 deadline,
        address _bountyResolver
        ) public{
            
            //make sure numLeft > 0

            if (users[msg.sender]==0){
                users[msg.sender] = uint32(userList.length);
                userList.push(msg.sender);
            }
            
            address bCAddress;
            if (freeBC.length>0){
                bCAddress = bCList[freeBC[freeBC.length-1]];
                freeBC.length--;
            } else{
                bountyChest C = new bountyChest();
                bCAddress = address(C);
                bountyChests[bCAddress] = uint32(bCList.length);
                bCList.push(bCAddress);
            }

            ubounties[numUbounties].creatorIndex = users[msg.sender];
            ubounties[numUbounties].available = available;
            ubounties[numUbounties].name = name;
            ubounties[numUbounties].description = description;
            ubounties[numUbounties].bountyChestIndex = bountyChests[bCAddress];
            ubounties[numUbounties].bountyResolver=_bountyResolver;
            if(deadline==0){
                ubounties[numUbounties].deadline = 2**48-1;
            } else {
               ubounties[numUbounties].deadline = deadline;
            }
            
           // conditionManager.createCondition(_agreementID, _bountyResolver);
            ERC20(devcash).transferFrom(msg.sender,bCAddress,amount);
            ERC20(devcash).transferFrom(msg.sender,admin,fee);
            emit created(numUbounties++,amount,available);
    }

    //add numLeft
    function postPersonalBounty(
        string memory name,
        string memory description,
        address hunter,
        uint available,
        uint amount,
        uint48 deadline,
        address _bountyResolver
        ) public{

            if (users[msg.sender]==0){
                users[msg.sender] = uint32(userList.length);
                userList.push(msg.sender);
            }

            if(users[hunter]==0){
                users[hunter] = uint32(userList.length);
                userList.push(hunter);
            }

            address bCAddress;
            if (freeBC.length>0){
                bCAddress = bCList[freeBC[freeBC.length-1]];
                freeBC.length--;
            } else{
                bountyChest C = new bountyChest();
                bCAddress = address(C);
                bountyChests[bCAddress] = uint32(bCList.length);
                bCList.push(bCAddress);
            }
    // create a new struct and assign it, looks cleaner
    
            ubounties[numUbounties].creatorIndex = users[msg.sender];
            ubounties[numUbounties].hunterIndex = users[hunter];
            ubounties[numUbounties].available = 1;
            ubounties[numUbounties].name = name;
            ubounties[numUbounties].description = description;
           
            ubounties[numUbounties].bountyResolver=_bountyResolver;
           // ubounties[numUbounties].agreementID = _agreementID;
            if(deadline==0){
                ubounties[numUbounties].deadline = 2**48-1;
            } else {
               ubounties[numUbounties].deadline = deadline;
            }
            
            ERC20(devcash).transferFrom(msg.sender,bCAddress,amount);
            ERC20(devcash).transferFrom(msg.sender,admin,fee);
            emit created(numUbounties++,amount,available);
    }
    
    function award(uint ubountyIndex, address hunter) public{
        
        require(users[msg.sender]==ubounties[ubountyIndex].creatorIndex,"You are not the bounty publisher");
       
        require(ubounties[ubountyIndex].available>0,"This bounty is inactive");
        require(ubounties[ubountyIndex].hunterIndex==0,"Only works for Open Bounties");
        
        uint rewardAmount = bountyAmount(ubountyIndex)/ubounties[ubountyIndex].available--;
        emit rewarded(ubountyIndex,hunter,rewardAmount);
        
        ERC20(devcash).transferFrom(bCList[ubounties[ubountyIndex].bountyChestIndex],hunter,rewardAmount);

        if(ubounties[ubountyIndex].available==0){
            freeBC.push(ubounties[ubountyIndex].bountyChestIndex);
            ubounties[ubountyIndex].deadline=0;
        }
    }
    
 
    
    function submit(uint ubountyIndex, string memory submissionString,bytes32 _agreementID) public {
        require(ubounties[ubountyIndex].hunterIndex==0 || msg.sender==userList[ubounties[ubountyIndex].hunterIndex],"You are not the bounty hunter");
        require(now<=ubounties[ubountyIndex].deadline,"The bounty deadline has passed");
        require(ubounties[ubountyIndex].available>0,"This bounty is inactive");  //make sure available is more than 0 
        
         if(users[msg.sender]==0){
            users[msg.sender] = uint32(userList.length);
            userList.push(msg.sender);
        }
            
        ubounties[ubountyIndex].submissions[ubounties[ubountyIndex].numSubmissions].submissionString = submissionString;
        ubounties[ubountyIndex].submissions[ubounties[ubountyIndex].numSubmissions].submitterIndex = users[msg.sender];
        //ubounties[ubountyIndex].submissions[ubounties[ubountyIndex].numSubmissions].bountyResolver=_bountyResolver;
        ubounties[ubountyIndex].submissions[ubounties[ubountyIndex].numSubmissions].agreementID=_agreementID;
        if(ubounties[ubountyIndex].bountyResolver!=address(0)){
            conditionManager.createCondition(_agreementID,  ubounties[ubountyIndex].bountyResolver);
        }
        
        emit submitted(ubountyIndex,ubounties[ubountyIndex].numSubmissions++);
            
    }
    
    function revise(uint ubountyIndex, uint32 submissionIndex, string memory revisionString) public {
        require(msg.sender==userList[ubounties[ubountyIndex].submissions[submissionIndex].submitterIndex],"You are not the submitter");
        require(now<=ubounties[ubountyIndex].deadline,"The bounty deadline has passed");
        require(ubounties[ubountyIndex].available>0,"This bounty is inactive");  //make sure available is more than 0 
        
        uint8 numRevisions = ubounties[ubountyIndex].submissions[submissionIndex].numRevisions;
        ubounties[ubountyIndex].submissions[submissionIndex].revisions[numRevisions] = revision(numRevisions,revisionString);
        emit revised(ubountyIndex,submissionIndex,numRevisions);
        ubounties[ubountyIndex].submissions[submissionIndex].numRevisions++;

    }
 
    
    function approve(uint ubountyIndex,uint submissionIndex,string memory feedback) public {
        if( ubounties[ubountyIndex].bountyResolver==address(0) ){
            require(users[msg.sender]==ubounties[ubountyIndex].creatorIndex,"You are not the bounty publisher");
        }
        else{
            require(conditionManager.getConditionState( ubounties[ubountyIndex].submissions[ubounties[ubountyIndex].numSubmissions].agreementID)==Icondition.ConditionState.Fulfilled);
        }
        require(ubounties[ubountyIndex].available>0,"This bounty is inactive");
        require(ubounties[ubountyIndex].submissions[submissionIndex].approved!=true,"submission already approved");

        emit approved(ubountyIndex, submissionIndex, feedback);
        ubounties[ubountyIndex].submissions[submissionIndex].approved=true;
        address hunter = userList[ubounties[ubountyIndex].submissions[submissionIndex].submitterIndex];
        reward(ubountyIndex,hunter);
    }
    
    function reject(uint ubountyIndex,uint submissionIndex,string memory feedback) public{
        require(users[msg.sender]==ubounties[ubountyIndex].creatorIndex,"You are not the bounty publisher");
        require(ubounties[ubountyIndex].available>0,"This bounty is inactive");

        emit rejected(ubountyIndex, submissionIndex, feedback);
    }
    
    function requestRevision(uint ubountyIndex,uint submissionIndex,string memory feedback) public {
        require(users[msg.sender]==ubounties[ubountyIndex].creatorIndex,"You are not the bounty publisher");
        
        emit revisionRequested(ubountyIndex,submissionIndex,feedback);
    }
    
    function reward(uint ubountyIndex, address hunter) internal {
        
        uint rewardAmount = bountyAmount(ubountyIndex)/ubounties[ubountyIndex].available--;

        emit rewarded(ubountyIndex,hunter,rewardAmount);
        
        ERC20(devcash).transferFrom(bCList[ubounties[ubountyIndex].bountyChestIndex],hunter,rewardAmount);

        if(ubounties[ubountyIndex].available==0){
            freeBC.push(ubounties[ubountyIndex].bountyChestIndex);
            ubounties[ubountyIndex].deadline=0;
        }
    }

    function bountyAmount(uint ubountyIndex) public view returns(uint){

        return( ERC20(devcash).balanceOf(bCList[ubounties[ubountyIndex].bountyChestIndex]) );

    }
    
//make bounty optionally reclaimable?
    function reclaim(uint ubountyIndex) public {
        require(users[msg.sender]==ubounties[ubountyIndex].creatorIndex,"You are not the bounty creator");
        require(now>ubounties[ubountyIndex].deadline||ubounties[ubountyIndex].deadline==2**48-1,"The bounty deadline has not yet elapsed");
        require(ubounties[ubountyIndex].bountyChestIndex!=0,"This bounty is inactive");

        emit reclaimed(ubountyIndex,bountyAmount(ubountyIndex));

        ERC20(devcash).transferFrom( bCList[ubounties[ubountyIndex].bountyChestIndex],msg.sender,bountyAmount(ubountyIndex) );

        freeBC.push( ubounties[ubountyIndex].bountyChestIndex );
        ubounties[ubountyIndex].bountyChestIndex=0;
        ubounties[ubountyIndex].deadline=0;
        ubounties[ubountyIndex].available = 0;
    }

    function createBountyChest() public {
        bountyChest C = new bountyChest();
        address bCAddress = address(C);
        bountyChests[bCAddress] = uint32(bCList.length);
        freeBC.push(bCList.length);
        bCList.push(bCAddress);
    }

    function setFee(uint _fee) public {
        require(admin==msg.sender);
        emit feeChange(fee,_fee);

        fee = _fee;
    }
}
