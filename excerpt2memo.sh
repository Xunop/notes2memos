#!/bin/bash

# This script is used to sync article excerpt to memos
# `book-name` is the file that contains the book name
# `new-content` is the file that new content from excerpt file(including book-name and modified-file)
# `new-excerpt` is a new excerpt

on_error() {
    echo "Error: $1"
    # echo "Error: $1" > error.log
    # clean
    # Print current time
    echo "-------END--------"
    echo "Current time: $(date)"
    echo "-------END--------"
    exit 1
}

clean() {
    [[ -e "${temp_path}/book-name.txt" ]] && rm "${temp_path}/book-name.txt"
    [[ -e "${temp_path}/new-content.txt" ]] && rm "${temp_path}/new-content.txt"
    [[ -e "${temp_path}/new-excerpt.txt" ]] && rm "${temp_path}/new-excerpt.txt"
    [[ -e "${temp_path}/added-excerpt.txt" ]] && rm "${temp_path}/added-excerpt.txt"
    # [[ -e "${temp_path}/modified-file.txt" ]] && rm "${temp_path}/modified-file.txt"
    [[ -e "${temp_path}" ]] && rm -rf "${temp_path}"
}

# Initialize, touch files
init() {
    clean
    mkdir "${temp_path}"
    touch "${temp_path}/book-name.txt"
    touch "${temp_path}/new-content.txt"
    touch "${temp_path}/new-excerpt.txt"
    touch "${temp_path}/added-excerpt.txt"
    ACCESS_TOKEN=$(cat "${current_path}/access-token")
    WEB_URL=$(cat "${current_path}/web-url")
    # touch "${temp_path}/modified-file.txt"
}

trap 'on_error' ERR

send_to_memo() {
    echo "Enter send_to_memo"
    format_excerpt "$1"
    [[ ! -e "${temp_path}/new-excerpt.txt" ]] && clean && return
    content=$(cat "${temp_path}/new-excerpt.txt")
    # echo "----------"
    # echo "INFO: Current excerpt content:"
    # echo "$content"
    # echo "----------"
    echo "INFO: Start to send excerpt to memos"
    data='{
        "content": "@CONTENT",
        "visibility": "PUBLIC"
    }'
    data="${data//@CONTENT/$content}"
    # echo "$data"
    reponse=$(curl -s --location --request POST "${WEB_URL}" \
    --header "Authorization: Bearer ${ACCESS_TOKEN}" \
    --header 'Content-Type: application/json' \
    --data-raw "${data}" \
    --connect-timeout 25)
    reponse=$(echo "$reponse" | jq)

    # echo "$reponse"
    local memo=$(jq .memo <<< "$reponse")
    # Get the memo, if memo is null, then report error and return
    if [[ -z "$memo" || "$memo" == "null" ]]; then
        echo "ERROR: Failed to send excerpt to memos"
        echo "ERROR: Message: $(jq .message <<< "$reponse")"
        [[ ! -e "./error_reponse.log" ]] && touch "./error_reponse.log"
        echo "ERROR: Message: $(jq .message <<< "$reponse")" >> "./error_reponse.log"
        return
    fi
    echo "INFO: Finish to send excerpt to memos"
    echo "INFO: Memo id: $(jq .memo.id <<< "$reponse")"
}

commit() {
    echo "INFO: Start to commit"
    git add "${excerpt_path}/${1}"
    git commit -m "Update article excerpt"
    # git push
    echo "INFO: Finish to commit"
}

# Format excerpt content
# WARN: The json format should be escaped
format_excerpt() {
    echo "INFO: Start to format excerpt content"
    content=$(cat "${temp_path}/new-excerpt.txt" | sed 's/\r//g' | sed 's/\"/\\\"/g')
    book="$1"
    book="${book##*\[摘抄\]}"
    book="${book%_*}"
    # bash strip
    book="${book#"${book%%[![:space:]]*}"}"
    book="${book%"${book##*[![:space:]]}"}"
    book=$(tr ' ' '-' <<< "$book")
    echo "INFO: Current book: $book"
    # Add tags
    # Use book name as the tag
    content="#阅读/$book\n$content"
    [[ ! "$content" =~ "#阅读/摘录" ]] && content="#阅读/摘录 $content"
    echo "$content" | sed -z 's/\n/\\n/g' > "${temp_path}/new-excerpt.txt"
    echo "INFO: Finish to format excerpt content"
}

# Get excerpt content from new-content
# The new excerpt is stored in added-excerpt.txt
get_excerpt_content() {
    # The excerpt file format is as follows:

    # 2024年03月31日 15:46:38  摘自《The Missing README A Guide for the New Software Engineer (Chris Riccomini Dmitriy Ryaboy).pdf》  第205页
    # Keep Design Documents Up-to-Date
    #
    #
    # 2024年03月31日 15:46:52  摘自《The Missing README A Guide for the New Software Engineer (Chris Riccomini Dmitriy Ryaboy).pdf》  第205页
    # We’ve been talking about design documents as a tool to propose and
    # finalize  a  design  before  it’s  implemented

    # So first I get the line number of the pattern
    # Then I can get the excerpt content between two line numbers:
    # sed -n "start_line_number, end_line_numberp" file
    local pattern="^([0-9]{4}年[0-9]{2}月[0-9]{2}日 [0-9]{2}:[0-9]{2}:[0-9]{2}).*第([0-9]+)页"
    local file="${temp_path}/new-content.txt"
    local delimiter=$(grep -n -E "${pattern}" "$file")
    local line_numbers=$(awk -F: '{print $1}' <<< "$delimiter")
    # transform string to array
    local line_numbers=($line_numbers)
    local length=${#line_numbers[@]}
    local title=""
    # echo "length: $length"
    # Clear the last excerpt
    echo '' > "${temp_path}/new-excerpt.txt"
    for ((i = 0; i < $length; i++)); do
        line_number=${line_numbers[i]}
        line=$(sed -n "${line_number}p" "$file")
        if [[ $line =~ $pattern ]]; then
            date="${BASH_REMATCH[1]}"
            page="${BASH_REMATCH[2]}"
            book="$1"
            book="${book##*\[摘抄\]}"
            book="${book%_*}"
            # echo "DEBUG: $book"
            echo "INFO: Current excerpt: $date, $book, $page"
            title="${date} 摘自《${book}》 第 ${page} 页\n"
        fi

        echo "INFO: Start to get excerpt content from line $line_number"
        # If it is the last line, then get the content from the current line to the end of the file
        if [[ $i -eq $((length - 1)) ]]; then
            content=$(sed -n "$((line_number + 1)), \$p" "$file" | tr '\n' ' ' | sed 's/ \+/ /g')
            echo "${title}${content}\n" >> "${temp_path}/new-excerpt.txt"
            break
        fi
        # echo "$line_number, $next_line_number"
        next_line_number=${line_numbers[i + 1]}
        content=$(sed -n "$((line_number + 1)), $((next_line_number - 1))p" "$file" | tr '\n' ' ' | sed 's/ \+/ /g')
        echo "${title}${content}\n" >> "${temp_path}/new-excerpt.txt"
    done
    echo "INFO: Finish to get excerpt content"
}

# Clears the nasty BOM
clear_bom() {
    find "${excerpt_path}" -type f -exec sed -i '1s/^\xEF\xBB\xBF//' {} \;
}

######################
# Main
######################

echo "-------START--------"
echo "Current time: $(date)"
echo "-------START--------"
# Get current path
current_path="$(cd `dirname $0`; pwd)"
echo "INFO: current_path: ${current_path}"

# set -x
# Get article notes path
# notes_path="${current_path}/笔记"
excerpt_path="${current_path}/摘抄"
temp_path="${current_path}/temp"

# Clear BOM prevent from the grep command can't match the pattern
clear_bom

echo "INFO: Start to sync article excerpt to memos"

init
git_status=$(git status --porcelain "${excerpt_path}")
if [[ $git_status == *"??"* ]]; then
    echo "INFO: New article excerpt found"
    # Get new article excerpt file
    git status -u --porcelain "${excerpt_path}" | grep '^??' | sed 's/^?? //g' > "${temp_path}/book-name.txt"
    # Get added content from new excerpt
    while read file; do
        echo "INFO: Handle new excerpt file: $file"
        file=$(echo "$file" | sed 's/"//g')
        # set -x
        cat "${file}" > "${temp_path}/new-content.txt"
        # find . -name "${file}" -exec cat {} \; > "${temp_path}/new-content.txt"
        # set +x
        file=$(basename "$file")
        get_excerpt_content "$file"
        send_to_memo "$file"
        commit "$file"
    done < "${temp_path}/book-name.txt"
fi

init
if [[ $git_status == *"M"* ]]; then
    echo "INFO: Start to sync modified article excerpt to memos"
    # Get modified article excerpt
    m_file=$(git status --porcelain "${excerpt_path}" | grep '^ M' | sed 's/^ M //g')
    echo "INFO: Modified excerpt file:"
    echo '----------'
    echo "$m_file"
    echo '----------'
    echo "$m_file" > "${temp_path}/book-name.txt"
    while read file; do
        echo "INFO: Handle modified excerpt file: $file"
        file=$(echo "$file" | sed 's/"//g')
        diff=$(git diff --ignore-cr-at-eol "${current_path}/${file}" | grep '^+' | grep -v '^+++' | grep -v '^+ ' | grep -v '^+$' | sed 's/^+//g')
        # echo '----------'
        # echo "INFO: Modified excerpt content:"
        # echo "$diff"
        # echo '----------'
        echo "$diff" > "${temp_path}/new-content.txt"
        file=$(basename "$file")
        get_excerpt_content "$file"
        send_to_memo "$file"
        commit "$file"
    done < "${temp_path}/book-name.txt"
fi
echo "-------END--------"
echo "Current time: $(date)"
echo "-------END--------"
