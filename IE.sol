// SPDX-License-Identifier: UNLICENSED 

pragma solidity ^0.8.19;
import "./Spark.sol";

contract IE {
  struct Participant {
    string multiaddr;
    address payable account;
  }

  mapping(string => Participant) participants;
  Spark spark;

  constructor (Spark _spark) {
    spark = _spark;
  }

  /**
   * @dev Join the network or top up your balance
   */
  function join(string memory multiaddr) public {
    // TODO: Do we need to keep track of participants?
    require(msg.value > 0, "Retrieval testing funds required");
    require(multiaddr != "", "Invalid multiaddr");

    if (participants[multiaddr].multiaddr != multiaddr) {
			participants[multiaddr] = Participant(multiaddr, msg.sender);
		}

    spark.schedule{ value: msg.value }(multiaddr, spark.FREQUENCY_HOURLY());
  }

  /**
   * @dev Spark calls this to report retrieval results
   */
  function sparkCallback(string memory multiaddr, bool retrievable) public {
    measure(multiaddr, retrievable);
  }

  function measure(string memory multiaddr, bool retrievable) private {
    Participant participant = participants[multiaddr];
    require(participant.multiaddr == multiaddr, "Unknown participant");
    if (retrievable) {
      // TODO: Pay out in rounds instead
      participant.account.send(0.1 ether);
    }
  }
  
  function evaluate() private {
    // TODO
  }

  function reward() private {
    // TODO
  }
}
