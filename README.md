# Notes to Memos

This is a script that push reading notes to my memos web app. It is a simple script that reads some text files and push to my memos web app.

The memos web app I use is [memos](https://github.com/usememos/memos).

## How to use

1. Provide the `ACCESS_TOKEN` in the `access-token` file and `WEB_URL` in the file `web-url`.
2. Run the script

The `run.sh` is for myself. You can run the script by `bash excerpt.sh`

### My setup

I have a cron job that runs `run.sh` every day at 11:20 PM.

## TODO

- [x] Push the excerpt to memos web app.
- [ ] Push the notes to memos web app.
