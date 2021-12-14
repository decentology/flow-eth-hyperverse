//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../hyperverse/IHyperverseModule.sol";
import "./@openzeppelin/contracts/utils/Counters.sol";

contract HelloWorld is IHyperverseModule {
    address private owner;

    struct Tenant {
        bytes greeting;
    }

    mapping(address => Tenant) tenants;

    event ChangedGreeting(address tenant, bytes greeting);

    constructor() {
        metadata = ModuleMetadata(
            "HelloWorld",
            Author(
                0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
                "https://externallink.net"
            ),
            "0.0.1",
            3479831479814,
            "https://externalLink.net"
        );

        // HARDCODED ADDRESS
        owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    }

    function getState(address tenant) internal view returns (Tenant storage) {
        return tenants[tenant];
    }

    // Even if this contract gets inherited, they can't change this function.
    function pay() private {
        // pay owner...
    }

    function changeGreeting(bytes memory newGreeting) external {
        _changeGreeting(newGreeting);
        pay(); // ....
    }

    // "Hook" in Solidity
    function _changeGreeting(bytes memory newGreeting) internal virtual {
        Tenant storage state = getState(msg.sender);
        state.greeting = newGreeting;
        emit ChangedGreeting(msg.sender, newGreeting);
    }

    function greet(address tenant) external view returns (bytes memory) {
        Tenant storage state = getState(tenant);
        return state.greeting;
    }
}
