#!/bin/bash
# 遇到錯誤時立即退出
set -e

# 宣告腳本執行環境為 UTF-8 編碼
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# --- 配置區塊 ---
# 這些變數可以根據你的需求修改
DEFAULT_BRANCH="main" # 預設分支名稱，例如 main 或 master
# --- 配置結束 ---

# 標題
DIALOG_TITLE="Git 遠端推送工作流程"
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
        # 嘗試安裝 dialog 套件 (通常包含 whiptail)
        # 注意：這裡不加 --noconfirm，讓用戶手動確認安裝
        pacman -S dialog

        # 安裝後再次檢查 whiptail
        if ! command -v whiptail &> /dev/null
        then
            echo "錯誤：嘗試安裝 whiptail 失敗，或您未確認安裝。"
            echo "請確認您的網路連接，或手動執行 'pacman -S dialog' 安裝。"
            echo "如果遇到權限問題，請務必『以系統管理員身份執行 Git Bash』。"
            exit 1
        else
            echo "whiptail 已成功安裝！"
            # 等待幾秒讓用戶看到訊息
            sleep 2
            clear # 清除安裝訊息，為對話框準備
        fi
    else
        echo "錯誤：pacman (套件管理器) 未找到。無法自動安裝 whiptail。"
        echo "請手動在 Git Bash 環境中安裝 whiptail (例如透過 MSYS2 的 pacman -S dialog)。"
        exit 1
    fi
fi

# =========================================================
# 以下是原有的 Git 工作流程腳本內容，省略部分以保持簡潔
# 實際使用時請將完整的腳本內容複製到此處
# =========================================================

# 函數：主選單
main_menu() {
    whiptail --title "$DIALOG_TITLE" --menu "請選擇您要執行的操作：" $HEIGHT $WIDTH $CHOICE_HEIGHT \
    "1" "檢查工作區狀態 (git status)" \
    "2" "暫存變更 (git add .)" \
    "3" "提交變更 (git commit)" \
    "4" "設定遠端倉庫 (git remote add) [僅首次]" \
    "5" "拉取遠端變更 (git pull) [建議推送前]" \
    "6" "推送變更 (git push)" \
    "7" "全部自動執行 (add -> commit -> pull -> push)" \
    "8" "離開" 3>&1 1>&2 2>&3
}

# 函數：執行 Git Status
git_status_action() {
    show_message "正在執行：git status\n\n$(git status 2>&1)"
}

# 函數：執行 Git Add
git_add_action() {
    whiptail --title "$DIALOG_TITLE" --yesno "確定要執行 'git add .' 暫存所有變更嗎？" $HEIGHT $WIDTH
    if [ $? -eq 0 ]; then
        show_message "正在執行：git add .\n\n$(git add . 2>&1)"
    else
        show_message "取消 'git add .' 操作。"
    fi
}

# 函數：執行 Git Commit
git_commit_action() {
    COMMIT_MSG=$(get_input "請輸入提交訊息：" "")
    if [ $? -eq 0 ] && [ -n "$COMMIT_MSG" ]; then
        show_message "正在執行：git commit -m \"$COMMIT_MSG\"\n\n$(git commit -m "$COMMIT_MSG" 2>&1)"
    else
        show_message "提交訊息不能為空或取消操作。"
    fi
}

# 函數：執行 Git Remote Add
git_remote_add_action() {
    REMOTE_URL=$(get_input "請輸入遠端倉庫 URL (例如：https://github.com/user/repo.git)：" "")
    if [ $? -eq 0 ] && [ -n "$REMOTE_URL" ]; then
        show_message "正在執行：git remote add origin $REMOTE_URL\n\n$(git remote add origin "$REMOTE_URL" 2>&1)"
    else
        show_message "遠端 URL 不能為空或取消操作。"
    fi
}

# 函數：執行 Git Pull
git_pull_action() {
    BRANCH_NAME=$(get_input "請輸入要拉取的分支名稱 (預設: $DEFAULT_BRANCH)：" "$DEFAULT_BRANCH")
    if [ $? -eq 0 ] && [ -n "$BRANCH_NAME" ]; then
        show_message "正在執行：git pull origin $BRANCH_NAME\n\n$(git pull origin "$BRANCH_NAME" 2>&1)"
    else
        show_message "分支名稱不能為空或取消操作。"
    fi
}

# 函數：執行 Git Push
git_push_action() {
    BRANCH_NAME=$(get_input "請輸入要推送的分支名稱 (預設: $DEFAULT_BRANCH)：" "$DEFAULT_BRANCH")
    if [ $? -eq 0 ] && [ -n "$BRANCH_NAME" ]; then
        if whiptail --title "$DIALOG_TITLE" --yesno "這是首次推送此分支嗎？(將使用 -u 選項)" $HEIGHT $WIDTH; then
            show_message "正在執行：git push -u origin $BRANCH_NAME\n\n$(git push -u origin "$BRANCH_NAME" 2>&1)"
        else
            show_message "正在執行：git push origin $BRANCH_NAME\n\n$(git push origin "$BRANCH_NAME" 2>&1)"
        fi
    else
        show_message "分支名稱不能為空或取消操作。"
    fi
}

# 函數：自動化流程
auto_flow() {
    show_message "開始自動化流程：add -> commit -> pull -> push"

    # 1. git add .
    show_message "正在執行：git add .\n\n$(git add . 2>&1)"

    # 2. git commit
    COMMIT_MSG=$(get_input "請輸入提交訊息：" "")
    if [ $? -ne 0 ] || [ -z "$COMMIT_MSG" ]; then
        show_error "提交訊息不能為空或取消操作。自動流程中止。"
        return 1
    fi
    show_message "正在執行：git commit -m \"$COMMIT_MSG\"\n\n$(git commit -m "$COMMIT_MSG" 2>&1)"

    # 3. git pull
    BRANCH_NAME=$(get_input "請輸入要拉取的分支名稱 (預設: $DEFAULT_BRANCH)：" "$DEFAULT_BRANCH")
    if [ $? -ne 0 ] || [ -z "$BRANCH_NAME" ]; then
        show_error "分支名稱不能為空或取消操作。自動流程中止。"
        return 1
    fi
    show_message "正在執行：git pull origin $BRANCH_NAME\n\n$(git pull origin "$BRANCH_NAME" 2>&1)"

    # 4. git push
    if whiptail --title "$DIALOG_TITLE" --yesno "這是首次推送此分支嗎？(將使用 -u 選項)" $HEIGHT $WIDTH; then
        show_message "正在執行：git push -u origin $BRANCH_NAME\n\n$(git push -u origin "$BRANCH_NAME" 2>&1)"
    else
        show_message "正在執行：git push origin $BRANCH_NAME\n\n$(git push origin "$BRANCH_NAME" 2>&1)"
    fi

    show_message "自動化流程執行完畢。"
}


# 主迴圈
while true
do
    CHOICE=$(main_menu)

    case $CHOICE in
        1) git_status_action ;;
        2) git_add_action ;;
        3) git_commit_action ;;
        4) git_remote_add_action ;;
        5) git_pull_action ;;
        6) git_push_action ;;
        7) auto_flow ;;
        8)
            show_message "感謝使用！"
            break
            ;;
        *)
            show_message "無效選項，請重新選擇。"
            ;;
    esac
done

exit 0
