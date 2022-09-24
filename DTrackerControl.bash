#!/bin/bash

FORMAT=' <task-name> (<task-project>) <elapsed-time>'
FORMAT_INACTIVE='%{F#6b6b6b}%{F-}'
NOTIFICATIONS="yes"

# task related variables (globally stored)
TASK=""
TASK_NAME=""
TASK_PROJECT=""
TASK_START_DATE=""
TASK_START_TIME=""
TASK_ELAPSED_TIME=""

# console utils
function console::error() {
    echo -e "\e[01;31m"$1"\e[0m"
}

# send a notification if the option is enabled
function notification::send() {
    if [ "$NOTIFICATIONS" == "yes" ]; then
        notify-send -i "task" "$1" "$2"
    fi
}

# if the task is not ended, its date should be a sequence of 3 hyphens
# otherwise it means the last task has been stopped
function updateActiveTaskVars() {
    TASK=$(d-tracker-cli list-today-tasks | sed -n \$p)
    if [ $(echo $TASK | cut -d'|' -f4) != '---' ]; then
        TASK=""
        TASK_NAME=""
        TASK_PROJECT=""
        TASK_START_DATE=""
        TASK_START_TIME=""
        TASK_ELAPSED_TIME=""
    else
        TASK_NAME=$(echo $TASK | cut -d'|' -f5)
        TASK_PROJECT=$(echo $TASK | cut -d'|' -f2)
        TASK_START_DATE=$(echo $TASK | cut -d'|' -f3 | cut -d'T' -f1)
        TASK_START_TIME=$(echo $TASK | cut -d'|' -f3 | cut -d'T' -f2)
        TASK_ELAPSED_TIME=$(date -u -d @$(($(date +%s) - $(date +%s -d "$(echo "$TASK" | cut -d'|' -f3)"))) +%H:%M:%S)
    fi
}

# prints current task alongside its project
function outputCommand() {
    updateActiveTaskVars
    if [ "$TASK" != "" ]; then
        local str="$FORMAT"
        str="${str//<task-name>/$TASK_NAME}"
        str="${str//<task-project>/$TASK_PROJECT}"
        str="${str//<start-date>/$TASK_START_DATE}"
        str="${str//<start-time>/$TASK_START_TIME}"
        str="${str//<elapsed-time>/$TASK_ELAPSED_TIME}"
        echo "$str"
    else
        echo "$FORMAT_INACTIVE"
    fi
}

# update output
# TODO: set custom sleep value
# TODO: ask for subscription system with d-tracker-cli?
function listenCommand() {
    while true; do
        outputCommand
        sleep 2
    done
}

# start a new task
# read task name and project from user prompt (rofi)
function createTaskCommand() {
    PROJECT_NEW=$(d-tracker-cli list-projects | sed 's/^[0-9]\+|//g' | sort | rofi -dmenu -theme-str 'entry { placeholder: "What project are you working on?"; }')

    if [ "$PROJECT_NEW" == "" ]; then
        exit 1
    fi

    TASK_NEW=$(echo "" | rofi -dmenu -theme-str "entry { placeholder: \"What are you going to do? ($PROJECT_NEW)\"; } listview { enabled: false; }")

    if [ "$PROJECT_NEW" != "" ] && [ "$TASK_NEW" != "" ]; then
        d-tracker-cli add-task "$TASK_NEW" "$PROJECT_NEW"
        updateActiveTaskVars

        if [ "$TASK" != "" ]; then
            notification::send "Task started" "Description: $TASK_NAME\nProject: $TASK_PROJECT"
        fi
    fi

    # reset values
    PROJECT_NEW=""
    TASK_NEW=""
}

# stop the current task
function stopActiveTaskCommand() {
    updateActiveTaskVars

    if [ "$TASK" != "" ]; then
        notification::send "Task stopped" "Description: $TASK_NAME\nProject: $TASK_PROJECT\nStarted At: $TASK_START_TIME\nStopped At: $(date +"%H:%M:%S")"
    fi

    d-tracker-cli stop-in-progress
}

# if a task is running stop it
# if there is not task, create one
function toggleCommand() {
    updateActiveTaskVars
    if [ "$TASK" != "" ]; then
        stopActiveTaskCommand
    else
        createTaskCommand
    fi
}

# print usage
function usage() {
    echo "\
Usage: $0 ACTION [OPTIONS]

Options:
  --help
    Print this help message.
  --format
    Set the format for the output.
    Default: '$FORMAT'
  --format-inactive
    Set the format for the inactive state.
    Default: '$FORMAT_INACTIVE'
  --notifications <yes|no>
    Enabled or disable notifications.
    Default: '$NOTIFICATIONS'

Format:
  <task-name>
    The name of the task.
  <task-project>
    The project of the task.
  <start-date>
    The starting date of the task (Y-m-d).
  <start-time>
    The time at which the task started (H:m:s).
  <elapsed-time>
    The elapsed time of the active task (H:m:s).

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

# check if d-tracker is installed
if ! which d-tracker-cli &>/dev/null; then
    console::error "d-tracker-cli not found in path"
    return 1
fi

# stolen from `polybar-pulseaudio-control`
while [[ "$1" = --* ]]; do
    unset arg
    unset val
    if [[ "$1" = *=* ]]; then
        arg="${1//=*/}"
        val="${1//*=/}"
        shift
    else
        arg="$1"
        # Support space-separated values, but also value-less flags
        if [[ "$2" != --* ]]; then
            val="$2"
            shift
        fi
        shift
    fi
    case "$arg" in
    --format)
        FORMAT="$val"
        ;;
    --format-inactive)
        FORMAT_INACTIVE="$val"
        ;;
    --notifications)
        NOTIFICATIONS="$val"
        ;;
    # Undocumented because the `help` action already exists, but makes the
    # help message more accessible.
    --help)
        usage
        exit 0
        ;;
    *)
        echo "Unrecognised option: $arg" >&2
        exit 1
        ;;
    esac
done

case "$1" in
listen)
    listenCommand
    ;;
output)
    outputCommand
    ;;
toggle)
    toggleCommand
    ;;
new)
    createTaskCommand
    ;;
stop)
    stopActiveTaskCommand
    ;;
help)
    usage
    ;;
*)
    usage
    ;;
esac
