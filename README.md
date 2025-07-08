# Git Bash 命令列 UI sh腳本開發
---

本倉庫用於撰寫並收錄在 Git Bash 命令列 UI 中使用的 Shell 腳本，協助管理本地與遠端 Git 倉庫操作，並提升在 Windows Git Bash 環境下的自動化與易用性。

## 目錄結構與主要檔案說明

### 根目錄

- **LICENSE**  
  採用[MIT](LICENSE)的開源授權條款。

- **README.md**  
  本說明文件。

### scripts 資料夾

存放所有核心 Shell 腳本，主要用於輔助 Git 操作，並提供對話框（whiptail）介面，提高使用者體驗。

#### 1. `setup_my_git_scripts.sh`
Git Bash 腳本安裝、路徑設定與 alias 建立精靈。  
- 功能：引導用戶設定腳本目錄、檢查 whiptail 工具、批次檢查與設置腳本執行權限、將腳本新增到 PATH，並自動寫入 `.bashrc`。
- 特點：適合初次部署、快速更新 shell script 工作環境，強化腳本可用性。

#### 2. `git_pull_workflow.sh`
輔助拉取（pull）遠端分支變更的流程腳本。  
- 功能：互動式選擇要拉取的分支，執行 `git pull` 並自動偵測/處理合併衝突，可選擇直接 abort 合併。
- 特點：適合新手、團隊協作時確保正確同步遠端內容。

#### 3. `git_push_workflow.sh`
一站式 Git 主要操作整合腳本。  
- 功能：以 whiptail 介面逐步引導執行 git status、add、commit、remote add、pull、push，支援全自動（add→commit→pull→push）模式。
- 特點：方便一鍵新增修改、推送到遠端，降低手動操作失誤。

#### 4. `git_force_sync.sh`
提供極度危險的本地倉庫「強制同步」功能。  
- 功能：將本地所有未提交或未推送的變更徹底覆蓋，強制同步到指定遠端分支（如 main/master），包括強制 reset 及可選的 git clean 操作。
- 特點：全程以 whiptail 互動式對話框進行二次確認與警告，適合需要用遠端倉庫完全還原本地狀態的情境。

---

## 使用說明

1. 請先確保 Windows Git Bash 環境下已安裝 [whiptail/dialog] 工具（腳本會自動檢查並協助安裝）。
2. 建議先將 `setup_my_git_scripts.sh` 改放到/scripts目錄外後執行，完成環境部署與/scripts中sh腳本 alias 設定。
3. 依需求執行對應腳本（如同步、拉取、推送）。
4. 詳細指令與操作流程，請參考各腳本註解。

---

## 適用情境

- Windows Git Bash 用戶
- 需要 UI 對話框輔助的 Git 操作自動化
- 預防人為誤操作、加強安全提示
- 教學、團隊協作

如有建議或問題，歡迎發 issue 討論！
