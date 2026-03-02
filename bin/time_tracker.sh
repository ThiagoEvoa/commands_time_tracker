zmodload zsh/datetime

LOG_FILE="$HOME/track_build_metrics.txt"
DATE_FORMAT="%Y-%m-%d %H:%M:%S"

format_time() {
    local -i total=$(( $1 + 0.5 )) 
    local h=$(( total / 3600 ))
    local m=$(( (total % 3600) / 60 ))
    local s=$(( total % 60 ))
    
    if (( h > 0 )); then printf "%dh %dm %ds" $h $m $s
    elif (( m > 0 )); then printf "%dm %ds" $m $s
    else printf "%ds" $s; fi
}

preexec_track_metrics() {
    # 1. Capture the command being executed
    local cmd="$1"

    # 2. Filter: Only proceed if it contains keywords
    if [[ "$cmd" =~ (flutter|dart|make|pod|gradle|cache) ]]; then
        _TRACK_CMD="$cmd"
        _STEP_START=$EPOCHREALTIME
    else
        unset _TRACK_CMD
        unset _STEP_START
    fi
}

precmd_track_metrics() {
    # If _TRACK_CMD exists, it means the previous command was tracked
    if [[ -n "$_TRACK_CMD" && -n "$_STEP_START" ]]; then
        local end_step=$EPOCHREALTIME
        local duration_raw=$(( end_step - _STEP_START ))
        local duration_pretty=$(format_time $duration_raw)
        
        # Check status of the previous command
        local cmd_status="SUCCESS"
        [[ $? -ne 0 ]] && cmd_status="FAILED"

        # Ensure header exists
        local header="TIMESTAMP           | COMMAND                        | STATUS  | DURATION"
        if [[ ! -f "$LOG_FILE" ]]; then
            echo "$header" > "$LOG_FILE"
            echo "--------------------------------------------------------------------------" >> "$LOG_FILE"
        fi
        
        printf "%-19s | %-30s | %-7s | %s\n" \
            "$(date +"$DATE_FORMAT")" \
            "${_TRACK_CMD:0:30}" \
            "$cmd_status" \
            "$duration_pretty" >> "$LOG_FILE"
    
        unset _TRACK_CMD
        unset _STEP_START
    fi
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec preexec_track_metrics
add-zsh-hook precmd precmd_track_metrics