// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Vote {

    struct Voter {
        string name;
        uint age;
        uint voterId;
        Gender gender;
        uint voteCandidateId; //candidate id to whom the voter has voted.
        address voterAddress;
    }

    struct Candidate {
        string name;
        string party;
        uint age;
        Gender gender;
        uint candidateId;
        address candidateAddress;
        uint votes;
    }

    address public electionCommission;
    address public winner;
    uint nextVoterId = 1;
    uint nextCandidateId = 1;

    uint startTime;
    uint endTime;
    bool stopVoting;


    mapping(uint => Voter) voterDetails;
    mapping(uint => Candidate) candidateDetails;


    enum VotingStatus {NotStarted, InProgress, Ended}
    enum Gender {NotSpecified, Male, Female, Other}


    constructor() {
        electionCommission = msg.sender; // electionCommission has the control of the contract
    }

 
    modifier isVotingOver() {
        require(block.timestamp<=endTime && stopVoting==false,"Voting is over.");
        _;
    }


    modifier onlyCommissioner() {
        require(msg.sender==electionCommission, "Unauthorized access. Only election commissioner can access this");
        _;
    }

    modifier isAgeAbove18(uint _age) {
        require(_age>=18, "You are less than 18");
        _;
    }

    function registerCandidate(
        string calldata _name,
        string calldata _party,
        uint _age,
        Gender _gender
    ) external isAgeAbove18(_age){
        require(isCandidateNotRegistered(msg.sender), "You are already registered");
        require(nextCandidateId<3,"Candidate registration full");
        require(msg.sender!=electionCommission,"Election Commission is not allowed as a candidate");
       candidateDetails[nextCandidateId] = Candidate({
            name : _name,
            party : _party,
            age : _age,
            gender : _gender,
            candidateId : nextCandidateId,
            candidateAddress : msg.sender,
            votes : 0
       });
       nextCandidateId++;
    }


    function isCandidateNotRegistered(address _person) private view returns (bool) {
        for (uint i=0; i<nextCandidateId; i++){
        if (candidateDetails[i].candidateAddress == _person) {
            return false;
        }
        }
        return true;
    }


    function getCandidateList() public view returns (Candidate[] memory) {
        Candidate[] memory candidateArray = new Candidate[](nextCandidateId-1);
        for (uint i=0; i<candidateArray.length; i++) {
            candidateArray[i] = candidateDetails[i+1];
        }
        return candidateArray;
    }


    function isVoterNotRegistered(address _person) private view returns (bool) {
         for (uint i=0; i<nextVoterId; i++) 
         {
            if (voterDetails[i].voterAddress == _person) {
                return false;
            }
         }
         return true;
    }


    function registerVoter(
        string calldata _name,
        uint _age,
        Gender _gender
    ) external isAgeAbove18(_age){
        require(isVoterNotRegistered(msg.sender),"You are already registered");
        voterDetails[nextVoterId] = Voter({
            name : _name,
            age : _age,
            voterId : nextVoterId,
            gender : _gender,
            voteCandidateId : 0, //initally no vote is casted
            voterAddress : msg.sender
        });
        nextVoterId++;
    }


    function getVoterList() public view returns (Voter[] memory) {
        Voter[] memory voterList = new Voter[](nextVoterId-1);
        for (uint i=0; i<voterList.length; i++) {
            voterList[i] = voterDetails[i+1];
        }
        return voterList;
    }


    function castVote(uint _voterId, uint _candidateId) external {
        require(voterDetails[_voterId].voteCandidateId == 0, "You have already voted");
        require(voterDetails[_voterId].voterAddress == msg.sender, "Unauthorized access");
        require(_candidateId==1 || _candidateId ==2 , "Candidate ID is invalid");
        voterDetails[_voterId].voteCandidateId = _candidateId;
        candidateDetails[_candidateId].votes += 1;
    }


    function setVotingPeriod(uint _startTimeDuration, uint _endTimeDuration) external onlyCommissioner() {
        require(_endTimeDuration>3600, "End Time Duration must be greater than 1 hour");
        startTime = block.timestamp+_startTimeDuration;
        endTime = startTime+_endTimeDuration;
    }


    function getVotingStatus() public view returns (VotingStatus) {
        if (startTime==0) {
            return VotingStatus.NotStarted;
        } else if (endTime>block.timestamp && stopVoting==false) {
            return VotingStatus.InProgress;
        } else {
            return VotingStatus.Ended;
        }
    }


    function announceVotingResult() external onlyCommissioner()  {
        require(stopVoting==true && endTime>block.timestamp,"Voting is still in progress ");
        // if (candidateDetails[1].votes > candidateDetails[2].votes) {
        //     winner = candidateDetails[1].candidateAddress;
        // } else if (candidateDetails[1].votes < candidateDetails[2].votes) {
        //     winner = candidateDetails[2].candidateAddress;
        // } else {
            
        // }
        uint max=0;
        for (uint i=1; i<nextCandidateId; i++) 
        {
            if (candidateDetails[i].votes>max) {
                max = candidateDetails[i].votes;
                winner = candidateDetails[i].candidateAddress;
            }
        }
    }


    function emergencyStopVoting() public onlyCommissioner() {
       stopVoting = true;
    }
}











