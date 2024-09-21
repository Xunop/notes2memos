# Notes to Memos

This is a script that push reading notes to my memos web app. It is a simple script that reads some text files and push to my memos web app.

The memos web app I use is [memos](https://github.com/usememos/memos).

## Pre-requisite

1. You need to have an access token for the memos web app.
2. You need to have the web url of the memos web app.
3. You need to have the `jq` installed.

This script is for my personal use. You can modify the script to suit your needs.

Here is the structure of the text files:

```
notes
├── access-token
├── error_reponse.log
├── excerpt2memo.sh -> notes2memos/excerpt2memo.sh
├── formatted-excerpt
│   ├── [摘抄]01-红楼梦（上）_epub.txt
├── log
│   └── log.log
├── notes2memos
│   ├── excerpt2memo.sh
│   ├── LICENSE
│   ├── README.md
│   └── run.sh
├── run.sh -> notes2memos/run.sh
├── temp
│   ├── added-excerpt.txt
│   ├── book-name.txt
│   ├── new-content.txt
│   └── new-excerpt.txt
├── web-url
├── 摘抄
│   └── [摘抄]百年孤独_加西亚_马尔克斯_epub.txt
└── 笔记
```

## How to use

1. Provide the `ACCESS_TOKEN` in the `access-token` file and `WEB_URL` in the file `web-url`.
2. Run the script

The `run.sh` is for myself. You can run the script by `bash excerpt.sh`

### My setup

I have a cron job that runs `run.sh` every day at 11:20 PM.

## TODO

- [x] Push the excerpt to memos web app.
- [ ] Push the notes to memos web app.
