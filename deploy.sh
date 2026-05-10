#!/usr/bin/env bash
set -euo pipefail

# ─── Load env ────────────────────────────────────────────────────────────────
if [ -f .env ]; then
  # shellcheck disable=SC2046
  export $(grep -v '^#' .env | xargs)
fi

# ─── Config ──────────────────────────────────────────────────────────────────
SCRIPT="DeployEcoReceiptNFT"
CONTRACT="EcoReceiptNFT"
CONTRACT_SRC="src/${CONTRACT}.sol"
CHAIN_ID="${CHAIN_ID:-10143}"
RPC_URL="${MONAD_TESTNET_RPC_URL:?Please set MONAD_TESTNET_RPC_URL in .env}"
PRIVATE_KEY="${PRIVATE_KEY:?Please set PRIVATE_KEY in .env}"
VERIFIER_URL="${VERIFIER_URL:-https://sourcify-api-monad.blockvision.org}"

# ─── Deploy ──────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║         Deploying ${CONTRACT}          ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  RPC     : ${RPC_URL}"
echo "  Chain   : ${CHAIN_ID}"
echo ""
forge clean && forge build
forge script "${SCRIPT}" \
  --rpc-url "${RPC_URL}" \
  --private-key "${PRIVATE_KEY}" \
  --broadcast \
  -vvv

# ─── Read deployed address from broadcast ────────────────────────────────────
BROADCAST_FILE="broadcast/${SCRIPT}.s.sol/${CHAIN_ID}/run-latest.json"
if [ ! -f "${BROADCAST_FILE}" ]; then
  echo "❌  Broadcast file not found: ${BROADCAST_FILE}"
  exit 1
fi

CONTRACT_ADDRESS=$(jq -r '
  .transactions[]
  | select(.contractName == "'"${CONTRACT}"'" and .transactionType == "CREATE")
  | .contractAddress
' "${BROADCAST_FILE}")

if [ -z "${CONTRACT_ADDRESS}" ] || [ "${CONTRACT_ADDRESS}" = "null" ]; then
  echo "❌  Could not parse deployed address from broadcast."
  exit 1
fi

echo ""
echo "✅  Deployed at: ${CONTRACT_ADDRESS}"
echo ""

# ─── Verify ──────────────────────────────────────────────────────────────────
echo "╔══════════════════════════════════════════════╗"
echo "║            Verifying Contract                ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  Verifier : ${VERIFIER_URL}"
echo ""

# Unset ETHERSCAN_API_KEY so forge does not override --verifier sourcify
unset ETHERSCAN_API_KEY

forge verify-contract "${CONTRACT_ADDRESS}" \
  "${CONTRACT_SRC}:${CONTRACT}" \
  --rpc-url "${RPC_URL}" \
  --verifier sourcify \
  --verifier-url "${VERIFIER_URL}"

echo ""
echo "🎉  All done!"
echo "    Contract : ${CONTRACT}"
echo "    Address  : ${CONTRACT_ADDRESS}"
echo "    Chain ID : ${CHAIN_ID}"
echo ""
