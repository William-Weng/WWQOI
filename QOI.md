# 格式解說

## 以下是一個1x1 像素的 QOI 檔案完整範例（總共 64 bytes），用十六進位顯示。這張圖片的像素是純紅色 RGBA(255,0,0,255)：

```bin
71 6F 69 66                     // [0-3]  magic: "qoif"  
00 00 00 01                     // [4-7]  width: 1 (BE)
00 00 00 01                     // [8-11] height: 1 (BE) 
04                              // [12]   channels: 4 (RGBA)
00                              // [13]   colorspace: 0 (sRGB)

FF  FF  00  00  00  FF          // [14-19] RGBA chunk (tag 0xFF): r=255,g=0,b=0,a=255

00 00 00 00 00 00 00 00         // [20-27] padding (無像素資料)
00 00 00 00 00 00 00 00         // [28-35] padding
00 00 00 00 00 00 00 00         // [36-43] padding  
00 00 00 00 00 00 00 01         // [44-51] end marker (最後8 bytes)
```

## 逐區塊解析

| Offset | Bytes (Hex) | 解釋 |
| ---  | --- | --- | 
| 0-3 | 71 6F 69 66 | Header: "qoif" |
| 4-7 | 00 00 00 01 | Width = 1 pixel |
| 8-11 | 00 00 00 01 | Height = 1 pixel |
| 12 | 04 | Channels = RGBA |
| 13 | 00 | Colorspace = sRGB |
| 14-19 | FF FF 00 00 00 FF | QOI_OP_RGBA: 完整紅色像素 (255,0,0,255) |
| 20-51 | 00...00 | Padding（實際應用中像素區塊會填滿） |
| 52-59 | 00 00 00 00 00 00 00 01 | End Marker |

## 解碼流程驗證

1. 讀 Header → 1x1 RGBA 圖片
2. 讀第一個 chunk: tag=0xFF → QOI_OP_RGBA
3. 讀 r=255, g=0, b=0, a=255 → 設定 first pixel
4. 像素計數=1，等於 width×height=1 → 成功
5. 讀到 end marker → 檔案完整

# 如何壓縮

## 壓縮核心：64 像素索引表
QOI 維護一個固定大小 64 的像素快取：
```bin
hash_pos = (r×3 + g×5 + b×7 + a×11) % 64
```
每個新像素：
1. 先檢查索引表中是否有相同像素 → QOI_OP_INDEX (最省)
2. 沒有 → 檢查與前像素差異 → 選擇最佳 chunk
3. 更新索引表（寫入 hash_pos）

## 6 種壓縮 Chunk 決策流程
| 優先級 | Chunk 類型 | 條件 | 位元組數 | Tag | 原理 |
| ---  | --- | --- |  --- | ---  |
| 1	| INDEX	| 索引表第 X 位有此像素 | 1 | 00 | 重複像素引用 |
| 2	| DIFF | RGB 差異全在 -2~+1 | 1 | 01 | 極小變化 |
| 3	| LUMA | 綠差 -32~+31，紅藍相對綠 ±8 | 2 | 10 | 人類視覺綠通道敏感 |
| 4	| RUN | 連續相同像素 1-62 個 | 1 | 11 | 大面積同色 |
| 5	| RGB | 以上皆不符 | 4 | FE | 完整 RGB (alpha 前值) |
| 6	| RGBA | 需要指定 alpha | 5  | FF | 完整 RGBA |

## 實際編碼偽碼
```py
for each pixel in image:
    if pixel in index_table[hash_pos]:
        write INDEX chunk               // 1 byte
    elif all RGB diffs in [-2,1]:
        write DIFF chunk                // 1 byte
    elif green_diff in [-32,31]:
        write LUMA chunk                // 2 bytes
    elif run_length >= 2:
        write RUN chunk                 // 1 byte
    else:
        write RGB chunk                 // 4 bytes
    index_table[hash_pos] = pixel       // 更新快取
```

## 測試圖片設定

```bins
寬: 2, 高: 2, RGBA, sRGB
像素 (從左上到右下):
P0: 紅色 (255, 0,   0, 255)
P1: 綠色 (0,   255, 0,   255)  
P2: 藍色 (0,   0,   255, 255)
P3: 紅色 (255, 0,   0,  255) ← 重複 P0
```

## 完整 QOI 檔案 (28 bytes)

```bin
71 6F 69 66                 // [0-3] Header: "qoif"
00 00 00 02                 // [4-7] width=2
00 00 00 02                 // [8-11] height=2  
04                          // [12] channels=RGBA
00                          // [13] colorspace=sRGB

FF FF 00 00 00 FF           // [14-19] P0: QOI_OP_RGBA (紅)
FE 00 FF 00                 // [20-23] P1: QOI_OP_RGB (綠)
FE 00 00 FF                 // [24-27] P2: QOI_OP_RGB (藍)
32                          // [28] P3: QOI_OP_INDEX #0 (紅，重複P0)

00 00 00 00 00 00 00 00     // [29-36] End marker + padding
```

## Tag 值嚴格分離

| Chunk 類型 | Tag 範圍 (Hex) | 二進位開頭 | FF 可能嗎？ |
| ---  | --- | --- |  --- |
| INDEX | 00-3F | 00xxxxxx | ❌ 不可能 |
| DIFF | 40-7F | 01xxxxxx | ❌ |
| LUMA | 80-BF | 10xxxxxx | ❌ |
| RUN | C0-FD | 11xxxxxx | ❌ |
| RGB | FE | 11111110 | ❌ |
| RGBA | FF | 11111111 | ✅ 專屬 RGBA |

## 256 Byte 值完美利用圖

```bin
00000000 ~ 00111111 (  0- 63)  64種 → **INDEX** (64槽)
01000000 ~ 01111111 ( 64-127)  64種 → **DIFF** (3×2bit組合)
10000000 ~ 10111111 (128-191)  64種 → **LUMA** (第1byte)
11000000 ~ 11111101 (192-253)  62種 → **RUN** (1~62)
11111110            ( 254)      1種 → **RGB**
11111111            ( 255)      1種 → **RGBA**

總計：64+64+64+62+1+1 = **256 ✓**
```

## 解碼「先後順序」驗證

正確順序：
1. **RGB/RGBA** → 建立「基準顏色」+填 index_table
2. **INDEX**    → **查詢** index_table（前面已寫入）
3. **DIFF/LUMA**→ **微調** 前顏色
4. **RUN**      → **重複** 前顏色

狀態依賴：RUN 需要「前一個顏色已存在」

## QOI 核心原則

**「顏色必須先存在，才能有意義」**

1. RGB/RGBA → **創造** 顏色 → 存入 index_table
2. INDEX    → **引用** 現有顏色  
3. DIFF/LUMA→ **變形** 現有顏色
4. RUN      → **複製** 現有顏色

狀態流：創造 → 引用/變形/複製 → **永不真空**

