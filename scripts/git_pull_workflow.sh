#!/bin/bash
set -e # 遇到非零退出碼時立即退出腳本
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# --- 配置區塊 ---
DEFAULT_BRANCH="main" # 預設分支名稱，例如 main 或 master
# --- 配置結束 ---

# 檢查 whiptail 是否存在，如果不存在則嘗試安裝
if ! command -v whiptail &> /dev/null
then
    echo "警告：whiptail 工具未安裝或不在 PATH 中。"
    echo "此腳本需要 whiptail 來顯示對話框。"
    echo ""
    echo "==================================================================="
    echo "  注意：如果接下來的安裝步驟出現權限錯誤，"
    echo "        請關閉目前的 Git Bash，然後『右鍵點擊 Git Bash 圖示』"
    echo "        選擇『以系統管理員身份執行』，再重新運行此腳本。"
    echo "==================================================================="
    echo ""
    echo "正在嘗試透過 pacman 安裝 whiptail (屬於 'dialog' 套件)..."
    echo "您可能需要按 'Y' 確認安裝。"
    echo "按 Enter 鍵繼續安裝，或 Ctrl+C 取消。"
    read -r

    if command -v pacman &> /dev/null
    then
        pacman -S dialog
        if ! command -v whiptail &> /dev/null
        then
            echo "錯誤：嘗試安裝 whiptail 失敗，或您未確認安裝。"
            echo "請確認您的網路連接，或手動執行 'pacman -S dialog' 安裝。"
            echo "如果遇到權限問題，請務必『以系統管理員身份執行 Git Bash』。"
            exit 1
        else
            echo "whiptail 已成功安裝！"
            sleep 2
            clear
        fi
    else
        echo "錯誤：pacman (套件管理器) 未找到。無法自動安裝 whiptail。"
        echo "請手動在 Git Bash 環境中安裝 whiptail (例如透過 MSYS2 的 pacman -S dialog)。"
        exit 1
    fi
fi

# 標題和常用設定
DIALOG_TITLE="Git 遠端拉取工作流程"
HEIGHT=20
WIDTH=70
CHOICE_HEIGHT=15

# 函數：顯示訊息框
show_message() {
    whiptail --title "$DIALOG_TITLE" --msgbox "$1" $HEIGHT $WIDTH
}

# 函數：顯示錯誤訊息框
show_error() {
    whiptail --title "$DIALOG_TITLE - 錯誤" --msgbox "$1" $HEIGHT $WIDTH
}

# 函數：顯示輸入框
get_input() {
    whiptail --title "$DIALOG_TITLE" --inputbox "$1" $HEIGHT $WIDTH "$2" 3>&1 1>&2 2>&3
}

# 函數：檢測是否處於合併衝突狀態
is_merging() {
    git rev-parse --verify MERGE_HEAD &> /dev/null
}

# 函數：執行 Git Pull
git_pull_action() {
    BRANCH_NAME=$(get_input "請輸入要拉取的分支名稱 (預設: $DEFAULT_BRANCH)：" "$DEFAULT_BRANCH")
    if [ $? -ne 0 ] || [ -z "$BRANCH_NAME" ]; then
        show_message "分支名稱不能為空或取消操作。"
        return 1
    fi

    # 執行 pull 操作
    PULL_OUTPUT=$(git pull origin "$BRANCH_NAME" 2>&1)
    PULL_STATUS=$? # 捕獲 git pull 的退出狀態碼

    show_message "正在執行：git pull origin $BRANCH_NAME\n\n$PULL_OUTPUT"

    # 檢查是否發生合併衝突
    if [ $PULL_STATUS -ne 0 ] && is_merging; then
        show_error "Git Pull 發生合併衝突！您需要手動解決衝突，或者選擇回退。"

        whiptail --title "$DIALOG_TITLE - 合併衝突" --yesno \
        "偵測到合併衝突！\n\n您想現在執行 'git merge --abort' 來回退到合併前的狀態嗎？\n\n(若選擇『否』，您將需要手動解決衝突。)" \
        $HEIGHT $WIDTH

        if [ $? -eq 0 ]; then # 用戶選擇是，回退
            show_message "正在執行：git merge --abort\n\n$(git merge --abort 2>&1)"
            show_message "已成功回退到合併前狀態。請檢查您的工作區。"
        else # 用戶選擇否，不回退
            show_message "您選擇不回退。請手動解決衝突後，執行 'git add .', 'git commit' 完成合併。"
        fi
    elif [ $PULL_STATUS -ne 0 ]; then
        # 處理其他非合併衝突的錯誤 (例如網路問題，遠端分支不存在等)
        show_error "Git Pull 執行失敗，但不是合併衝突。\n請檢查上述訊息了解錯誤原因。"
    else
        show_message "Git Pull 成功完成，沒有偵測到衝突。"
    fi
}

# 函數：主選單
main_menu() {
    whiptail --title "$DIALOG_TITLE" --menu "請選擇您要執行的操作：" $HEIGHT $WIDTH $CHOICE_HEIGHT \
    "1" "拉取遠端變更 (git pull) [含衝突回退]" \
    "2" "離開" 3>&1 1>&2 2>&3
}

# 主迴圈
while true
do
    CHOICE=$(main_menu)

    case $CHOICE in
        1) git_pull_action ;;
        2)
            show_message "感謝使用！"
            break
            ;;
        *)
            show_message "無效選項，請重新選擇。"
            ;;
    esac
done

exit 0
