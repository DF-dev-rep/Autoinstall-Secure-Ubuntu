#!/bin/bash

log_info() {
    echo "[INFO] $1" | tee -a /root/setup.log
}

log_error() {
    echo "[ERROR] $1" | tee -a /root/setup.log >&2
}

