# Eco Receipt Contracts

Eco Receipt 是一个 Monad 黑客松项目的合约部分。用户输入商品名称后，AI 后端会基于公开证据生成一份环保鉴定报告 `Green Receipt`，报告包含商品名称、品牌、环保评分、风险等级、证据来源、AI 推论和替代商品建议等内容。

合约不会把完整报告和证据全文写入链上。链上 NFT 只作为公开凭证，保存报告哈希、证据 Merkle Root、摘要字段和 metadata URI。

## 合约设计方案

核心合约为 `GreenReceiptNFT`：

- 继承 OpenZeppelin `ERC721URIStorage`，每份报告 mint 成一个 NFT。
- 继承 OpenZeppelin `Ownable`，由 owner 管理 auditor。
- 只有 owner 或授权 auditor 可以 mint。
- `tokenId` 从 `1` 开始自动递增。
- `score` 必须在 `0` 到 `100` 之间。
- `reportHash`、`evidenceMerkleRoot`、`metadataURI` 不能为空。
- `getReceipt(tokenId)` 可查询链上保存的报告摘要。
- `exists(tokenId)` 可检查 NFT 是否存在。

每个 NFT 保存的 `GreenReceipt` 摘要字段：

```solidity
struct GreenReceipt {
    uint256 tokenId;
    string productName;
    string brand;
    uint8 score;
    string grade;
    bytes32 reportHash;
    bytes32 evidenceMerkleRoot;
    string metadataURI;
    uint256 timestamp;
    address creator;
    address auditor;
}
```

字段含义：

- `productName`：商品名称，例如 `Nike Pegasus Trail 5 DV3865-602`。
- `brand`：品牌名。
- `score`：环保评分，范围 `0-100`。
- `grade`：等级或风险标签，例如 `A`、`B`、`High Risk`。
- `reportHash`：完整 report JSON 的 hash。
- `evidenceMerkleRoot`：多个 evidence hash 构建出的 Merkle Root。
- `metadataURI`：指向 NFT metadata、IPFS、Arweave 或后端报告地址。
- `timestamp`：mint 时间。
- `creator`：NFT 接收者，也可以理解为报告持有人。
- `auditor`：执行 mint 的 owner 或授权 auditor。

## 项目结构

```text
src/GreenReceiptNFT.sol              主合约
test/GreenReceiptNFT.t.sol           Foundry 测试
script/DeployGreenReceiptNFT.s.sol   部署脚本
remappings.txt                       OpenZeppelin import 映射
```

默认 Foundry 生成的 `Counter` 示例文件目前仍保留，可以后续删除。

## 安装依赖

本项目需要 OpenZeppelin Contracts：

```bash
forge install OpenZeppelin/openzeppelin-contracts
```

Windows 环境如果 `forge` 只在 Git Bash 中可用，请在 Git Bash 中执行 Foundry 命令。

## 运行测试

```bash
forge test
```

## 部署到 Monad

Monad 是 EVM 兼容链，因此可以按标准 Foundry 部署流程执行。

```bash
export PRIVATE_KEY=0x...
export MONAD_RPC_URL=https://...

forge script script/DeployGreenReceiptNFT.s.sol:DeployGreenReceiptNFT \
  --rpc-url $MONAD_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```

## 后端 Mint 流程

1. 后端生成完整 `Green Receipt` JSON。
2. 对完整 JSON 计算 hash，得到 `reportHash`。
3. 对每条 evidence 分别计算 hash。
4. 用 evidence hash 构建 Merkle Tree，得到 `evidenceMerkleRoot`。
5. 将完整报告或 NFT metadata 上传到 IPFS、Arweave 或后端数据库。
6. owner 或授权 auditor 调用 `mintReceipt`。
7. 用户获得一个 Green Receipt NFT，作为环保鉴定报告的链上公开凭证。

示例：

```solidity
greenReceiptNFT.mintReceipt(
    user,
    "Nike Pegasus Trail 5 DV3865-602",
    "Nike",
    82,
    "B",
    reportHash,
    evidenceMerkleRoot,
    "ipfs://bafy..."
);
```

## 安全说明

- 不上链完整报告或原始 evidence，避免隐私、成本和存储膨胀问题。
- 链上只保存可验证的 hash、Merkle Root 和摘要字段。
- mint 权限由 owner 管理 auditor，适合 MVP 阶段控制数据质量。
- 后续可以扩展用户付费 mint、报告更新版本、Merkle proof 校验等功能。
