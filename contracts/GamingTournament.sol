// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract GamingContest is AccessControl {

    // Struct to hold participant's data
    struct Gamer {
        address user;
        uint256 scores;
    }

    // Struct to hold tournament's data
    struct Tournament {
        uint256 id;
        uint256 lobbySize;
        uint256 startTime;
        uint256 endTime;
    }
    
    // Mapping of tournament ID to an array of participants in that tournament
    mapping(uint => Gamer[]) private  Participants;
    // Array to hold all tournaments
    Tournament[] public tournaments;
    // Entry fee for the tournament
    uint constant public ENTRY_FEE = 0.2 ether; 
    //Admin
    address public owner;
    // Duration of a tournament
    uint public constant _duration = 300; 
    //ADMIN_ROLE Access Controller
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    // Events
        event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event TournamentCreated(uint256 Tournamentid, uint256 lobbySize);
    event UserAdded(uint256 tournamentId, address user);
    event TournamentStarted(uint256 tournamentId);
    event WinnersAnnounced(uint256 tournamentId,address winner,address runner,address third);

    // Constructor that grants the  admin role to the contract deployer
    constructor() {
        _setupRole(ADMIN_ROLE, msg.sender);
        owner = msg.sender;

    }

    // Modifier that checks if a user can join a tournament
    modifier TournamentJoin(uint256 _tournamentId) {
        // Get the tournament data
        Tournament memory tournament = tournaments[_tournamentId - 1];
        // Check if the tournament has not started and is not full
        require(tournament.startTime == 0, "Tournament is already started!");
        require(Participants[_tournamentId].length < tournament.lobbySize, "Tournament is full");
        // Check if the user is not already a participant
        Gamer[] memory users = Participants[_tournamentId];
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].user == msg.sender) {
                revert("You are already joined!");
            }
        }
        _;
    }

    // Modifier that checks if a score can be added to a participant's data
    modifier calculateScore(uint256 _tournamentId) {
        // Get the tournament data
        Tournament memory tournament = tournaments[_tournamentId - 1];
        // Check if the tournament has started and has not ended
        require(tournament.startTime != 0, "Tournament is not started yet!");
        require(block.timestamp < tournament.endTime, "Tournament is already ended!");
        _;
    }
    
    // Function to Transfer the ownership to others
    function transferOwnership(address newOwner)
        external
        onlyRole(ADMIN_ROLE)
        returns (bool)
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _revokeRole(ADMIN_ROLE, owner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        _setupRole(ADMIN_ROLE, newOwner);
        return true;
    }

    // Function to add  the tournament scores by the individuals only by admin
    function addScore(uint256 _tournamentId, address _user, uint _score) public calculateScore(_tournamentId) onlyRole(ADMIN_ROLE) returns(bool _done) {
        Gamer[] memory user = Participants[_tournamentId];
   
        for (uint256 i = 0; i < user.length; i++) {
            if (user[i].user == _user) {
                Participants[_tournamentId][i].scores = user[i].scores + _score;
                return(true);
            }
        }
    }
    
    // Airdrop tokens to the winner(s) of a tournament
    function announceWinner(uint256 _tournamentId) public onlyRole(ADMIN_ROLE) {
        // Get the leaderboard for the tournament
        Gamer[] memory leaderboard = getLeaderboard(_tournamentId);

        // Only distribute rewards if there is at least one participant
        require(leaderboard.length > 0, "No participants in tournament");

        // Get the total amount of ether to distribute
        uint256 totalEther = address(this).balance;

        // Calculate the amounts to distribute to each winner
        uint256 firstPlacePrize = totalEther * 60 / 100;
        uint256 secondPlacePrize = totalEther * 30 / 100;
        uint256 thirdPlacePrize = totalEther * 10 / 100;

        // Distribute ether to the top 3 players
        for (uint256 i = 0; i < leaderboard.length && i < 3; i++) {
            address payable winner = payable(leaderboard[i].user);
            if (i == 0) {
                // First place winner receives 60% of the total prize
                winner.transfer(firstPlacePrize);
            } else if (i == 1) {
                // Second place winner receives 30% of the total prize
                winner.transfer(secondPlacePrize);
            } else {
                // Third place winner receives 10% of the total prize
                winner.transfer(thirdPlacePrize);
            }
        }

        // Emit an event to announce the winners
        emit WinnersAnnounced(_tournamentId, leaderboard[0].user, leaderboard[1].user, leaderboard[2].user);
    }


    // Function to join the tournament 
    function joinTournament(uint256 _tournamentId) public payable  TournamentJoin(_tournamentId) returns(bool) {
        Tournament memory tournament = tournaments[_tournamentId - 1];
        require(msg.value == ENTRY_FEE, "Entry fee is required");
        Participants[_tournamentId].push(Gamer(msg.sender, 0));

        emit UserAdded(_tournamentId, msg.sender);

        if (Participants[_tournamentId].length == tournament.lobbySize) {
            tournament.startTime = block.timestamp;
            tournament.endTime = block.timestamp + _duration;
            tournaments[_tournamentId - 1] = tournament;
            emit TournamentStarted(_tournamentId);
        }

        return true;
    }

    // Function to shortlist the participants
    function shortlistParticipants(Gamer[] memory _participants) private pure returns (Gamer[] memory) {
        for (uint256 i = 0; i < _participants.length - 1; i++) {
            for (uint256 j = i + 1; j < _participants.length; j++) {
                if (_participants[i].scores < _participants[j].scores) {
                    uint256 tempScore = _participants[i].scores;
                    address tempAddress = _participants[i].user;
                    _participants[i].scores = _participants[j].scores;
                    _participants[i].user = _participants[j].user;
                    _participants[i].scores = tempScore;
                    _participants[j].user = tempAddress;
                }
            }
        }
        return _participants;
    }

        // Function to get all active tournaments
    function getActiveTournaments() public view returns (Tournament[] memory) {
       // Count the number of active tournaments
        uint256 count = 0;

        for (uint256 i = 0; i < tournaments.length; i++) {

            if (tournaments[i].startTime == 0 && tournaments[i].endTime == 0) {
                count++;
            }

        }
        // Create an array of active tournaments
        Tournament[] memory activeTournaments= new Tournament[](count);

        uint256 index = 0;
        
        for (uint256 i = 0; i < tournaments.length; i++) {
            if (tournaments[i].startTime == 0 && tournaments[i].endTime == 0) {
                activeTournaments[index] = tournaments[i];
                index++;
            }
        }
        return activeTournaments;
    }

    // Function to get all participants of a tournament
    function getParticipants(uint _tournamentId) public view returns(Gamer[] memory) {
        Gamer[] memory participants = Participants[_tournamentId];
        return participants;
    }
    // Function to create a new tournament
    function createTournament(uint256 _lobbySize ) public onlyRole(ADMIN_ROLE) {
        require(_lobbySize >=3 , "lobbySize must be greater than or equal to 3");
        // Create a new tournament with a unique ID
        uint256 id = tournaments.length + 1;
        tournaments.push(Tournament(id, _lobbySize, 0, 0));
        emit TournamentCreated(id, _lobbySize);
    }
    // Function to get tournament data by _tournamentId
    function getTournament(uint256 _tournamentId) public view returns(Tournament memory) {
        Tournament memory tournament = tournaments[_tournamentId - 1];
        return tournament;
    }
    // Function to get Leaderboard data by _tournamentId
    function getLeaderboard(uint256 _tournamentId) public view returns(Gamer[] memory) {
        Tournament memory tournament = tournaments[_tournamentId - 1];
        require(block.timestamp > tournament.endTime && tournament.endTime != 0, "Tournament has not ended yet");
        Gamer[] memory shortedlistParticipants = shortlistParticipants(Participants[_tournamentId]);
        return shortedlistParticipants;
    }    
}