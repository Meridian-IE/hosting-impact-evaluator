// SPDX-License-Identifier: (MIT or Apache-2.0)

pragma solidity ^0.8.19;

contract Spark {
  bytes32 public constant FREQUENCY_HOURLY = keccak256("FREQUENCY_HOURLY");
  bytes32 public constant FREQUENCY_DAILY = keccak256("FREQUENCY_DAILY");

  function schedule(string memory multiaddr, bytes32 frequency) public {
    // TODO: Schedule retrieval testing
    // TODO: Perform retrieval testing
  }

  function onResult(
    address account,
    string memory multiaddr,
    bool retrievable
  ) private {
		(bool success,) = account.call(abi.encodeWithSignature(
      "sparkCallback(string, bool)",
      multiaddr,
      retrievable
    ));
  }
}
