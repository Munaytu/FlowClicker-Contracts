import { expect } from "chai";
import { ethers, network } from "hardhat";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { FlowClicker } from "../typechain-types";

describe("FlowClicker", function () {
    let flowClicker: FlowClicker;
    let owner: HardhatEthersSigner, player: HardhatEthersSigner, dev: HardhatEthersSigner, foundation: HardhatEthersSigner, other: HardhatEthersSigner;

    const BURN_ADDRESS = "0x000000000000000000000000000000000000dEaD";

    beforeEach(async function () {
        [owner, player, dev, foundation, other] = await ethers.getSigners();

        const FlowClickerFactory = await ethers.getContractFactory("FlowClicker");
        flowClicker = await FlowClickerFactory.deploy(owner.address, dev.address, foundation.address);
        await flowClicker.waitForDeployment();
    });

    describe("Deployment", function () {
        it("Should set the right owner", async function () {
            expect(await flowClicker.owner()).to.equal(owner.address);
        });

        it("Should set the correct token name and symbol", async function () {
            expect(await flowClicker.name()).to.equal("FlowClicker");
            expect(await flowClicker.symbol()).to.equal("FLOW");
        });

        it("Should set the correct dev and foundation wallets", async function () {
            expect(await flowClicker.devWallet()).to.equal(dev.address);
            expect(await flowClicker.foundationWallet()).to.equal(foundation.address);
        });
    });

    describe("Claiming Tokens", function () {
        it("Should only allow the owner to claim tokens", async function () {
            await expect(flowClicker.connect(other).claim(player.address, 100))
                .to.be.revertedWithCustomError(flowClicker, 'OwnableUnauthorizedAccount');
        });

        it("Should revert if claiming for zero address", async function () {
            await expect(flowClicker.claim(ethers.ZeroAddress, 100))
                .to.be.revertedWith("Player address cannot be zero");
        });

        it("Should revert if claiming zero clicks", async function () {
            await expect(flowClicker.claim(player.address, 0))
                .to.be.revertedWith("Clicks must be positive");
        });

        it("Should mint tokens to the player and distribute fees correctly", async function () {
            const clicks = 1000;
            const initialReward = await flowClicker.INITIAL_REWARD_PER_CLICK();
            const expectedPlayerAmount = (BigInt(clicks) * initialReward) / BigInt(1e18);

            await flowClicker.claim(player.address, clicks);

            const playerBalance = await flowClicker.balanceOf(player.address);
            expect(playerBalance).to.equal(expectedPlayerAmount);

            const totalFee = (expectedPlayerAmount * BigInt(1000)) / BigInt(10000); // 10% total fee
            const devFee = (totalFee * BigInt(400)) / BigInt(1000); // 4% of total
            const foundationFee = (totalFee * BigInt(400)) / BigInt(1000); // 4% of total
            const burnFee = totalFee - devFee - foundationFee;

            const devBalance = await flowClicker.balanceOf(dev.address);
            const foundationBalance = await flowClicker.balanceOf(foundation.address);
            const burnBalance = await flowClicker.balanceOf(BURN_ADDRESS);

            expect(devBalance).to.equal(devFee);
            expect(foundationBalance).to.equal(foundationFee);
            expect(burnBalance).to.equal(burnFee);
        });
    });

    describe("Reward Decay", function () {
        it("Should return the initial reward at launch time", async function () {
            const initialReward = await flowClicker.INITIAL_REWARD_PER_CLICK();
            expect(await flowClicker.getCurrentReward()).to.equal(initialReward);
        });

        it("Should decrease the reward over time", async function () {
            const initialReward = await flowClicker.getCurrentReward();

            const oneYearInSeconds = 365 * 24 * 60 * 60;
            await time.increase(oneYearInSeconds);

            const rewardAfterOneYear = await flowClicker.getCurrentReward();
            expect(rewardAfterOneYear).to.be.lessThan(initialReward);
        });

        it("Should return the final reward after the decay period", async function () {
            const decayDuration = await flowClicker.DECAY_DURATION_SECONDS();
            await time.increase(decayDuration);

            const finalReward = await flowClicker.FINAL_REWARD_PER_CLICK();
            expect(await flowClicker.getCurrentReward()).to.equal(finalReward);
        });

         it("Should not decrease reward below final reward", async function () {
            const decayDuration = await flowClicker.DECAY_DURATION_SECONDS();
            await time.increase(Number(decayDuration) + (365 * 24 * 60 * 60)); // Increase time beyond decay period

            const finalReward = await flowClicker.FINAL_REWARD_PER_CLICK();
            expect(await flowClicker.getCurrentReward()).to.equal(finalReward);
        });
    });

    describe("Wallet Management", function () {
        it("Should allow the owner to set a new dev wallet", async function () {
            await flowClicker.setDevWallet(other.address);
            expect(await flowClicker.devWallet()).to.equal(other.address);
        });

        it("Should prevent non-owners from setting the dev wallet", async function () {
             await expect(flowClicker.connect(other).setDevWallet(other.address))
                .to.be.revertedWithCustomError(flowClicker, 'OwnableUnauthorizedAccount');
        });

        it("Should allow the owner to set a new foundation wallet", async function () {
            await flowClicker.setFoundationWallet(other.address);
            expect(await flowClicker.foundationWallet()).to.equal(other.address);
        });

        it("Should prevent non-owners from setting the foundation wallet", async function () {
            await expect(flowClicker.connect(other).setFoundationWallet(other.address))
                .to.be.revertedWithCustomError(flowClicker, 'OwnableUnauthorizedAccount');
        });
    });
});
