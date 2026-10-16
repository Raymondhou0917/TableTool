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

App 位於 `build/Release-arm64/Build/Products/Release/`，ZIP 位於 `dist/`。測試會執行英文與繁體中文兩組，結果包包含真正 AppKit 介面的截圖附件。

## 資料與限制

App 只讀寫你選擇的檔案，不內建分析追蹤或雲端上傳。保留原版的數字自動辨識行為：**前導零等數字格式可能被正規化**。處理編號、帳號或重要匯入檔時請保留原始檔，先在副本驗證轉換結果。

## 原作者與 ARM 工作

原作者為 Sandro Peham、Andreas Aigner 與 Jakob Egger；Apple Silicon 修正採用 Andrea Brugnoli 的 [PR #112](https://github.com/jakob/TableTool/pull/112)，再補上雙語與發布工程。詳細範圍見 [UPSTREAM.md](UPSTREAM.md)。
