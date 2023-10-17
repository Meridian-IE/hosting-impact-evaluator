// SPDX-License-Identifier: (MIT or Apache-2.0)

pragma solidity ^0.8.19;

contract Spark {
    bytes32 public constant FREQUENCY_HOURLY = keccak256("FREQUENCY_HOURLY");
    bytes32 public constant FREQUENCY_DAILY = keccak256("FREQUENCY_DAILY");

    function schedule(
        address account,
        string memory multiaddr,
        bytes32 frequency
    ) public payable {
        // TODO: Schedule retrieval testing
        // TODO: Perform retrieval testing
    }

    // This assumes the full Spark protocol has been executed, including fraud detection.
    // The result is the outcome of the committee process, and not an individual node's
    // test.
    function onResult(
        address account,
        bool retrievable
    ) private {
        (bool success, ) = account.call(
            abi.encodeWithSignature(
                "sparkCallback(string, bool)",
                account,
                retrievable
            )
        );
        require(success);
    }
}
