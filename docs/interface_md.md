# EcoReceiptNFT 合约对外接口文档

- **合约名称**：`EcoReceiptNFT`
- **代币标准**：ERC-721（`ERC721URIStorage`）
- **代币名称 / Symbol**：`Eco Receipt NFT` / `ERN`
- **网络**：Monad Testnet（Chain ID: 10143）

---

## 数据结构

### `EcoReceipt`

链上存储的环保收据摘要，通过 `getReceipt` 返回。

| 字段 | 类型 | 说明 |
|---|---|---|
| `tokenId` | `uint256` | NFT ID（从 1 自增） |
| `productName` | `string` | 产品名称 |
| `brand` | `string` | 品牌名称 |
| `score` | `uint8` | 环保评分（0–100） |
| `grade` | `string` | 等级标签（如 `"A+"`） |
| `reportHash` | `bytes32` | 完整报告的 keccak256 哈希，用于链下验证 |
| `evidenceMerkleRoot` | `bytes32` | 证据集合的 Merkle Root，用于链下验证 |
| `metadataURI` | `string` | NFT metadata 的 URI（IPFS / HTTPS） |
| `timestamp` | `uint256` | 铸造时的区块时间戳（Unix 秒） |
| `creator` | `address` | 收据接收方（NFT 持有人） |
| `auditor` | `address` | 执行铸造的审计员地址 |

---

## 写入函数

### `mintReceipt`

铸造一枚环保收据 NFT。

```solidity
function mintReceipt(
    address to,
    string memory productName,
    string memory brand,
    uint8 score,
    string memory grade,
    bytes32 reportHash,
    bytes32 evidenceMerkleRoot,
    string memory metadataURI
) external returns (uint256 tokenId)
```

**权限**：仅 Owner 或已授权的 Auditor 可调用。

| 参数 | 类型 | 说明 |
|---|---|---|
| `to` | `address` | NFT 接收地址（不可为零地址） |
| `productName` | `string` | 产品名称 |
| `brand` | `string` | 品牌名称 |
| `score` | `uint8` | 环保评分，必须 ≤ 100 |
| `grade` | `string` | 等级标签 |
| `reportHash` | `bytes32` | 报告哈希，不可为零值 |
| `evidenceMerkleRoot` | `bytes32` | 证据 Merkle Root，不可为零值 |
| `metadataURI` | `string` | metadata URI，不可为空字符串 |

**返回值**：新铸造的 `tokenId`。

**触发事件**：[`ReceiptMinted`](#receiptminted)

**可能 revert**：

| 错误 | 触发条件 |
|---|---|
| `InvalidRecipient()` | `to` 为零地址 |
| `InvalidScore(score)` | `score > 100` |
| `EmptyReportHash()` | `reportHash == bytes32(0)` |
| `EmptyEvidenceMerkleRoot()` | `evidenceMerkleRoot == bytes32(0)` |
| `EmptyMetadataURI()` | `metadataURI` 为空字符串 |
| `UnauthorizedMinter(account)` | 调用者既非 Owner 也非 Auditor |

---

### `addAuditor`

授予某地址铸造权限。

```solidity
function addAuditor(address auditor) external
```

**权限**：仅 Owner。

**触发事件**：[`AuditorAdded`](#auditoradded)

**可能 revert**：`ZeroAddressAuditor()` — `auditor` 为零地址。

---

### `removeAuditor`

撤销某地址的铸造权限。

```solidity
function removeAuditor(address auditor) external
```

**权限**：仅 Owner。

**触发事件**：[`AuditorRemoved`](#auditorremoved)

**可能 revert**：`ZeroAddressAuditor()` — `auditor` 为零地址。

---

## 只读函数

### `getReceipt`

查询某 tokenId 对应的完整链上收据数据。

```solidity
function getReceipt(uint256 tokenId) external view returns (EcoReceipt memory)
```

**可能 revert**：`NonexistentToken(tokenId)` — token 不存在。

---

### `isAuditor`

查询某地址是否具有铸造权限。

```solidity
function isAuditor(address account) public view returns (bool)
```

---

### `exists`

查询某 tokenId 是否已铸造且未销毁。

```solidity
function exists(uint256 tokenId) public view returns (bool)
```

---

### ERC-721 标准只读函数（继承）

| 函数 | 说明 |
|---|---|
| `ownerOf(tokenId)` | 查询 token 持有人 |
| `tokenURI(tokenId)` | 查询 metadata URI |
| `balanceOf(owner)` | 查询某地址持有数量 |
| `getApproved(tokenId)` | 查询单个 token 的授权地址 |
| `isApprovedForAll(owner, operator)` | 查询全量授权状态 |
| `supportsInterface(interfaceId)` | ERC-165 接口检测 |

---

## 事件

### `ReceiptMinted`

每次成功铸造时触发。

```solidity
event ReceiptMinted(
    uint256 indexed tokenId,
    address indexed creator,
    address indexed auditor,
    string productName,
    string brand,
    uint8 score,
    string grade,
    bytes32 reportHash,
    bytes32 evidenceMerkleRoot,
    string metadataURI
)
```

### `AuditorAdded`

```solidity
event AuditorAdded(address indexed auditor)
```

### `AuditorRemoved`

```solidity
event AuditorRemoved(address indexed auditor)
```

---

## 自定义错误

| 错误 | 说明 |
|---|---|
| `UnauthorizedMinter(address account)` | 无铸造权限 |
| `InvalidRecipient()` | 接收方为零地址 |
| `InvalidScore(uint8 score)` | 评分超出 100 |
| `EmptyReportHash()` | reportHash 为零值 |
| `EmptyEvidenceMerkleRoot()` | evidenceMerkleRoot 为零值 |
| `EmptyMetadataURI()` | metadataURI 为空 |
| `NonexistentToken(uint256 tokenId)` | token 不存在 |
| `ZeroAddressAuditor()` | Auditor 地址为零地址 |

---

## 权限模型

```
Owner（合约部署者）
  ├── addAuditor / removeAuditor   — 管理审计员名单
  └── mintReceipt                  — 可直接铸造

Auditor（Owner 授权的地址）
  └── mintReceipt                  — 铸造收据 NFT

其他地址
  └── 只读操作（getReceipt / isAuditor / ERC-721 查询等）
```
