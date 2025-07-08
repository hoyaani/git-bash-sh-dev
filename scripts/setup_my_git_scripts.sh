#!/bin/bash
set -e # 遇到非零退出碼時立即退出腳本

# 宣告腳本執行環境為 UTF-8 編碼
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# --- whiptail 工具檢查與安裝邏輯 (與之前的腳本相同) ---
# 為了避免重複，這裡省略了詳細的 whiptail 檢查與安裝程式碼。
# 請將您之前腳本中開頭的 whiptail 檢查和安裝邏輯複製到這裡。
# 確保在執行實際邏輯之前 whiptail 是可用的。
# --- 這裡開始放置 whiptail 檢查與安裝程式碼 ---
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
# --- 這裡結束 whiptail 檢查與安裝程式碼 ---


# 標題和常用設定
DIALOG_TITLE="自定義 Git 腳本設定嚮導"
HEIGHT=20
WIDTH=70

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

# --- 主要設定流程 ---

show_message "歡迎使用自定義 Git 腳本設定嚮導！\n\n這個嚮導將引導您設定 Git Bash，以便快速執行您的 Git 腳本。"

whiptail --title "$DIALOG_TITLE" --yesno "您確定要開始設定自定義 Git 腳本嗎？" $HEIGHT $WIDTH --defaultno
if [ $? -ne 0 ]; then
    show_message "設定已取消。感謝使用！"
    exit 0
fi

CUSTOM_SCRIPT_DIR=""
VALID_PATH=false

# 循環詢問並驗證腳本路徑
while [ "$VALID_PATH" == false ]; do
    CUSTOM_SCRIPT_DIR_WIN=$(get_input "請輸入您的 Git 腳本所在目錄的 Windows 路徑 (例如：C:\\Git_Bash_sh-dev)：" "$CUSTOM_SCRIPT_DIR_WIN_PREV")
    if [ $? -ne 0 ]; then # 用戶取消
        show_message "路徑輸入已取消。設定中止。"
        exit 1
    fi

    # 將 Windows 路徑轉換為 Bash 格式
    # 注意：這裡使用 bash 的內建轉換功能，對於簡單的 C:\ 盤符有效
    # 如果路徑包含複雜的符號，可能需要更複雜的轉換
    CUSTOM_SCRIPT_DIR=$(echo "$CUSTOM_SCRIPT_DIR_WIN" | sed 's/\\/\//g' | sed 's/://g' | sed 's/^\([a-zA-Z]\)/\/&/')
    
    if [ -d "$CUSTOM_SCRIPT_DIR" ]; then
        VALID_PATH=true
        show_message "路徑 '$CUSTOM_SCRIPT_DIR_WIN' (Bash: $CUSTOM_SCRIPT_DIR) 已確認存在。"
        CUSTOM_SCRIPT_DIR_WIN_PREV="$CUSTOM_SCRIPT_DIR_WIN" # 記住上次輸入，方便下次預填
    else
        show_error "錯誤：路徑 '$CUSTOM_SCRIPT_DIR_WIN' (Bash: $CUSTOM_SCRIPT_DIR) 不存在或不是一個有效的目錄。\n\n請重新輸入。"
    fi
done

# 收集找到的腳本並檢查權限
declare -A script_aliases # 儲存腳本檔名及其建議的別名
scripts_to_add=()         # 儲存要添加到 PATH 的實際腳本完整路徑
dialog_content=""         # 用於 whiptail 顯示所有找到的腳本

echo_to_bashrc_content="" # 準備寫入 .bashrc 的內容

show_message "正在掃描 '$CUSTOM_SCRIPT_DIR' 中的 .sh 腳本..."

# 初始化 .bashrc 內容開始標記
echo_to_bashrc_content+="\n# --- BEGIN Custom Git Bash Scripts by Setup Wizard ($(date)) ---\n"

# Add the directory to PATH
echo_to_bashrc_content+="if [ -d \"$CUSTOM_SCRIPT_DIR\" ]; then\n"
echo_to_bashrc_content+="    export PATH=\"$CUSTOM_SCRIPT_DIR:\$PATH\"\n"
echo_to_bashrc_content+="    echo \"訊息：已將 $CUSTOM_SCRIPT_DIR 加入 PATH。\"\n"
echo_to_bashrc_content+="else\n"
echo_to_bashrc_content+="    echo \"警告：自定義腳本目錄 $CUSTOM_SCRIPT_DIR 不存在。\"\n"
echo_to_bashrc_content+="fi\n\n"

# 遍歷找到的 .sh 腳本
for script_path in "$CUSTOM_SCRIPT_DIR"/*.sh; do
    if [ -f "$script_path" ]; then
        script_filename=$(basename "$script_path") # 獲取檔名 (例如 git_push_workflow.sh)
        script_basename="${script_filename%.sh}"   # 獲取不帶副檔名的檔名 (例如 git_push_workflow)

        # 根據檔名提供預設別名
        suggested_alias=""
        case "$script_basename" in
            git_force_sync) suggested_alias="gsync" ;;
            git_pull_workflow) suggested_alias="gpull" ;;
            git_push_workflow) suggested_alias="gpush" ;;
            *) suggested_alias="$script_basename" ;; # 其他腳本使用其基本名作為別名
        esac

        script_aliases["$script_filename"]="$suggested_alias"
        scripts_to_add+=("$script_path") # 存儲完整路徑以便後續處理

        # 檢查可執行權限
        if [ ! -x "$script_path" ]; then
            whiptail --title "$DIALOG_TITLE - 權限設定" --yesno \
            "腳本 '$script_filename' 沒有執行權限。\n\n" \
            "是否立即為其賦予執行權限 (chmod +x)？" $HEIGHT $WIDTH
            if [ $? -eq 0 ]; then
                chmod +x "$script_path" 2>/dev/null
                if [ $? -eq 0 ]; then
                    dialog_content+="- $script_filename: 已成功賦予執行權限。\n"
                else
                    dialog_content+="- $script_filename: 賦予執行權限失敗，可能需要管理員權限。\n"
                fi
            else
                dialog_content+="- $script_filename: 未賦予執行權限。若無法執行，請手動設定。\n"
            fi
        else
            dialog_content+="- $script_filename: 已有執行權限。\n"
        fi
        
        # 添加別名到 .bashrc 內容
        echo_to_bashrc_content+="alias ${script_aliases["$script_filename"]}='$script_filename'\n"

    fi
done

if [ -z "$dialog_content" ]; then
    dialog_content="在指定目錄中沒有找到任何 .sh 腳本。"
fi
show_message "腳本掃描和權限檢查結果：\n\n$dialog_content"

# 結束 .bashrc 內容標記
echo_to_bashrc_content+="\n# --- END Custom Git Bash Scripts by Setup Wizard ($(date)) ---\n"


# 確認寫入 .bashrc
whiptail --title "$DIALOG_TITLE - 確認寫入 .bashrc" --yesno \
"所有設定都已準備就緒。\n\n" \
"您確定要將這些設定寫入您的 ~/.bashrc 檔案嗎？\n\n" \
"如果 ~/.bashrc 已存在相同區塊，此操作會追加新的設定。" $HEIGHT $WIDTH

if [ $? -ne 0 ]; then
    show_message "寫入 ~/.bashrc 操作已取消。設定未保存。"
    exit 0
fi

# 寫入 .bashrc
echo -e "$echo_to_bashrc_content" >> ~/.bashrc

show_message "設定已成功寫入 ~/.bashrc！\n\n" \
"請關閉所有 Git Bash 視窗並重新開啟，或執行 'source ~/.bashrc'，\n" \
"您的新別名和 PATH 設定將會生效。"

exit 0
