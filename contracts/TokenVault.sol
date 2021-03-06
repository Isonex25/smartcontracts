pragma solidity ^0.4.20;

import "./ERC20Interface.sol";

contract TokenVault {

    ERC20Interface public IsonexContract;
    address beneficiary;
    uint256 public fundingEndBlock;


    bool private initClaim = false; // state tracking variables

    uint256 public firstRelease; // vesting times
    uint256 public secondRelease;
    uint256 public thirdRelease;
    uint256 public fourthRelease;

    modifier atStage(Stages _stage) {
        if(stage == _stage) _;
    }

    Stages public stage = Stages.initClaim;

    enum Stages {
        initClaim,
        firstRelease,
        secondRelease,
        thirdRelease,
        fourthRelease
    }

    function TokenVault(address _contractAddress, uint256 fundingEndBlockInput) public {
        require(_contractAddress != address(0));
        IsonexContract = ERC20Interface(_contractAddress);
        beneficiary = msg.sender;
        fundingEndBlock = fundingEndBlockInput;
    }

    function changeBeneficiary(address newBeneficiary) external {
        require(newBeneficiary != address(0));
        require(msg.sender == beneficiary);
        beneficiary = newBeneficiary;
    }

    function updateFundingEndBlock(uint256 newFundingEndBlock) external {
        require(msg.sender == beneficiary);
        require(block.number < fundingEndBlock);
        require(block.number < newFundingEndBlock);
        fundingEndBlock = newFundingEndBlock;
    }

    function checkBalance() public constant returns (uint256 tokenBalance) {
        return IsonexContract.balanceOf(this);
    }

    function claim() external {
        require(msg.sender == beneficiary);
        require(block.number > fundingEndBlock);
        uint256 balance = IsonexContract.balanceOf(this);
        // in reverse order so stages changes don't carry within one claim
        fourth_release(balance);
        third_release(balance);
        second_release(balance);
        first_release(balance);
        init_claim(balance);
    }

    function nextStage() private {
        stage = Stages(uint256(stage) + 1);
    }

    function init_claim(uint256 balance) private atStage(Stages.initClaim) {
        firstRelease = now + 26 weeks; // assign 4 claiming times
        secondRelease = firstRelease + 26 weeks;
        thirdRelease = secondRelease + 26 weeks;
        fourthRelease = thirdRelease + 26 weeks;
        uint256 amountToTransfer = safeMul(balance, 53846153846) / 100000000000;
        IsonexContract.transfer(beneficiary, amountToTransfer); // now 46.153846154% tokens left
        nextStage();
    }

    function first_release(uint256 balance) private atStage(Stages.firstRelease) {
        require(now > firstRelease);
        uint256 amountToTransfer = balance / 4;
        IsonexContract.transfer(beneficiary, amountToTransfer); // send 25 % of team releases
        nextStage();
    }

    function second_release(uint256 balance) private atStage(Stages.secondRelease) {
        require(now > secondRelease);
        uint256 amountToTransfer = balance / 3;
        IsonexContract.transfer(beneficiary, amountToTransfer); // send 25 % of team releases
        nextStage();
    }

    function third_release(uint256 balance) private atStage(Stages.thirdRelease) {
        require(now > thirdRelease);
        uint256 amountToTransfer = balance / 2;
        IsonexContract.transfer(beneficiary, amountToTransfer); // send 25 % of team releases
        nextStage();
    }
    
    function fourth_release(uint256 balance) private atStage(Stages.fourthRelease) {
        require(now > fourthRelease);
        IsonexContract.transfer(beneficiary, balance); // send remaining 25 % of team releases
    }

    function claimOtherTokens(address _token) external {
        require(msg.sender == beneficiary);
        require(_token != address(0));
        ERC20Interface token = ERC20Interface(_token);
        require(token != IsonexContract);
        uint256 balance = token.balanceOf(this);
        token.transfer(beneficiary, balance);
    }

    function safeMul(uint a, uint b) pure internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
}