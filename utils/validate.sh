#!/bin/bash

validate_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "This script must be run as root. Use sudo."
        exit 1
    fi
}

