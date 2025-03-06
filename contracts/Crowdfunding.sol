pragma solidity ^0.8.0;
// SPDX-License-Identifier: UNLICENSED

contract Crowdfunding {
    string public name;
    string public description;
    uint256 public goal;
    uint256 public deadline;
    address public owner;
    bool public paused;

    enum CampaignState { Active, Successful, Failed }
    CampaignState public state;

    struct Tier {
        string name;
        uint256 amount;
        uint256 backers;
    }

    struct Backer {
        uint256 totalContribution;
        mapping(uint256 => bool) fundedTiers;
    }

    Tier[] public tiers;
    mapping(address => Backer) public backers;

    modifier onlyOwner() {
        require(msg.sender == owner, "Anda bukan Owner");
        _;
    }

    modifier campaignOpen() {
        require(state == CampaignState.Active, "Campaign Tidak Aktif");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }
    
    modifier pausedOnly() {
        require(paused == true, "Contract is not paused.");
        _;
    }

    constructor(
        address _owner,
        string memory _name,
        string memory _description,
        uint256 _goal,
        uint256 _durationInDays
    ) {
        name = _name;
        description = _description;
        goal = _goal;
        deadline = block.timestamp + (_durationInDays * 1 days);
        owner = _owner;
        state = CampaignState.Active;
    }
    function CheckAndUpdateCampaignState() internal {
        if(state == CampaignState.Active) {
            if(block.timestamp >= deadline) {
                state = address(this).balance >= goal ? CampaignState.Successful : CampaignState.Failed;
            } else {
                state = address(this).balance >= goal ? CampaignState.Successful : CampaignState.Active;
            }
        }
        
    }

    function fund (uint256 _tierIndex) public payable campaignOpen notPaused  {
        require(_tierIndex < tiers.length, "Tier tidak valid");
        require(msg.value == tiers[_tierIndex].amount, "Nominal tidak tepat");

        tiers[_tierIndex].backers++;
        backers[msg.sender].totalContribution += msg.value;
        backers[msg.sender].fundedTiers[_tierIndex] = true;

        CheckAndUpdateCampaignState();
    }

    function addTier(
        string memory _name,
        uint256 _amount
    ) public onlyOwner{
        require(_amount > 0, "Nominalnya harus lebih dari 0");
        tiers.push(Tier(_name, _amount, 0));

    }

    function removeTier(uint256 _index) public onlyOwner {
        require(_index < tiers.length, "Tier tidak ada");
        tiers[_index] = tiers[tiers.length-1];
        tiers.pop();
    }

    function withdraw() public onlyOwner {
        CheckAndUpdateCampaignState();
        require(state == CampaignState.Successful, "Campaign gagal");

        uint256 balance = address(this).balance;
        require(balance > 0, "Tidak ada dana yang bisa di withdraw");
        payable(owner).transfer(balance);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function refund() public {
        CheckAndUpdateCampaignState();
       require(state == CampaignState.Failed, "Refunds Tidak tersedia");
        uint256 amount = backers[msg.sender].totalContribution;
        require(amount > 0, "Tidak ada kontribusi untuk di refund");

        backers[msg.sender].totalContribution = 0;
        payable (msg.sender).transfer(amount);
    }
    function hasFundedTier(address _backer, uint256 _tierIndex) public view returns (bool) {
        return backers[_backer].fundedTiers[_tierIndex];

    }

    function getTiers() public view returns (Tier[] memory){
    return tiers;
    }

    function tooglePause() public onlyOwner {
        paused = !paused;
    }

    function getCampaignStatus() public view returns (CampaignState) {
        if (state == CampaignState.Active && block.timestamp > deadline) {
            return address(this).balance >= goal ? CampaignState.Successful : CampaignState.Failed;
        }
        return state;
    }

    function extendDeadline(uint256 _daysToAdd) public onlyOwner campaignOpen {
        deadline += _daysToAdd * 1 days;
    }
}
