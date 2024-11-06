pragma solidity 0.8.25;

import {OwnableUpgradeable} from
    "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20Metadata} from
    "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from
    "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Vault03Storage} from "src/exercises/03/Vault03Storage.sol";

contract Vault03 is Vault03Storage {
    using SafeERC20 for IERC20;

    /// @notice Deposit event
    /// @param token The token deposited
    /// @param sender The address that deposited the token
    /// @param amount The amount deposited
    event Deposit(
        address indexed token, address indexed sender, uint256 amount
    );

    /// @notice Withdraw event
    /// @param token The token withdrawn
    /// @param sender The address that withdrew the token
    /// @param amount The amount withdrawn
    event Withdraw(
        address indexed token, address indexed sender, uint256 amount
    );

    event TokenAdded(address indexed token);

    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the vault with a list of authorized tokens
    /// @param _tokens The list of authorized tokens
    /// @param _owner The owner address to set for the contract
    function initialize(address[] memory _tokens, address _owner)
        external
        initializer
    {
        __Ownable_init(_owner);

        for (uint256 i = 0; i < _tokens.length; i++) {
            require(
                IERC20Metadata(_tokens[i]).decimals() <= 18,
                "Vault: unsupported decimals"
            );

            authorizedToken[_tokens[i]] = true;

            emit TokenAdded(_tokens[i]);
        }
    }

    /// -------------------------------------------------------------
    /// -------------------------------------------------------------
    /// -------------------- ONLY OWNER FUNCTION --------------------
    /// -------------------------------------------------------------
    /// -------------------------------------------------------------

    /// @notice Add a token to the list of authorized tokens
    /// only callable by the owner
    /// @param token to add
    function addToken(address token) external onlyOwner {
        require(
            IERC20Metadata(token).decimals() <= 18,
            "Vault: unsupported decimals"
        );
        require(
            !authorizedToken[token], "Vault: token already authorized"
        );

        authorizedToken[token] = true;

        emit TokenAdded(token);
    }

    /// -------------------------------------------------------------
    /// -------------------------------------------------------------
    /// ----------------- PUBLIC MUTATIVE FUNCTIONS -----------------
    /// -------------------------------------------------------------
    /// -------------------------------------------------------------

    /// @notice Deposit tokens into the vault
    /// @param token The token to deposit, only authorized tokens allowed
    /// @param amount The amount to deposit
    function deposit(address token, uint256 amount) external {
        require(authorizedToken[token], "Vault: token not authorized");

        uint256 normalizedAmount = getNormalizedAmount(token, amount);

        /// save on gas by using unchecked, no need to check for overflow
        /// as all deposited tokens are whitelisted
        unchecked {
            balanceOf[msg.sender] += normalizedAmount;
        }

        totalSupplied += normalizedAmount;

        IERC20(token).safeTransferFrom(
            msg.sender, address(this), amount
        );

        emit Deposit(token, msg.sender, amount);
    }

    /// @notice Withdraw tokens from the vault
    /// @param token The token to withdraw, only authorized tokens are allowed
    /// this is implicitly checked because a user can only have a balance of an
    /// authorized token
    /// @param amount The amount to withdraw
    function withdraw(address token, uint256 amount) external {
        require(authorizedToken[token], "Vault: token not authorized");

        uint256 normalizedAmount = getNormalizedAmount(token, amount);

        /// both a check and an effect, ensures user has sufficient funds for
        /// withdrawal
        /// must be checked for underflow as a user can only withdraw what they
        /// have deposited
        balanceOf[msg.sender] -= normalizedAmount;

        /// save on gas by using unchecked, no need to check for underflow
        /// as all deposited tokens are whitelisted, plus we know our invariant
        /// always holds
        unchecked {
            totalSupplied -= normalizedAmount;
        }

        IERC20(token).safeTransfer(msg.sender, amount);

        emit Withdraw(token, msg.sender, amount);
    }

    /// --------------------------------------------------------
    /// --------------------------------------------------------
    /// ----------------- PUBLIC VIEW FUNCTION -----------------
    /// --------------------------------------------------------
    /// --------------------------------------------------------

    /// @notice public for testing purposes, returns the normalized amount of
    /// tokens scaled to 18 decimals
    /// @param token The token to deposit
    /// @param amount The amount to deposit
    function getNormalizedAmount(address token, uint256 amount)
        public
        view
        returns (uint256 normalizedAmount)
    {
        uint8 decimals = IERC20Metadata(token).decimals();
        normalizedAmount = amount;
        if (decimals < 18) {
            normalizedAmount = amount * (10 ** (18 - decimals));
        }
    }
}
