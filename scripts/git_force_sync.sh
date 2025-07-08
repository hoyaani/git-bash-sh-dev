#!/bin/bash
set -e # 遇到非零退出碼時立即退出腳本
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# --- 配置區塊 ---
# 預設分支名稱，例如 main 或 master
DEFAULT_BRANCH="main" 
# --- 配置結束 ---

# 檢查 whiptail 是否存在，如果不存在則嘗試安裝 (與之前的腳本相同)
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
DIALOG_TITLE="Git 本地倉庫強制同步 (極度危險)"
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

# 函數：執行強制同步操作
force_sync_action() {
    # 第一次警告
    whiptail --title "$DIALOG_TITLE - 警告！" --yesno \
    "這將強制覆蓋您本地的所有變更，並與遠端倉庫完全同步。\n\n" \
    "!!! 本地所有未提交或未推送的變更將永久丟失 !!!\n\n" \
    "您確定要繼續嗎？" $HEIGHT $WIDTH --defaultno
    
    if [ $? -ne 0 ]; then # 用戶選擇否或取消
        show_message "操作已取消。沒有對本地倉庫進行任何修改。"
        return 0
    fi

    BRANCH_NAME=$(get_input "請輸入要同步的遠端分支名稱 (例如：main 或 master)：" "$DEFAULT_BRANCH")
    if [ $? -ne 0 ] || [ -z "$BRANCH_NAME" ]; then
        show_message "分支名稱不能為空或取消操作。同步已取消。"
        return 1
    fi

    # 第二次警告，要求輸入確認文字
    CONFIRM_TEXT="我確認並接受所有數據丟失"
    CONFIRMATION=$(get_input "再次確認：請輸入以下文字以繼續：\n『${CONFIRM_TEXT}』" "")

    if [ "$CONFIRMATION" != "$CONFIRM_TEXT" ]; then
        show_message "確認文字不匹配。操作已取消。沒有對本地倉庫進行任何修改。"
        return 1
    fi

    show_message "正在從遠端拉取最新資料 (git fetch origin)..."
    FETCH_OUTPUT=$(git fetch origin 2>&1)
    if [ $? -ne 0 ]; then
        show_error "git fetch 失敗！請檢查網路或遠端設定。\n\n$FETCH_OUTPUT"
        return 1
    fi
    show_message "git fetch 完成。\n\n$FETCH_OUTPUT"

    show_message "正在執行：git reset --hard origin/$BRANCH_NAME\n(這將丟失本地所有變更)..."
    RESET_OUTPUT=$(git reset --hard origin/"$BRANCH_NAME" 2>&1)
    if [ $? -ne 0 ]; then
        show_error "git reset --hard 失敗！\n\n$RESET_OUTPUT"
        return 1
    fi
    show_message "git reset --hard 完成。\n\n$RESET_OUTPUT"

    # 清理 untracked 檔案和資料夾 (可選但推薦)
    whiptail --title "$DIALOG_TITLE" --yesno \
    "您想同時清除本地所有未被 Git 追蹤的檔案和資料夾嗎？\n(這將執行 'git clean -df')" \
    $HEIGHT $WIDTH --defaultno

    if [ $? -eq 0 ]; then
        show_message "正在執行：git clean -df (清理未追蹤檔案)..."
        CLEAN_OUTPUT=$(git clean -df 2>&1)
        if [ $? -ne 0 ]; then
            show_error "git clean -df 失敗！\n\n$CLEAN_OUTPUT"
            return 1
        fi
        show_message "git clean -df 完成。\n\n$CLEAN_OUTPUT"
    else
        show_message "跳過 'git clean -df'。"
    fi

    show_message "本地倉庫已成功強制同步至遠端 $BRANCH_NAME 分支的狀態！\n\n您的本地工作區現在與遠端完全一致。"
}

# 函數：主選單
main_menu() {
    whiptail --title "$DIALOG_TITLE" --menu "請選擇您要執行的操作：" $HEIGHT $WIDTH $CHOICE_HEIGHT \
    "1" "強制同步本地倉庫至遠端 (危險操作)" \
    "2" "離開" 3>&1 1>&2 2>&3
}

# 主迴圈
while true
do
    CHOICE=$(main_menu)

    case $CHOICE in
        1) force_sync_action ;;
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
