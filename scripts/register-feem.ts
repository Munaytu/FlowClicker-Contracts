import { ethers } from "hardhat";

async function main() {
  // The address of your deployed FlowClicker proxy contract
  const proxyAddress = "0x404E7Ede0Bbc428217E8B04011c0A72F4cB74a7F";

  console.log(`Connecting to FlowClicker contract at: ${proxyAddress}`);

  // Get the contract factory
  const FlowClicker = await ethers.getContractFactory("FlowClicker");

  // Attach the factory to the deployed contract instance
  const flowClicker = FlowClicker.attach(proxyAddress);

  // Get the signer (owner)
  const [signer] = await ethers.getSigners();
  console.log(`Calling 'registerMe' from account: ${signer.address}`);

  // Call the registerMe function
  // This will send a transaction to the blockchain
  console.log("Sending transaction to call 'registerMe()'...");
  const tx = await flowClicker.connect(signer).registerMe();

  // Wait for the transaction to be mined
  console.log(`Transaction sent. Waiting for confirmation... (Tx hash: ${tx.hash})`);
  await tx.wait();

  console.log("✅ Transaction confirmed!");
  console.log("Your contract should now be registered with Sonic FeeM.");
}

main().catch((error) => {
  console.error("An error occurred:", error);
  process.exitCode = 1;
});
