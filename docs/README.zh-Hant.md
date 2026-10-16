# Table Tool Native

適用 Apple Silicon 的輕量 CSV 編輯器，提供繁體中文與英文介面。這是 [jakob/TableTool](https://github.com/jakob/TableTool) 的社群分支，沿用 MIT 授權與原作者的 CSV 引擎。

## 下載與使用

1. 從 [Releases](https://github.com/Raymondhou0917/TableTool/releases) 下載 `arm64.zip`，解壓縮後將 **Table Tool Native.app** 放入「應用程式」。
2. 本版使用不同的 App 名稱與 bundle ID，可與原版 Table Tool 並存，不會自動覆寫原版。
3. 預設依 macOS 語言選擇介面，也可在 **Table Tool Native → 語言** 選擇「跟隨系統」、「English」或「繁體中文」。儲存文件並重新開啟 App 後生效。
4. 支援 CSV 編輯、增刪與移動列／欄、復原、編碼／分隔符號設定與格式轉換。繁體中文舊檔可選 Big5。

### 系統與簽章

- Apple Silicon（M 系列），建置最低版本為 macOS 12；實際驗收環境為 macOS 27、M4 Pro。未宣稱已在所有舊版 macOS 驗證。
- 發布檔為 ad-hoc 簽章，**尚未取得 Developer ID 簽章或 Apple 公證**。下載後若 macOS 阻擋，請依「系統設定 → 隱私權與安全性」的個別 App 開啟流程處理，或自行從原始碼建置。不需要全域停用 Gatekeeper。
- 為維持舊版自訂表格與圖示的可讀性，這版固定使用淺色介面。

## 自行建置

需要完整 Xcode（Command Line Tools 單獨不足），不需 CocoaPods、網路 API 或其他套件。

```sh
bash scripts/build.sh
bash scripts/test.sh
```

App 位於 `build/Distribution-arm64/Build/Products/Release/`，ZIP 位於 `dist/`。測試會執行英文與繁體中文兩組，結果包包含真正 AppKit 介面的截圖附件。

## 資料與限制

App 只讀寫你選擇的檔案，不內建分析追蹤或雲端上傳。

1. **儲存格一律保留文字原貌**：`00123`、`1.2300`、`1e003`、`+0002`、超長編號與前後空白，開檔、編輯、貼上與存檔都不會自動轉成數值。小數點設定只用於格式判斷與對齊，不轉換儲存格文字。
2. 未修改內容、格式或欄位順序時，存檔保留原始位元組。編輯後保存各格文字、編碼、UTF-8 BOM 與偵測到的列尾格式；引號會重新產生，混合列尾可能統一，因此編輯後不宣稱逐位元組相同。原本較短的列不會自動補上尾端空欄。
3. 關閉引號時，若儲存格含分隔符號或換行，會阻止儲存並提示啟用引號。所選編碼無法表示的文字也會報錯，避免悄悄替換成問號。
4. 分隔符號與編碼仍採自動推測；Big5 等舊編碼可能有歧義，請先看預覽並選對格式。測試範圍見 [VALIDATION.md](VALIDATION.md)，並非保證任何格式錯誤的檔案都能正確推測。

## 原作者與 ARM 工作

原作者為 Sandro Peham、Andreas Aigner 與 Jakob Egger；Apple Silicon 修正採用 Andrea Brugnoli 的 [PR #112](https://github.com/jakob/TableTool/pull/112)，再補上雙語與發布工程。詳細範圍見 [UPSTREAM.md](UPSTREAM.md)。
