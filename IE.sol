// SPDX-License-Identifier: (MIT or Apache-2.0)

pragma solidity ^0.8.19;
import "./Spark.sol";

// TODO: Prevent gas exhaustion attacks

contract IE {
    struct Participant {
        string multiaddr;
        address payable account;
    }
    struct Measurement {
        Participant participant;
        bool retrievable;
    }
    struct Score {
        Participant participant;
        uint value;
    }
    struct Round {
        uint start;
        Measurement[] measurements;
        Participant[] participants;
    }

    mapping(string => Participant) participants;
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
        delete round.measurements;
        delete round.participants;
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

        if (!stringsEqual(participants[multiaddr].multiaddr, multiaddr)) {
            participants[multiaddr] = Participant(
                multiaddr,
                payable(msg.sender)
            );
        }

        spark.schedule{value: msg.value}(multiaddr, spark.FREQUENCY_HOURLY());
    }

    /**
     * @dev Spark calls this to report retrieval results
     */
    function sparkCallback(string memory multiaddr, bool retrievable) public {
        measure(multiaddr, retrievable);
    }

    function measure(string memory multiaddr, bool retrievable) private {
        Participant memory participant = participants[multiaddr];
        require(
            stringsEqual(participant.multiaddr, multiaddr),
            "Unknown participant"
        );
        round.measurements.push(Measurement(participant, retrievable));
        maybeAdvanceRound();
    }

    function evaluate() private view returns (Score[] memory) {
        Score[] memory scores = new Score[](round.participants.length);
        for (uint i = 0; i < round.participants.length; i++) {
            Participant memory participant = round.participants[i];
            uint value = 0;
            for (uint j = 0; j < round.measurements.length; j++) {
                Measurement memory measurement = round.measurements[j];
                if (
                    stringsEqual(
                        measurement.participant.multiaddr,
                        participant.multiaddr
                    )
                ) {
                    if (measurement.retrievable) {
                        value += 1;
                    } else {
                        value -= 1;
                    }
                }
            }
            scores[i] = Score(participant, value);
        }
        return scores;
    }

    function reward(Score[] memory scores) private {
        uint totalScores = 0;
        for (uint i = 0; i < scores.length; i++) {
            totalScores += scores[i].value;
        }
        for (uint i = 0; i < scores.length; i++) {
            Participant memory participant = scores[i].participant;
            uint value = scores[i].value;
            uint amount = (value * roundReward) / totalScores;
            require(participant.account.send(amount));
        }
    }

    function stringsEqual(
        string memory a,
        string memory b
    ) public pure returns (bool) {
        if (bytes(a).length != bytes(b).length) {
            return false;
        }
        return (keccak256(abi.encodePacked(a)) ==
            keccak256(abi.encodePacked(b)));
    }
}
