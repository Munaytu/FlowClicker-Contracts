// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// --- NEW IMPORTS ---
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract FlowClicker is Initializable, ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable, EIP712Upgradeable {
    // --- State Variables ---

    // Wallets for sustainability fee distribution
    address public devWallet;
    address public foundationWallet;
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // Reward decay parameters
    uint256 public constant INITIAL_REWARD_PER_CLICK = 1 * 1e18;
    uint256 public constant FINAL_REWARD_PER_CLICK = 1 * 1e16; // 0.01 tokens
    uint256 public constant DECAY_DURATION_SECONDS = 3 * 365 days;
    uint256 public launchTime;

    // Sustainability fee percentages
    uint256 public constant DEV_FEE_BPS = 400;
    uint256 public constant FOUNDATION_FEE_BPS = 400;
    uint256 public constant BURN_FEE_BPS = 200;
    uint256 public constant TOTAL_FEE_BPS = DEV_FEE_BPS + FOUNDATION_FEE_BPS + BURN_FEE_BPS;

    // --- NEW EIP712 and Nonce Tracking ---
    // Used to prevent replay attacks. Each user has a nonce that increments with each claim.
    mapping(address => uint256) public nonces;

    // --- Events ---

    event TokensClaimed(address indexed player, uint256 amount, uint256 clicks);
    event FeesDistributed(uint256 devFee, uint256 foundationFee, uint256 burnFee);

    // --- Initializer ---

    function initialize(address initialOwner, address _devWallet, address _foundationWallet) public initializer {
        __ERC20_init("FlowClicker", "FLOW");
        __Ownable_init(initialOwner);
        __Pausable_init();
        __UUPSUpgradeable_init();
        // --- NEW --- Initialize EIP712 with the contract name and version
        __EIP712_init("FlowClicker", "1");

        require(_devWallet != address(0), "Dev wallet cannot be zero address");
        require(_foundationWallet != address(0), "Foundation wallet cannot be zero address");

        devWallet = _devWallet;
        foundationWallet = _foundationWallet;
        launchTime = block.timestamp;
    }

    // --- External Functions ---

    /**
     * @notice A player calls this to claim tokens, providing a signature from the owner (backend).
     * The player (msg.sender) pays the gas fee for this transaction.
     * @param player The address of the player receiving tokens. Must be the same as msg.sender.
     * @param clicks The number of validated clicks to claim.
     * @param signature A signature from the contract owner authorizing this claim.
     */
    function claim(address player, uint256 clicks, bytes calldata signature) external whenNotPaused {
        require(player == msg.sender, "Player must be the transaction sender");
        require(clicks > 0, "Clicks must be positive");

        // --- NEW: Signature Verification Logic ---
        uint256 nonce = nonces[player];
        bytes32 structHash = keccak256(abi.encode(
            keccak256("Claim(address player,uint256 clicks,uint256 nonce)"),
            player,
            clicks,
            nonce
        ));
        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(digest, signature);

        require(signer == owner(), "Invalid signature");
        // --- End of Signature Verification ---

        // Increment nonce to prevent replay attacks
        nonces[player]++;

        uint256 currentRewardPerClick = getCurrentReward();
        uint256 playerAmount = clicks * currentRewardPerClick;

        require(playerAmount > 0, "Reward results in zero tokens");

        _mint(player, playerAmount);
        emit TokensClaimed(player, playerAmount, clicks);

        _distributeFees(playerAmount);
    }

    // --- Public Functions ---

    function getCurrentReward() public view returns (uint256) {
        uint256 elapsedTime = block.timestamp - launchTime;
        if (elapsedTime >= DECAY_DURATION_SECONDS) {
            return FINAL_REWARD_PER_CLICK;
        }
        uint256 rewardReduction = INITIAL_REWARD_PER_CLICK - FINAL_REWARD_PER_CLICK;
        uint256 decay = (rewardReduction * elapsedTime) / DECAY_DURATION_SECONDS;
        return INITIAL_REWARD_PER_CLICK - decay;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // --- Internal Functions ---

    function _distributeFees(uint256 playerAmount) internal {
        uint256 totalFeeAmount = (playerAmount * TOTAL_FEE_BPS) / 10000;
        if (totalFeeAmount == 0) return;

        uint256 devFee = (totalFeeAmount * DEV_FEE_BPS) / TOTAL_FEE_BPS;
        uint256 foundationFee = (totalFeeAmount * FOUNDATION_FEE_BPS) / TOTAL_FEE_BPS;
        uint256 burnFee = totalFeeAmount - devFee - foundationFee;

        if (devFee > 0) _mint(devWallet, devFee);
        if (foundationFee > 0) _mint(foundationWallet, foundationFee);
        if (burnFee > 0) _mint(BURN_ADDRESS, burnFee);

        emit FeesDistributed(devFee, foundationFee, burnFee);
    }

    // --- Owner Functions ---

    /// @notice Register my contract on Sonic FeeM
    function registerMe() external onlyOwner {
        (bool _success,) = address(0xDC2B0D2Dd2b7759D97D50db4eabDC36973110830).call(
            abi.encodeWithSignature("selfRegister(uint256)", 228)
        );
        require(_success, "FeeM registration failed");
    }

    function setDevWallet(address _newDevWallet) external onlyOwner {
        require(_newDevWallet != address(0), "Dev wallet cannot be zero address");
        devWallet = _newDevWallet;
    }

    function setFoundationWallet(address _newFoundationWallet) external onlyOwner {
        require(_newFoundationWallet != address(0), "Foundation wallet cannot be zero address");
        foundationWallet = _newFoundationWallet;
    }

    // --- UUPS Upgradeability ---

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

