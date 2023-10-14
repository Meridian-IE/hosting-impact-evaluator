// SPDX-License-Identifier: (MIT or Apache-2.0)

pragma solidity ^0.8.19;
import "./Spark.sol";

// TODO: Write this as a pure on-chain IE, without external storage, since we're
// not needing a lot of participants. Otoh, this requires participant management
// to prevent uncontrolled growth.

contract IE {
    struct Participant {
        string multiaddr;
        address payable account;
    }

    mapping(string => Participant) participants;
    Spark spark;

    constructor(Spark _spark) {
        spark = _spark;
    }

    /**
     * @dev Join the network or top up your balance
     */
    function join(string memory multiaddr) public payable {
        // TODO: Do we need to keep track of participants?
        require(msg.value > 0, "Retrieval testing funds required");
        require(stringsEqual(multiaddr, ""), "Invalid multiaddr");

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
        // TODO: Accumulate this data in rounds storage
        if (retrievable) {
            // TODO: Pay out in rounds instead
            require(participant.account.send(0.1 ether));
        }
    }

    function evaluate() private {
        // TODO
    }

    function reward() private {
        // TODO
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
