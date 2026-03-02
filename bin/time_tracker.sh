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
  local local_repo="$(get_local_repo)"
  local exit_code=$?

  if [[ $local_repo == "" ]]; then
    unset _TRACK_CMD
    unset _STEP_START
    return
  fi

  # If _TRACK_CMD exists, it means the previous command was tracked
  if [[ -n "$_TRACK_CMD" && -n "$_STEP_START" ]]; then
    local end_step=$EPOCHREALTIME
    local duration_raw=$(( end_step - _STEP_START ))
    local duration_pretty=$(format_time $duration_raw)

    # Check status of the previous command
    local cmd_status="SUCCESS"
    [[ $exit_code -ne 0 ]] && cmd_status="FAILED"

    local display_cmd=${_LAST_CMD:0:30}

    # Ensure header exists
    local table_columns="| %-19s | %-30s | %-7s | %8s | %-60s |\n"
    local -a table_headers=("TIMESTAMP" "COMMAND" "STATUS" "DURATION" "REPO")

    local header=$(printf "$table_columns" "${table_headers[@]}")

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


    printf "$table_columns" \
      "$(date +"$DATE_FORMAT")" \
      "$display_cmd" \
      "$cmd_status" \
      "$duration_pretty" \
      "$local_repo">> "$LOG_FILE"

    unset _TRACK_CMD
    unset _STEP_START
  fi
}

is_path_inside_repo() {
  local path="$PWD"

  while [ "$path" != "/" ]; do
    if [ -d "$path/.git" ]; then
      return 0
    fi
    path="${path:h}"
  done
  return 1

}

get_repo_url() {
  git config --get remote.origin.url
}

get_local_repo() {
  local local_repo=""
  if is_path_inside_repo; then
    local repourl=$(get_repo_url)
    if [[ -n "$TK_REPOS" ]]; then
      for repo in ${TK_REPOS[@]}; do
        if [[ "$repourl" == "$repo"* ]]; then
          echo "$repo"
          return 0
        fi
      done
    fi
  fi
  return 0
}


autoload -Uz add-zsh-hook
add-zsh-hook preexec preexec_track_metrics
add-zsh-hook precmd precmd_track_metrics
