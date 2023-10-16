// SPDX-License-Identifier: (MIT or Apache-2.0)

pragma solidity ^0.8.19;
import "./Spark.sol";

// TODO: Prevent gas exhaustion attacks
// TODO: Drop participants

contract IE {
    struct Participant {
        string multiaddr;
        address payable account;
        uint successfulRetrievals;
        uint failedRetrievals;
        bool exists;
    }
    struct Score {
        Participant participant;
        uint value;
    }
    struct Round {
        uint start;
    }

    mapping(address => Participant) participants;
    address[] participantAddresses;
    Spark spark;
    Round round;
    uint roundLength = 10;
    uint roundReward = 1 ether;

    constructor(Spark _spark) {
        spark = _spark;
        advanceRound();
    }

    function advanceRound() private {
        reward(evaluate());
        round.start = block.number;
    }

    function maybeAdvanceRound() private {
        if (round.start + roundLength < block.number) {
            advanceRound();
        }
    }

    /**
     * @dev Join the network or top up your balance
     */
    function join(string memory multiaddr) public payable {
        require(msg.value > 0, "Retrieval testing funds required");

        if (!participants[msg.sender].exists) {
            participants[msg.sender] = Participant(
                multiaddr,
                payable(msg.sender),
                0,
                0,
                true
            );
            participantAddresses.push(msg.sender);
        }

        spark.schedule{value: msg.value}(
            msg.sender,
            multiaddr,
            spark.FREQUENCY_HOURLY()
        );
    }

    /**
     * @dev Spark calls this to report retrieval results
     */
    function sparkCallback(address account, bool retrievable) public {
        measure(account, retrievable);
    }

    function measure(address account, bool retrievable) private {
        Participant memory participant = participants[account];
        require(participant.exists, "Unknown participant");
        if (retrievable) {
            participant.successfulRetrievals += 1;
        } else {
            participant.failedRetrievals += 1;
        }
        maybeAdvanceRound();
    }

    function evaluate() private view returns (Score[] memory) {
        Score[] memory scores = new Score[](participantAddresses.length);
        for (uint i = 0; i < participantAddresses.length; i++) {
            Participant memory participant = participants[
                participantAddresses[i]
            ];
            uint score = participant.successfulRetrievals;
            scores[i] = Score(participant, score);
        }
        return scores;
    }

    function reward(Score[] memory scores) private {
        uint totalScores = 0;
        for (uint i = 0; i < scores.length; i++) {
            totalScores += scores[i].value;
        }
        for (uint i = 0; i < scores.length; i++) {
            Score memory score = scores[i];
            uint amount = (score.value * roundReward) / totalScores;
            require(score.participant.account.send(amount));
        }
    }
}
