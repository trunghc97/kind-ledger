# Blockchain Flow & Data Consistency - KindLedger

## 1. Mục tiêu
- Chuẩn hóa luồng tương tác với Hyperledger Fabric.
- Định nghĩa dữ liệu ledger lưu vào MongoDB phục vụ Explorer (read-only, bất biến).
- Hướng dẫn truy vấn đảm bảo tính nhất quán, không thể chỉnh sửa ngoài chuỗi khối.

## 2. Luồng Giao dịch Chính

### 2.1 Deposit/Mint (Gateway → Fabric)
1) Gateway nhận request `/api/v1/deposit` với `accountNumber`, `amount`, `walletAddress`.
2) Gateway submit transaction đến Peer MBBank: `Mint(walletAddress, amount)` trên chaincode `cvnd-token` (channel `kindchannel`).
3) Fabric xác nhận và ghi block; phát `ContractEvent` (ví dụ `Mint`) kèm payload.
4) Gateway trả về `txId` thực.

### 2.2 Explorer Sync (Fabric → Mongo)
- Explorer đăng ký block listener, mỗi block mới:
  - Upsert vào `blocks` (theo `number`).
  - Ghi các giao dịch vào `transactions_ledger`.
  - Ghi sự kiện chaincode vào `chaincode_events`.
- Ghi idempotent, chỉ append, không cập nhật/xóa.

## 3. Cấu trúc Dữ liệu Ledger trong MongoDB

### 3.1 blocks
```javascript
{
  number: Number,           // unique
  blockHash: String,
  previousHash: String,
  transactionCount: Number,
  ts: Date
}
// Index: { number: 1 } unique
```

### 3.2 transactions_ledger
```javascript
{
  txId: String,             // unique
  status: String,           // e.g. VALID
  validationCode: Number,
  chaincodeId: String,      // cvnd-token
  blockNumber: Number
}
// Index: { txId: 1 } unique, { blockNumber: 1 }
```

### 3.3 chaincode_events
```javascript
{
  txId: String,
  chaincodeId: String,
  eventName: String,        // e.g. Mint
  payload: String,          // JSON string nếu có
  blockNumber: Number
}
// Index: { txId: 1 }, { eventName: 1, blockNumber: -1 }
```

Quy tắc bất biến:
- Chỉ Explorer ghi 3 collection này.
- Không có API nào khác được phép ghi/cập nhật/xóa.
- Mọi chỉnh sửa phải đến từ block mới trên Fabric (nguồn chân lý duy nhất).

## 4. Truy vấn Chuẩn (Đảm bảo Nhất quán)

### 4.1 Lấy chiều cao chuỗi khối (height)
```javascript
const last = db.blocks.find().sort({ number: -1 }).limit(1).toArray();
const height = last.length ? last[0].number + 1 : 0;
```

### 4.2 Lấy block gần nhất
```javascript
db.blocks.find().sort({ number: -1 }).limit(10)
```

### 4.3 Tra cứu giao dịch theo txId
```javascript
db.transactions_ledger.findOne({ txId: "<TX_ID>" })
```

### 4.4 Tra cứu sự kiện Mint mới nhất
```javascript
db.chaincode_events.find({ eventName: "Mint" }).sort({ blockNumber: -1 }).limit(5)
```

### 4.5 Kiểm tra chéo sự kiện có giao dịch tương ứng
```javascript
db.chaincode_events.aggregate([
  { $lookup: { from: "transactions_ledger", localField: "txId", foreignField: "txId", as: "tx" } },
  { $match: { tx: { $size: 0 } } }
]) // rỗng => nhất quán
```

## 5. Bảo vệ Tính Bất biến
- Quy định quyền: ứng dụng ngoài chỉ có quyền READ trên 3 collection ledger.
- Listener Explorer ghi idempotent, dùng unique index để chống ghi trùng.
- Không hỗ trợ API update/delete cho 3 collection ledger.

## 6. Mối liên hệ với Chaincode `cvnd-token`
- Các sự kiện như `Mint` phải phát kèm payload JSON (ví dụ `{ wallet, amount, timestamp }`).
- Explorer lưu `payload` nguyên văn để phục vụ audit/analytics, không biên dịch lại.

## 7. API Explorer (đọc từ Mongo)
- GET `/api/blockchain/info`: trả height/hash hiện tại từ `blocks`.
- GET `/api/blocks?limit=N`: trả danh sách block gần nhất.
- (Mở rộng) GET `/api/tx/{txId}`: trả thông tin từ `transactions_ledger` + sự kiện liên quan.

## 8. Phát hiện và xử lý lệch dữ liệu
- Định kỳ đối soát: chạy aggregation 4.5; nếu có lệch, log cảnh báo và re-sync từ block lệch.
- Re-sync: đọc lại block từ Fabric, ghi đè (idempotent) vào Mongo theo `number/txId`.
