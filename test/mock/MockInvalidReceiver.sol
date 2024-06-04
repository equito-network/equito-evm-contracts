// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Errors} from "../../src/libraries/Errors.sol";

contract MockInvalidReceiver {
    receive() external payable {
        revert Errors.TransferFailed();
    }
}