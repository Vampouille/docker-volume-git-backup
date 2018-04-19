#!/bin/bash

trap 'exit 0'  SIGKILL SIGTERM SIGHUP SIGINT EXIT

first=true

while true
do
    if [ ! -f $WATCH_FILE ]; then
        if $first; then
            printf "$WATCH_FILE does not exist (yet ?).."
            first=0
        fi
        printf "."
        sleep ${SLEEPING_TIME:-1}
        continue
    else
        echo "$WATCH_FILE exists"
    fi

    # set up watches:
    inotifywait -e modify $WATCH_FILE

    # Temporary remove flag file to avoid commit of this file
    if [ -n $INITIALIZED_FILE_FLAG ] && [ -f $INITIALIZED_FILE_FLAG ]; then
      rm -f $INITIALIZED_FILE_FLAG
    fi

    # commit all files from current dir:
    git add --all .

    # commit with custom message:
    msg=`eval $GIT_COMMIT_MESSAGE`
    git commit -m "${msg:-"no commit message"}"

    # Restore flag file
    if [ -n $INITIALIZED_FILE_FLAG ]; then
      touch $INITIALIZED_FILE_FLAG
    fi

    if [ $REMOTE_NAME ] && [ $REMOTE_URL ]; then
        # push to repository in the background
        git push $REMOTE_NAME $REMOTE_BRANCH &
    fi
done
