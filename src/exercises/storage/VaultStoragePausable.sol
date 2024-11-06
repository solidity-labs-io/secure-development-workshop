pragma solidity 0.8.25;

import {PausableUpgradeable} from
    "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {OwnableUpgradeable} from
    "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {Supply} from "src/exercises/storage/Supply.sol";
import {Balances} from "src/exercises/storage/Balances.sol";
import {Authorized} from "src/exercises/storage/Authorized.sol";

contract VaultStoragePausable is
    OwnableUpgradeable,
    Supply,
    Balances,
    PausableUpgradeable,
    Authorized
{}