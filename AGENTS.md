# TableTool：團隊與 AI 開發規則

先讀 `README.md` 與本次改動相關的專案指引；本檔適用於所有開發協作者與 AI agent。

## CI 額度與執行環境（所有協作者與 AI 必讀）

**AI 可以改碼；使用 macOS 算力必須有明確的 Apple 驗證需求。** 本節是協作規則，不代表現有 workflow 已自動強制執行；不得以省額度為由刪除必要測試、偽造綠燈或繞過必過檢查。

1. **先本地、再推送。** 開工先讀本檔、相關指引、工作樹與 `.github/workflows/` 的事件、runner、矩陣與必過檢查；先跑與改動相符的本地驗證，再集中推送可審閱的變更，避免用連續 push 試錯。
2. **不無意義重跑。** 不為「再看一次」重跑已綠燈的 macOS job，不連續手動重跑整包測試／打包。失敗先看 log、找原因；確認修正或暫時性故障後，只重跑必要的失敗 job，並留下原因。
3. **依影響判斷，不能只看副檔名。** 純協作說明可只做文件檢查；會被產品讀取的 Markdown、題庫、翻譯、JSON、圖示、素材、生成器輸入與發佈資料仍要做對應的語法、資料、建置或畫面驗證。只有影響 Apple bundle／UI／資源整合的部分才需要對應 Apple 驗證；一般文件或圖片變更不自動要求完整 macOS test／pack。
4. **Linux 優先處理可移植工作。** lint、型別、資料檢查、Web／API／CLI 測試與可移植建置優先在本地或已核准的隔離 Linux／VM 執行。SwiftUI、AppKit、Apple SDK、Xcode、模擬器、簽署與公證留在受控 Mac；Linux 綠燈不能代替 Apple 相容性驗收。GPT、Codex、dot 或其他 agent 的執行環境也不會自動免除 GitHub Actions 或 VM 的費用。
5. **同一 PR 只保留最新驗證。** 新增或調整 PR 驗證 workflow 時，用 workflow 名稱加 PR 編號（非 PR 則用 ref）作為 `concurrency.group`，對可取消的驗證設 `cancel-in-progress: true`。不要把不同 PR 放進同一組，也不要將部署／公證等有副作用的工作一律改成可中途取消。
6. **保留穩定的必過檢查。** 若調整 paths／change filter，要保留每次 PR 都回報的固定檢查；由 job 層決定需跑哪些重工作，無關變更明確回報成功跳過。改 workflow 前先核對 branch protection／rulesets；讀不到時明說待維護者確認，不能猜測或擅自移除 required checks。
7. **Draft 與發版分流。** Draft PR 預設先做輕量且必要的驗證，不強制全量 macOS 矩陣或發佈打包；轉 ready 後依影響補齊必要 Apple 驗證。Universal 正式分發打包、Developer ID 簽署、公證、staple、DMG／PKG、商店上傳與發佈，只走明確核准的 release／tag／手動發版通道，不掛在每次 PR push。既有本地 ad-hoc 開發驗證仍按專案指引執行。
8. **日常機器不變成組織 CI。** 不把日常筆電、Mac mini、既有雲端主機或 agent 主機註冊為通用 self-hosted runner；不把未受信任 PR、公司簽署憑證或生產資料送到未核准 VM。新增 runner、VM、權限或隔離方案須另獲明確授權；在隔離目錄手動做必要本地驗證，不等於允許安裝常駐 CI。
9. **付款與額度由負責人決定。** AI 不自行加付款方式、提高預算、移除支出限制、改 billing／runner 權限或購買雲端資源。額度耗盡時停止會花費額度的雲端執行，先交付本地驗證結果與可審閱 diff／draft PR，列出仍缺的檢查。
10. **提交前確認事件。** Draft PR 本身不保證免跑 CI。先查 `push`、`pull_request`、`pull_request_target`、`workflow_run` 與外部部署整合；只有確認安全才推送／開 PR。`[skip ci]` 僅可用於確定不影響產品的協作文件變更，而且不能停止 `pull_request_target` 或所有外部服務；required checks 可能維持 pending，必須照實回報，不改成假成功。無法安全發布時保留本地 patch，不觸發雲端工作。

交付時說清楚：改了什麼、跑了哪些本地檢查、哪些沒跑及原因、是否真的修改 workflow。只有 AGENTS.md 的文字更新，不能宣稱已降低實際 CI 用量。

### 本專案的執行分工

本專案為原生 macOS CSV 編輯器，包含 `Table Tool.xcodeproj` 與 `Table ToolTests`。既有 CI 在 PR 執行 macOS，且 push 會匹配 `master`／`codex/**`；提交前先確認事件。CSV 解析、編碼、匯入匯出與英文／繁中介面仍需必要測試；不以省額度刪掉測試。
