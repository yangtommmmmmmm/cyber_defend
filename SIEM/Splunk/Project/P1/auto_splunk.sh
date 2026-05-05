#!/bin/bash

# ============================================================
# Splunk Automation Dialog Tool
# ============================================================

# --- Color Definitions ---
RED='\033[31m'
GREEN='\033[32m'
BOLD='\033[1m'
RESET='\033[0m'

# --- Global Constants ---
SPLUNK_BIN='/opt/splunk/bin/splunk'
INDEX_MASTER_FILE='/opt/splunk/etc/master-apps/my_indexes/local/indexes.conf'
SSH_USER="tomyang"
SCRIPTS_BASE="/home/${SSH_USER}/scripts"
SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"

# ============================================================
# Utility Functions
# ============================================================

# [FIX] Added IP format validation (原版無此檢查)
validate_ip() {
    local ip="$1"
    if [[ ! "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        echo -e "${RED}Invalid IP address format: $ip${RESET}"
        return 1
    fi
    return 0
}

# Check if IP is reachable
check_ping() {
    local ip="$1"
    if ! ping -c 1 -w 1 "$ip" &>/dev/null; then
        echo -e "${RED}Cannot reach $ip. Please check the IP address.${RESET}"
        return 1
    fi
    return 0
}

# [FIX] 原版: `ip 4 addr` → 應為 `ip -4 addr`
is_local_ip() {
    local ip="$1"
    ip -4 addr show | grep -qw "$ip"
}

# [FIX] 統一 mkdir -p，避免目錄已存在時的重複 if/else 邏輯
ensure_dir() {
    local dir="$1"
    mkdir -p "$dir" || { echo -e "${RED}Failed to create directory: $dir${RESET}"; return 1; }
}

# ============================================================
# Function 1: Add Index to Index Master
# ============================================================
add_index() {
    read -p "Please input the IP address for index master: " ip
    validate_ip "$ip" || return
    check_ping "$ip"   || return
    read -p "What index do you want to add? " index

    if is_local_ip "$ip"; then
        echo -e "$ip is the local host."
        # [FIX] 原版: `[ -f "$LOCAL_FILE" ]` 反向判斷語意 — 找不到時才是非 index-master
        if [[ ! -f "$INDEX_MASTER_FILE" ]]; then
            echo -e "${RED}This is not index-master (config file not found).${RESET}"
            return
        fi
        # [FIX] 原版 grep: `"LOCAL_FILE"` 少了 `$`，永遠無法正確搜尋
        # [FIX] 改用 `^\[index\]` 確保是 section header 而非內文誤中
        if grep -q "^\[${index}\]" "$INDEX_MASTER_FILE"; then
            echo -e "Index '${index}' is already configured."
        else
            # [FIX] 原版 `repFactor =1` 格式不標準，改為 `repFactor = 1`
            printf '\n[%s]\nhomePath = $SPLUNK_DB/%s/db\ncoldPath = $SPLUNK_DB/%s/colddb\nthawedPath = $SPLUNK_DB/%s/thaweddb\nrepFactor = 1\n' \
                "$index" "$index" "$index" "$index" >> "$INDEX_MASTER_FILE"
            echo "Applying cluster bundle..."
            "$SPLUNK_BIN" apply cluster-bundle
            "$SPLUNK_BIN" restart
        fi
    else
        echo -e "$ip is the remote host."
        # [FIX] 原版 SSH heredoc 引號嵌套混亂導致語法錯誤，改用 heredoc 方式
        # [FIX] 原版 remote block 中誤用 `$LOCAL_FILE` 和 `"REMOTE_FILE"` (少 $)
        ssh -tt ${SSH_OPTS} "${SSH_USER}@${ip}" bash <<ENDSSH
REMOTE_FILE='${INDEX_MASTER_FILE}'
INDEX='${index}'
if [[ ! -f "\$REMOTE_FILE" ]]; then
    echo "This is not index-master (config file not found)."
    exit 1
fi
if grep -q "^\[\${INDEX}\]" "\$REMOTE_FILE"; then
    echo "Index '\${INDEX}' is already configured."
else
    printf '\n[%s]\nhomePath = \$SPLUNK_DB/%s/db\ncoldPath = \$SPLUNK_DB/%s/colddb\nthawedPath = \$SPLUNK_DB/%s/thaweddb\nrepFactor = 1\n' \
        "\$INDEX" "\$INDEX" "\$INDEX" "\$INDEX" >> "\$REMOTE_FILE"
    /opt/splunk/bin/splunk apply cluster-bundle
    /opt/splunk/bin/splunk restart
fi
ENDSSH
    fi
}

# ============================================================
# Function 2: Check iFrame Connection
# ============================================================
check_iframe() {
    local IFRAME_FILE="./iframe_alerts/iframe.txt"

    if [[ ! -f "$IFRAME_FILE" ]]; then
        echo -e "${RED}$IFRAME_FILE doesn't exist.${RESET}"
        return
    fi

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local iframe="${line#*:}"
        local src_part="${iframe#*src=\"}"
        local iframe_url="${src_part%%\"*}"

        # [FIX] 原版: curl 缺少 `-w` flag，`%{http_code}` 從未輸出，response 永遠空字串
        # [FIX] 改為判斷 HTTP 2xx 才算正常，而非只判斷 response 非空
        local response
        response=$(curl -s -o /dev/null -w "%{http_code}" "$iframe_url")

        if [[ "$response" =~ ^2 ]]; then
            echo -e "[${GREEN}OK${RESET}] $iframe_url (HTTP $response)"
        else
            echo -e "[${RED}NOT OK${RESET}] $iframe_url (HTTP $response)"
        fi
    done < "$IFRAME_FILE"
}

# ============================================================
# Function: linux_file - ACA USB detect (Linux)
# ============================================================
linux_file() {
    local file="$1"
    local type="$2"
    local user="$3"
    local iip="$4"
    local dip="$5"

    if [[ ! -s "$file" ]]; then
        echo -e "${RED}$file doesn't exist or is empty.${RESET}"
        return
    fi

    # [OPTIMIZE] 預先組好 content，避免在迴圈內重複產生
    local content1 content2 content3
    content1=$(printf '%s\n' \
        "[monitor:///var/log/devMon.log]" \
        "disabled = false" \
        "index = usb" \
        "sourcetype = linux:usb:detect")
    content2=$(printf '%s\n' \
        "[tcpout]" \
        "defaultGroup = default-autolb-group" \
        "" \
        "[tcpout:default-autolb-group]" \
        "server = ${iip}:9997" \
        "" \
        "[tcpout-server://${iip}:9997]")
    # [FIX] 原版 deploymentclient.conf 的 key 有誤: `target=broker` → `target-broker`
    content3=$(printf '%s\n' \
        "[target-broker:deploymentServer]" \
        "targetUri = ${dip}:8089")

    while IFS= read -r linuxip; do
        # [FIX] 原版: `if [[ -z "$linuxip" ]] && continue` 語法錯誤，&& 不能用在 if 條件後
        [[ -z "$linuxip" ]] && continue

        if [[ "$type" == "local" ]]; then
            if [[ -d "${SCRIPTS_BASE}/splunk" ]]; then
                echo -e "$linuxip is a Splunk node, skipping."
            else
                local dir1="${SCRIPTS_BASE}/linux_test"
                local dir2="${SCRIPTS_BASE}/linux_test1"
                # [FIX] 原版 local 段: 用 `local_file2/3` 宣告但寫入時用 `$file2/$file3` (變數名稱不一致)
                # [FIX] 原版用 if/else mkdir，改用 ensure_dir 統一處理
                ensure_dir "$dir1" || continue
                printf '%s\n' "$content1" > "${dir1}/inputs.conf"
                ensure_dir "$dir2" || continue
                printf '%s\n' "$content2" > "${dir2}/outputs.conf"
                printf '%s\n' "$content3" > "${dir2}/deploymentclient.conf"
            fi
        else
            if ssh -n -T ${SSH_OPTS} "${user}@${linuxip}" "[ -d '${SCRIPTS_BASE}/splunk' ]"; then
                echo -e "$linuxip is a Splunk node."
                # [FIX] 原版: rm -rf authorized_keys 後忘記 continue，仍會繼續寫 config
                ssh -n -T ${SSH_OPTS} "${user}@${linuxip}" \
                    "rm -f '/home/${user}/.ssh/authorized_keys'"
            else
                ssh -n -T ${SSH_OPTS} "${user}@${linuxip}" bash <<ENDSSH
mkdir -p "${SCRIPTS_BASE}/linux_test" "${SCRIPTS_BASE}/linux_test1"
printf '%s\n' "${content1}" > "${SCRIPTS_BASE}/linux_test/inputs.conf"
printf '%s\n' "${content2}" > "${SCRIPTS_BASE}/linux_test1/outputs.conf"
printf '%s\n' "${content3}" > "${SCRIPTS_BASE}/linux_test1/deploymentclient.conf"
rm -f "/home/${user}/.ssh/authorized_keys"
ENDSSH
            fi
        fi
    done < "$file"
}

# ============================================================
# Function: solaris_file - ACA USB detect (Solaris)
# ============================================================
solaris_file() {
    local file="$1"
    local type="$2"
    local user="$3"
    local iip="$4"

    if [[ ! -s "$file" ]]; then
        echo -e "${RED}$file doesn't exist or is empty.${RESET}"
        return
    fi

    local content1 content2
    content1=$(printf '%s\n' \
        "[monitor:///tmp/devMon.log]" \
        "disabled = false" \
        "index = usb" \
        "sourcetype = linux:usb:detect")
    content2=$(printf '%s\n' \
        "[tcpout]" \
        "defaultGroup = default-autolb-group" \
        "" \
        "[tcpout:default-autolb-group]" \
        "server = ${iip}:9997" \
        "" \
        "[tcpout-server://${iip}:9997]")

    while IFS= read -r solarisip; do
        # [FIX] 同 linux_file: `if [[ -z ]] && continue` 語法錯誤
        [[ -z "$solarisip" ]] && continue

        if [[ "$type" == "local" ]]; then
            if [[ -d "${SCRIPTS_BASE}/splunk" ]]; then
                echo -e "$solarisip is a Splunk node, skipping."
            else
                local dir1="${SCRIPTS_BASE}/solaris_test"
                local dir2="${SCRIPTS_BASE}/solaris_test1"
                # [FIX] 原版 local_file2 宣告後寫入用 $file2 (不一致)
                ensure_dir "$dir1" || continue
                printf '%s\n' "$content1" > "${dir1}/inputs.conf"
                ensure_dir "$dir2" || continue
                printf '%s\n' "$content2" > "${dir2}/outputs.conf"
            fi
        else
            if ssh -n -T ${SSH_OPTS} "${user}@${solarisip}" "[ -d '${SCRIPTS_BASE}/splunk' ]"; then
                echo -e "$solarisip is a Splunk node."
                ssh -n -T ${SSH_OPTS} "${user}@${solarisip}" \
                    "rm -f '/home/${user}/.ssh/authorized_keys'"
            else
                ssh -n -T ${SSH_OPTS} "${user}@${solarisip}" bash <<ENDSSH
mkdir -p "${SCRIPTS_BASE}/solaris_test" "${SCRIPTS_BASE}/solaris_test1"
printf '%s\n' "${content1}" > "${SCRIPTS_BASE}/solaris_test/inputs.conf"
printf '%s\n' "${content2}" > "${SCRIPTS_BASE}/solaris_test1/outputs.conf"
rm -f "/home/${user}/.ssh/authorized_keys"
ENDSSH
            fi
        fi
    done < "$file"
}

# ============================================================
# Function: clam_file - ClamAV config
# ============================================================
clam_file() {
    local file="$1"
    local type="$2"
    local user="$3"
    local ip="$4"

    if [[ ! -s "$file" ]]; then
        echo -e "${RED}$file doesn't exist or is empty.${RESET}"
        return
    fi

    local content1 content2
    content1=$(printf '%s\n' \
        "[monitor:///var/log/clamav]" \
        "disabled = false" \
        "index = clamav")
    content2=$(printf '%s\n' \
        "[tcpout]" \
        "defaultGroup = splunkssl" \
        "useACK = true" \
        "[tcpout:splunkssl]" \
        "server = ${ip}:9997" \
        "compressed = true" \
        "sslRootCAPath = /etc/puppetlabs/puppet/ssl/certs/ca.pem" \
        "sslCertPath = /opt/splunkforwarder/etc/system/local/splunkfkey.pem" \
        "sslVerifyServerCert = true")

    while IFS= read -r clamip; do
        # [FIX] 原版: `IFS=read` 少了空格，IFS 被賦值為 "read"
        # [FIX] 原版: `if [[ -z $clamip" ]]` 缺少開頭引號，語法錯誤
        [[ -z "$clamip" ]] && continue

        if [[ "$type" == "local" ]]; then
            # [FIX] 原版: echo 使用 `$solarisip` (錯誤變數名)，應為 `$clamip`
            if [[ -d "${SCRIPTS_BASE}/splunk" ]]; then
                echo -e "$clamip is a Splunk node, skipping."
            else
                local dir="${SCRIPTS_BASE}/clamav_test"
                ensure_dir "$dir" || continue
                printf '%s\n' "$content1" > "${dir}/inputs.conf"
                printf '%s\n' "$content2" > "${dir}/outputs.conf"
            fi
        else
            # [FIX] 原版: `"[ -d /home/tomyang/scripts/splunk]"` 缺少 `]` 前的空格
            if ssh -n -T ${SSH_OPTS} "${user}@${clamip}" "[ -d '${SCRIPTS_BASE}/splunk' ]"; then
                # [FIX] 原版: echo 用 `$clamavip`(未定義)、ssh 用 `$solarisip`(錯誤)
                echo -e "$clamip is a Splunk node."
                ssh -n -T ${SSH_OPTS} "${user}@${clamip}" \
                    "rm -f '/home/${user}/.ssh/authorized_keys'"
            else
                ssh -n -T ${SSH_OPTS} "${user}@${clamip}" bash <<ENDSSH
mkdir -p "${SCRIPTS_BASE}/clamav_test"
printf '%s\n' "${content1}" > "${SCRIPTS_BASE}/clamav_test/inputs.conf"
printf '%s\n' "${content2}" > "${SCRIPTS_BASE}/clamav_test/outputs.conf"
rm -f "/home/${user}/.ssh/authorized_keys"
ENDSSH
            fi
        fi
    done < "$file"
}

# ============================================================
# Main Menu
# ============================================================
show_menu() {
    echo "--------------------------------------------------------------"
    echo "'                                                            '"
    echo -e "   ${BOLD}${GREEN}Welcome to use Splunk Dialog Tool!!!${RESET}"
    echo "'                                                            '"
    echo "--------------------------------------------------------------"
    echo -e "   ${RED}What service would you like to use?${RESET}"
    echo "(1) Add the index to index master"
    echo "(2) Check the iFrame connection"
    echo "(3) Dispatch the config"
    echo "(4) Exit"
    echo ""
}

# ============================================================
# Main Loop
# ============================================================
while true; do
    show_menu
    read -p "Please enter your choice [1-4]: " choice

    # [OPTIMIZE] 原版 if/elif 鏈改為 case 語句，更清晰且效能更佳
    case "$choice" in
        1)
            add_index
            ;;
        2)
            check_iframe
            ;;
        3)
            echo -e "${RED}What software config would you like to use?${RESET}"
            echo "(a) ClamAV"
            echo "(b) ACA USB detect - Solaris"
            echo "(c) ACA USB detect - Linux"
            echo "(d) Back to main menu"
            echo ""
            read -p "Please enter your choice [a-d]: " software

            case "$software" in
                a)
                    read -p "What is your indexer IP? " iip
                    validate_ip "$iip" || continue
                    clam_file "./clamav/local.txt"  "local"  "$SSH_USER" "$iip"
                    clam_file "./clamav/remote.txt" "remote" "$SSH_USER" "$iip"
                    # [FIX] 原版用 `rm -rf` 刪文字檔，危險且過度；改用 `rm -f`
                    rm -f "./clamav/local.txt" "./clamav/remote.txt"
                    ;;
                b)
                    read -p "What is your indexer IP? " iip1
                    validate_ip "$iip1" || continue
                    solaris_file "./aca_solaris/local.txt"  "local"  "$SSH_USER" "$iip1"
                    solaris_file "./aca_solaris/remote.txt" "remote" "$SSH_USER" "$iip1"
                    rm -f "./aca_solaris/local.txt" "./aca_solaris/remote.txt"
                    ;;
                c)
                    read -p "What is your deployment server IP? " dip2
                    read -p "What is your indexer IP? " iip2
                    validate_ip "$dip2" || continue
                    validate_ip "$iip2" || continue
                    linux_file "./aca_linux/local.txt"  "local"  "$SSH_USER" "$iip2" "$dip2"
                    linux_file "./aca_linux/remote.txt" "remote" "$SSH_USER" "$iip2" "$dip2"
                    rm -f "./aca_linux/local.txt" "./aca_linux/remote.txt"
                    ;;
                d)
                    continue
                    ;;
                *)
                    echo -e "${RED}Invalid input! Please enter a choice from a to d.${RESET}"
                    ;;
            esac
            ;;
        4)
            echo "Goodbye!"
            break
            ;;
        *)
            # [FIX] 原版錯字: "fron" → "from"
            echo -e "${RED}Invalid input! Please enter a choice from 1 to 4.${RESET}"
            ;;
    esac
    echo ""
done
