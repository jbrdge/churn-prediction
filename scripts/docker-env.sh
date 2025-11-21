#!/usr/bin/env bash
# Set host UID/GID for compose so containers write as your user.
export HOST_UID=$(id -u)
export HOST_GID=$(id -g)
echo "HOST_UID=$HOST_UID HOST_GID=$HOST_GID"
