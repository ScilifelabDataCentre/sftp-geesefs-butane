#!/bin/bash

set -o errexit
set -o nounset

s3_bucket_name=$(cat ~/s3_bucket_name)
s3_endpoint=$(cat ~/s3_endpoint)

/usr/local/bin/geesefs --shared-config ~/.aws/credentials \
                       --endpoint "$s3_endpoint" \
                       --uid $(id -u) \
                       --gid $(id -g) \
                       --log-file stderr \
                       --dir-mode 0755 \
                       --file-mode 0644 \
                       --no-checksum \
                       --memory-limit 4000 \
                       --max-flushers 8 \
                       --max-parallel-parts 8 \
                       --part-sizes 100 \
                       --log-file syslog \
                       "$s3_bucket_name" /srv/sftp_geesefs/chroot/$USER/$USER
