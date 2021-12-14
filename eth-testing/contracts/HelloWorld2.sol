//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../hyperverse/IHyperverseModule.sol";
import "./HelloWorld.sol";
import "./@openzeppelin/contracts/utils/Counters.sol";

contract HelloWorld2 is IHyperverseModule, HelloWorld {
    // Compilation error: Trying to override non-virtual function. Did you forget to add "virtual"?
    function changeGreeting(bytes memory newGreeting) external override {
        // ...
    }

    // Totally fine
    function _changeGreeting(bytes memory newGreeting) internal override {
        // ...
    }
}
