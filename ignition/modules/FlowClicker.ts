import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("FlowClickerModule", (m) => {
  // Get the first account as the initial owner
  const initialOwner = m.getAccount(0);

  // Placeholder addresses for devWallet and foundationWallet
  // IMPORTANT: Replace these with your actual desired addresses before deploying!
  const devWallet = "0x633a628C72018B3D0805222d91b2a9014B8a9A67";
  const foundationWallet = "0x9b71551B6203f01Da5aF02Ce3d748eDd53E6Bd75";

  const flowClicker = m.contract("FlowClicker", [initialOwner, devWallet, foundationWallet]);

  return { flowClicker };
});
