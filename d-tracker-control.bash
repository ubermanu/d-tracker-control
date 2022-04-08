#!/bin/bash

if [ -z $TRACKER ]; then
    TRACKER=d-tracker-cli
fi

if ! which $TRACKER &> /dev/null; then
    echo "$TRACKER not found in path"
    return 1
fi

COLOR_INACTIVE="%{F#6b6b6b}"
END_COLOR="%{F-}"

NOTIFICATIONS="yes"

TASK_ICON=" "
TASK_NAME=""
TASK_PROJECT=""

FORMAT='$TASK_ICON $TASK_NAME \($TASK_PROJECT\)'

# prints current task alongside its project
# TODO: Add support for more formats
# TODO: Add time spent
# TODO: Add inactive color and format
function output() {
    getActiveTask
    if [ "$TASK" != "" ];
    then
        eval echo "$FORMAT"
    else
        echo "$COLOR_INACTIVE$TASK_ICON Start a new task$END_COLOR"
    fi
}

# the final time should not be a date (-----)
# if so it means there is no active task
function getActiveTask() {
    TASK=$(d-tracker-cli list-today-tasks | sed -n \$p)
    if [ $(echo $TASK | cut -d'|' -f4) != '---' ]; then
        TASK=""
        TASK_NAME=""
        TASK_PROJECT=""
    else
        TASK_NAME=$(echo $TASK | cut -d'|' -f5) 
        TASK_PROJECT=$(echo $TASK | cut -d'|' -f2)
    fi
}

# update output
# TODO: set custom sleep value
# TODO: ask for subscription system with d-tracker-cli?
function listen() {
    while true; do
        output
        sleep 2
    done
}

# start a new task
# read task name and project from user prompt (rofi)
function startTask() {
    PROJECT_NEW=$($TRACKER list-projects | sed 's/^[0-9]\+|//g' | sort | rofi -dmenu -theme-str 'entry { placeholder: "What project are you working on?"; }')

    if [ "$PROJECT_NEW" == "" ]; then
        exit 1
    fi

    TASK_NEW=$(echo "" | rofi -dmenu -theme-str "entry { placeholder: \"What are you going to do? ($PROJECT_NEW)\"; } listview { enabled: false; }")

    if [ "$PROJECT_NEW" != "" ] && [ "$TASK_NEW" != "" ]; then
        $TRACKER add-task $TASK_NEW $PROJECT_NEW
        getActiveTask
        [ "$TASK" != "" ] && notify-send "Task started" "Description: $TASK_NEW\nProject: $PROJECT_NEW"
    fi
}

# stop the current task
# TODO: check if the notification option is enabled
function stopTask() {
    getActiveTask
    [ "$TASK" != "" ] && notify-send "Task stopped" "Description: $TASK_NAME\nProject: $TASK_PROJECT"
    $TRACKER stop-in-progress
}

# if a task is running stop it
# if there is not task, create one
function toggleTask() {
    getActiveTask
    if [ "$TASK" != "" ]; then
        stopTask
    else
        startTask
    fi
}

# print usage
function usage() {
    echo "\
Usage: $0 ACTION
Actions:
  help              display this message and exit
  output            print the d-tracker status once
  listen            listen for changes in d-tracker to automatically update
                    this script's output
  new               creates a new task (prompted with rofi)
  stop              stops the currently active task
  toggle            creates a new task if there is no active task,
                    otherwise stops the currently active task"
}

case "$1" in
    listen)
        listen
        ;;
    output)
        output
        ;;
    toggle)
        toggleTask
        ;;
    new)
        startTask
        ;;
    stop)
        stopTask
        ;;
    help)
        usage
        ;;
    *)
        usage
        ;;
esac
