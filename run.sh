#!/bin/bash

# Pull the latest changes from the repository

current_path="$(cd `dirname $0`; pwd)"
echo "INFO: current_path: ${current_path}"
pushd "${current_path}/notes2memos"
git pull --quiet origin main
if [ $? -eq 0 ]; then
    echo "Successfully pulled latest code."
    echo "Last commit message:"
    git log -1 --pretty=%B
else
    echo "Failed to pull latest code. Exiting."
fi
popd
exec bash "${current_path}/excerpt2memo.sh"
