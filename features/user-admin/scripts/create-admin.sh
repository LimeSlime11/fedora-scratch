#!/bin/bash
set -e

if ! id admin >/dev/null 2>&1; then
    useradd \
        --create-home \
        --groups wheel \
        --shell /bin/bash \
        admin
fi

echo 'admin:admin' | chpasswd