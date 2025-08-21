import { ethers, upgrades } from "hardhat";

async function main() {
  // --- 1. Get the contract factory ---
  const FlowClicker = await ethers.getContractFactory("FlowClicker");

  // --- 2. Define initializer arguments ---
  // IMPORTANT: Replace these with your actual desired addresses before deploying!
  const initialOwner = (await ethers.getSigners())[0].address;
  const devWallet = "0x633a628C72018B3D0805222d91b2a9014B8a9A67";
  const foundationWallet = "0x9b71551B6203f01Da5aF02Ce3d748eDd53E6Bd75";

  // --- 3. Deploy the proxy ---
  console.log("Deploying FlowClicker as an upgradeable proxy...");
  const flowClickerProxy = await upgrades.deployProxy(
    FlowClicker,
    [initialOwner, devWallet, foundationWallet], // Arguments for the initializer function
    {
      initializer: "initialize", // Name of the initializer function
      kind: "uups", // Specify the proxy kind as UUPS
    }
  );

  await flowClickerProxy.waitForDeployment();

  const proxyAddress = await flowClickerProxy.getAddress();
  console.log("FlowClicker proxy deployed to:", proxyAddress);

  // --- 4. (Optional) Verify on Etherscan/Sonicscan ---
  // You can add steps here to programmatically verify the contract
  // console.log("Verification command for proxy:");
  // console.log(`npx hardhat verify ${proxyAddress} --network your_network_name`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
