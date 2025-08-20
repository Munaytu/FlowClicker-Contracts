// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract FlowClicker is ERC20, Ownable {
    // --- State Variables ---

    // Wallets for sustainability fee distribution
    address public devWallet;
    address public foundationWallet;
    // Burn address is conventionally address(0) or a specific dead address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // Reward decay parameters
    uint256 public constant INITIAL_REWARD_PER_CLICK = 1 * 1e18; // 1 token with 18 decimals
    uint256 public constant FINAL_REWARD_PER_CLICK = 0.01 * 1e18; // 0.01 tokens
    uint256 public constant DECAY_DURATION_SECONDS = 3 * 365 days; // 3 years
    uint256 public launchTime;

    // Sustainability fee percentages (e.g., 4% is 400)
    uint256 public constant DEV_FEE_BPS = 400; // 4%
    uint256 public constant FOUNDATION_FEE_BPS = 400; // 4%
    uint256 public constant BURN_FEE_BPS = 200; // 2%
    uint256 public constant TOTAL_FEE_BPS = DEV_FEE_BPS + FOUNDATION_FEE_BPS + BURN_FEE_BPS; // 10%

    // --- Events ---
    event TokensClaimed(address indexed player, uint256 amount, uint256 clicks);
    event FeesDistributed(uint256 devFee, uint256 foundationFee, uint256 burnFee);

    // --- Constructor ---

    constructor(address initialOwner, address _devWallet, address _foundationWallet) ERC20("FlowClicker", "FLOW") Ownable(initialOwner) {
        require(_devWallet != address(0), "Dev wallet cannot be zero address");
        require(_foundationWallet != address(0), "Foundation wallet cannot be zero address");

        devWallet = _devWallet;
        foundationWallet = _foundationWallet;
        launchTime = block.timestamp;
    }

    // --- External Functions ---

    /**
     * @notice The owner (backend server) calls this to mint tokens for a player based on their clicks.
     * @param player The address of the player to receive the tokens.
     * @param clicks The number of validated clicks to claim.
     */
    function claim(address player, uint256 clicks) external onlyOwner {
        require(player != address(0), "Player address cannot be zero");
        require(clicks > 0, "Clicks must be positive");

        uint256 currentRewardPerClick = getCurrentReward();
        uint256 playerAmount = (clicks * currentRewardPerClick) / 1e18;

        require(playerAmount > 0, "Reward results in zero tokens");

        // Mint tokens for the player
        _mint(player, playerAmount);
        emit TokensClaimed(player, playerAmount, clicks);

        // Calculate and distribute sustainability fees
        _distributeFees(playerAmount);
    }

    // --- Public Functions ---

    /**
     * @notice Calculates the current reward per click based on a linear decay.
     * @return The amount of tokens (with 18 decimals) per click.
     */
    function getCurrentReward() public view returns (uint256) {
        uint256 elapsedTime = block.timestamp - launchTime;

        if (elapsedTime >= DECAY_DURATION_SECONDS) {
            return FINAL_REWARD_PER_CLICK;
        }

        // Linear interpolation
        uint256 rewardReduction = INITIAL_REWARD_PER_CLICK - FINAL_REWARD_PER_CLICK;
        uint256 decay = (rewardReduction * elapsedTime) / DECAY_DURATION_SECONDS;
        
        return INITIAL_REWARD_PER_CLICK - decay;
    }

    // --- Internal Functions ---

    /**
     * @notice Calculates and mints the sustainability fees.
     * @param playerAmount The amount of tokens minted for the player.
     */
    function _distributeFees(uint256 playerAmount) internal {
        uint256 totalFeeAmount = (playerAmount * TOTAL_FEE_BPS) / 10000;

        if (totalFeeAmount == 0) {
            return;
        }

        uint256 devFee = (totalFeeAmount * DEV_FEE_BPS) / TOTAL_FEE_BPS;
        uint256 foundationFee = (totalFeeAmount * FOUNDATION_FEE_BPS) / TOTAL_FEE_BPS;
        uint256 burnFee = totalFeeAmount - devFee - foundationFee; // Remainder to burn

        if (devFee > 0) {
            _mint(devWallet, devFee);
        }
        if (foundationFee > 0) {
            _mint(foundationWallet, foundationFee);
        }
        if (burnFee > 0) {
            _mint(BURN_ADDRESS, burnFee);
        }

        emit FeesDistributed(devFee, foundationFee, burnFee);
    }

    // --- Owner Functions ---

    /**
     * @notice Allows the owner to update the dev wallet address.
     */
    function setDevWallet(address _newDevWallet) external onlyOwner {
        require(_newDevWallet != address(0), "Dev wallet cannot be zero address");
        devWallet = _newDevWallet;
    }

    /**
     * @notice Allows the owner to update the foundation wallet address.
     */
    function setFoundationWallet(address _newFoundationWallet) external onlyOwner {
        require(_newFoundationWallet != address(0), "Foundation wallet cannot be zero address");
        foundationWallet = _newFoundationWallet;
    }
}
