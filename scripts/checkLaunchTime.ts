// scripts/checkLaunchTime.ts
import { ethers } from "hardhat";

async function main() {
  const contractAddress = "0xe66d1bf6d2ebaD7b16B940e7cfA83473582001b0";
  const flowClicker = await ethers.getContractAt("FlowClicker", contractAddress);

  const launchTime = await flowClicker.launchTime();

  console.log("launchTime:", launchTime.toString());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
