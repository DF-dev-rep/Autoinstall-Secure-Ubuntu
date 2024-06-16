#!/bin/bash

download_script() {
    local script_name="$1"
    local url="$2"
    wget -O "/root/$script_name" "$url/$script_name"
    if [ $? -ne 0 ]; then
        log_error "Failed to download $script_name from $url"
        return 1
    fi
    chmod +x "/root/$script_name"
    log_info "$script_name downloaded and made executable."
    return 0
}

