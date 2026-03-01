zmodload zsh/datetime

LOG_FILE="$HOME/track_build_metrics.txt"
DATE_FORMAT="%Y-%m-%d %H:%M:%S"


format_time() {
    local -i total=$(( $1 + 0.5 )) 
    
    local h=$(( total / 3600 ))
    local m=$(( (total % 3600) / 60 ))
    local s=$(( total % 60 ))
    
    if (( h > 0 )); then
        printf "%dh %dm %ds" $h $m $s
    elif (( m > 0 )); then
        printf "%dm %ds" $m $s
    else
        printf "%ds" $s
    fi
}

preexec_track_metrics() {
    _STEP_START=$EPOCHREALTIME
    _LAST_CMD="$1"
}

precmd_track_metrics() {
    local exit_code=$?
    
    if [[ -n "$_LAST_CMD" && -n "$_STEP_START" ]]; then
        local end_step=$EPOCHREALTIME
        local duration_raw=$(( end_step - _STEP_START ))
        local duration_pretty=$(format_time $duration_raw)
        local cmd_status="SUCCESS"
        [[ $exit_code -ne 0 ]] && cmd_status="FAILED"

        local display_cmd=${_LAST_CMD:0:30}
        
        local header="TIMESTAMP           | COMMAND                        | STATUS  | DURATION"
        if [[ ! -f "$LOG_FILE" ]]; then
            echo "$header" > "$LOG_FILE"
            echo "--------------------------------------------------------------------------" >> "$LOG_FILE"
        elif [[ "$(head -n 1 "$LOG_FILE")" != "$header" ]]; then
            local temp_log=$(mktemp)
            echo "$header" > "$temp_log"
            echo "--------------------------------------------------------------------------" >> "$temp_log"
            cat "$LOG_FILE" >> "$temp_log"
            mv "$temp_log" "$LOG_FILE"
        fi
        
        printf "%-19s | %-30s | %-7s | %s\n" \
            "$(date +"$DATE_FORMAT")" \
            "$display_cmd" \
            "$cmd_status" \
            "$duration_pretty" >> "$LOG_FILE"
    
        unset _LAST_CMD
        unset _STEP_START
    fi
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec preexec_track_metrics
add-zsh-hook precmd precmd_track_metrics