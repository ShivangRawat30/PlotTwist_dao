// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {PlotTwistToken} from "./PlotTwistToken.sol";

contract PlotTwistDAO {
    error PlotTwistDAO__InsufficientAmount();
    error PlotTwistDAO__Mintfailed();
    error PlotTwistDAO__NotSubscribed();
    error PlotTwistDAO__TransferFailed();
    error PlotTwistDAO__NotSufficientTokens();
    error PlotTwist__VotingNotStartedYet();
    error PlotTwist__VotingHasEnded();
    error PlotTwistDAO__VotingTimeNotEnded();
    error PlotTwistDAO__ProposalIsNotActive();

    enum SubTier {
        None,
        Silver,
        Gold,
        Diamond
    }

    enum Vote {
        None,
        upvote,
        downvote
    }

    enum ProposalStatus {
        Pending,
        Added,
        Active,
        Passed,
        Failed,
        Canceled
    }

    struct buyerStruct {
        string name;
        SubTier tier;
        uint256 endingTime;
        uint256 TokenAmount;
    }

    struct voteStruct {
        address voter;
        Vote vote;
        uint256 numberOfVotes;
    }

    struct proposalStruct {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 executionTime;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVotes;
        ProposalStatus status;
    }

    PlotTwistToken private i_btt;
    uint256 private s_totalProposal = 0;
    address private immutable i_owner;
    uint256 private constant SILVER_AMOUNT = 0.003 * 1e18;
    uint256 private constant GOLD_AMOUNT = 0.007 * 1e18;
    uint256 private constant DIAMOND_AMOUNT = 0.01 * 1e18;
    uint256 private constant USER_SUB_DURATION = 60 * 60 * 24 * 30; // 30 days
    uint256 private constant VOTING_START_TIME = 24 * 60 * 60; // 1 day
    uint256 private constant VOTING_ENDING_TIME = 24 * 60 * 60 * 3; // 3 days
    uint256 private constant PROPOSAL_COST = 5 * 1e18;
    uint256 private constant TOTAL_FOR_VOTES = 10;
    uint256 private constant TOTAL_AGAINST_VOTES = 5;
    uint256 private constant TOTAL_VOTES = 10;

    mapping(address owner => buyerStruct) private s_buyInfo;
    mapping(uint256 id => proposalStruct) private s_proposals;
    mapping(uint256 id => mapping(address => voteStruct)) private s_votes;

    event UpvoteAProposal(address voter, uint256 tokenAmount, uint256 proposalId);
    event DownvoteAProposal(address voter, uint256 tokenAmount, uint256 proposalId);

    //////////////////
    /// FUNCTIONS ///
    /////////////////
    constructor(address pttAddress) {
        i_btt = PlotTwistToken(pttAddress);
        i_owner = msg.sender;
    }

    function createOwner(string memory name) external payable {
        if (msg.value == DIAMOND_AMOUNT) {
            uint256 mintAmount = 100 ether;
            s_buyInfo[msg.sender] = buyerStruct({
                name: name,
                tier: SubTier.Diamond,
                endingTime: currentTime() + USER_SUB_DURATION,
                TokenAmount: 0
            });
            _mintPtt(msg.sender, mintAmount);
        } else if (msg.value == GOLD_AMOUNT) {
            uint256 mintAmount = 50 ether;
            s_buyInfo[msg.sender] = buyerStruct({
                name: name,
                tier: SubTier.Gold,
                endingTime: currentTime() + USER_SUB_DURATION,
                TokenAmount: 0
            });
            _mintPtt(msg.sender, mintAmount);
        } else if (msg.value == SILVER_AMOUNT) {
            uint256 mintAmount = 20 ether;
            s_buyInfo[msg.sender] = buyerStruct({
                name: name,
                tier: SubTier.Silver,
                endingTime: currentTime() + USER_SUB_DURATION,
                TokenAmount: 0
            });
            _mintPtt(msg.sender, mintAmount);
        } else {
            revert PlotTwistDAO__InsufficientAmount();
        }
    }

    function createProposal(string memory _title, string memory _description) external {
        if (s_buyInfo[msg.sender].endingTime == 0) {
            revert PlotTwistDAO__NotSubscribed();
        }
        s_totalProposal++;
        s_proposals[s_totalProposal] = proposalStruct({
            id: s_totalProposal,
            proposer: msg.sender,
            title: _title,
            description: _description,
            executionTime: currentTime(),
            votingStartTime: currentTime() + VOTING_START_TIME,
            votingEndTime: currentTime() + VOTING_ENDING_TIME,
            votesFor: 0,
            votesAgainst: 0,
            totalVotes: 0,
            status: ProposalStatus.Added
        });
        s_buyInfo[msg.sender].TokenAmount -= PROPOSAL_COST;
        bool success = i_btt.transferFrom(msg.sender, address(this), PROPOSAL_COST);
        if (!success) {
            revert PlotTwistDAO__Mintfailed();
        }
        i_btt.burn(PROPOSAL_COST);
    }

    function upvote(uint256 _proposalId) external {
        if (s_buyInfo[msg.sender].endingTime == 0) {
            revert PlotTwistDAO__NotSubscribed();
        }
        if (currentTime() < s_proposals[_proposalId].votingStartTime) {
            revert PlotTwist__VotingNotStartedYet();
        }
        if (currentTime() > s_proposals[_proposalId].votingEndTime) {
            revert PlotTwist__VotingHasEnded();
        }
        if (s_buyInfo[msg.sender].tier == SubTier.Diamond && s_buyInfo[msg.sender].TokenAmount > 3 ether) {
            _upvote(3 ether, _proposalId, msg.sender);
        } else if (s_buyInfo[msg.sender].tier == SubTier.Gold && s_buyInfo[msg.sender].TokenAmount > 2 ether) {
            _upvote(2 ether, _proposalId, msg.sender);
        } else if (s_buyInfo[msg.sender].tier == SubTier.Silver && s_buyInfo[msg.sender].TokenAmount > 1 ether) {
            _upvote(1 ether, _proposalId, msg.sender);
        } else {
            revert PlotTwistDAO__NotSufficientTokens();
        }
    }

    function downvote(uint256 _proposalId) external {
        if (s_buyInfo[msg.sender].endingTime == 0) {
            revert PlotTwistDAO__NotSubscribed();
        }
        if (currentTime() < s_proposals[_proposalId].votingStartTime) {
            revert PlotTwist__VotingNotStartedYet();
        }
        if (currentTime() > s_proposals[_proposalId].votingEndTime) {
            revert PlotTwist__VotingHasEnded();
        }
        if (s_buyInfo[msg.sender].tier == SubTier.Diamond && s_buyInfo[msg.sender].TokenAmount > 3 ether) {
            _downvote(3 ether, _proposalId, msg.sender);
        } else if (s_buyInfo[msg.sender].tier == SubTier.Gold && s_buyInfo[msg.sender].TokenAmount > 2 ether) {
            _downvote(2 ether, _proposalId, msg.sender);
        } else if (s_buyInfo[msg.sender].tier == SubTier.Silver && s_buyInfo[msg.sender].TokenAmount > 1 ether) {
            _downvote(1 ether, _proposalId, msg.sender);
        } else {
            revert PlotTwistDAO__NotSufficientTokens();
        }
    }

    function endProposal(uint256 _proposalId) external {
        if (currentTime() < s_proposals[_proposalId].votingEndTime) {
            revert PlotTwistDAO__VotingTimeNotEnded();
        }
        if (s_proposals[_proposalId].totalVotes > TOTAL_VOTES) {
            if (s_proposals[_proposalId].votesFor > TOTAL_FOR_VOTES) {
                s_proposals[_proposalId].status = ProposalStatus.Active;
            } else {
                s_proposals[_proposalId].status = ProposalStatus.Failed;
            }
        } else {
            s_proposals[_proposalId].status = ProposalStatus.Canceled;
        }
    }

    function actProposal(uint256 _proposalId) external {
        if (s_proposals[_proposalId].status != ProposalStatus.Active) {
            revert PlotTwistDAO__ProposalIsNotActive();
        }
        s_proposals[_proposalId].status = ProposalStatus.Passed;
    }

    function _downvote(uint256 tokenAmount, uint256 _proposalId, address voter) internal {
        uint256 voteAmount = tokenAmount / 1 ether;
        s_votes[_proposalId][voter] = voteStruct({voter: voter, vote: Vote.downvote, numberOfVotes: voteAmount});
        s_proposals[_proposalId].votesAgainst += voteAmount;
        s_proposals[_proposalId].totalVotes += voteAmount;

        s_buyInfo[voter].TokenAmount -= tokenAmount;
        bool success = i_btt.transferFrom(voter, address(this), tokenAmount);
        if (!success) {
            revert PlotTwistDAO__Mintfailed();
        }
        i_btt.burn(tokenAmount);

        emit DownvoteAProposal(voter, tokenAmount, _proposalId);
    }

    function _upvote(uint256 tokenAmount, uint256 _proposalId, address voter) internal {
        uint256 voteAmount = tokenAmount / 1 ether;
        s_votes[_proposalId][voter] = voteStruct({voter: voter, vote: Vote.upvote, numberOfVotes: voteAmount});
        s_proposals[_proposalId].votesFor += voteAmount;
        s_proposals[_proposalId].totalVotes += voteAmount;

        s_buyInfo[voter].TokenAmount -= tokenAmount;
        bool success = i_btt.transferFrom(voter, address(this), tokenAmount);
        if (!success) {
            revert PlotTwistDAO__Mintfailed();
        }
        i_btt.burn(tokenAmount);

        emit UpvoteAProposal(voter, tokenAmount, _proposalId);
    }

    function _mintPtt(address to, uint256 mintAmount) internal {
        s_buyInfo[to].TokenAmount += mintAmount;
        bool minted = i_btt.mint(to, mintAmount);

        if (!minted) {
            revert PlotTwistDAO__Mintfailed();
        }
    }

    function currentTime() public view returns (uint256) {
        return block.timestamp;
    }

    function getTokenAddress() external view returns (address) {
        return address(i_btt);
    }

    function getBuyerInfo(address owner) external view returns (buyerStruct memory) {
        return s_buyInfo[owner];
    }

    function getBuyerName(address owner) external view returns (string memory) {
        return s_buyInfo[owner].name;
    }

    function getBuyerTier(address owner) external view returns (SubTier) {
        return s_buyInfo[owner].tier;
    }

    function getBuyerTokenAmount(address owner) external view returns (uint256) {
        return s_buyInfo[owner].TokenAmount;
    }

    function getBuyerEndingTime(address owner) external view returns (uint256) {
        return s_buyInfo[owner].endingTime;
    }

    function getTotalProposal() external view returns (uint256) {
        return s_totalProposal;
    }

    function getProposalInfo(uint256 _id) external view returns (proposalStruct memory) {
        return s_proposals[_id];
    }

    function getProposalId(uint256 _id) external view returns (uint256) {
        return s_proposals[_id].id;
    }

    function getPropsalOwner(uint256 _id) external view returns (address) {
        return s_proposals[_id].proposer;
    }

    function getProposalTitle(uint256 _id) external view returns (string memory) {
        return s_proposals[_id].title;
    }

    function getProposalDescription(uint256 _id) external view returns (string memory) {
        return s_proposals[_id].description;
    }

    function getProposalExecutionTime(uint256 _id) external view returns (uint256) {
        return s_proposals[_id].executionTime;
    }

    function getProposalVotingStartTime(uint256 _id) external view returns (uint256) {
        return s_proposals[_id].votingStartTime;
    }

    function getProposalVotingEndTime(uint256 _id) external view returns (uint256) {
        return s_proposals[_id].votingEndTime;
    }

    function getProposalVotesFor(uint256 _id) external view returns (uint256) {
        return s_proposals[_id].votesFor;
    }

    function getProposalVotesAgainst(uint256 _id) external view returns (uint256) {
        return s_proposals[_id].votesAgainst;
    }

    function getProposalTotalVotes(uint256 _id) external view returns (uint256) {
        return s_proposals[_id].totalVotes;
    }

    function getProposalStatus(uint256 _id) external view returns (ProposalStatus) {
        return s_proposals[_id].status;
    }

    function getVoter(uint256 id, address voter) external view returns (address) {
        return s_votes[id][voter].voter;
    }

    function getVote(uint256 id, address voter) external view returns (Vote) {
        return s_votes[id][voter].vote;
    }

    function getNumberOfVotes(uint256 id, address voter) external view returns (uint256) {
        return s_votes[id][voter].numberOfVotes;
    }
}
