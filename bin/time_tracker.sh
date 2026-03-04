# ==============================================================================
# Zsh Command Tracking Script
# 
# DESCRIPTION:
# Automatically logs the execution duration and status of dev commands (e.g., 
# flutter, gradle) to a local file for productivity analysis.
#
# FLOW:
# 
#
# 1. preexec: Captures start time and validates command scope.
# 2. precmd: Calculates duration, checks success, and persists to log.
#
# REQUIREMENTS:
# - Set $TIME_TRACK_REPOS array in .zshrc to enable repo-specific tracking.
# ==============================================================================

zmodload zsh/datetime 

LOG_FILE="$HOME/track_build_metrics.txt"
DATE_FORMAT="%Y-%m-%d %H:%M:%S"

# --- HELPER FUNCTIONS ---

# Step 1: Format float duration (seconds) into human-readable string.
format_time() {
  local -i total=$(($1 + 0.5)) # Round up to nearest second

  local h=$((total / 3600))
  local m=$(((total % 3600) / 60))
  local s=$((total % 60))

  if ((h > 0)); then
    printf "%dh %dm %ds" $h $m $s
  elif ((m > 0)); then
    printf "%dm %ds" $m $s
  else
    printf "%ds" $s
  fi
}

# Step 2: Zsh 'preexec' hook logic.
# Triggered by shell immediately after user hits Enter but before command runs.
preexec_track_metrics() {
  local cmd="$1"

  # Filter: Only track commands relevant to build/CI tasks to reduce log noise.
  if [[ "$cmd" =~ (flutter|dart|make|pod|gradle|cache|npm|node|nuget) ]]; then
    _TRACK_CMD="$cmd"
    _STEP_START=$EPOCHREALTIME # Capture start time with high precision
  else
    unset _TRACK_CMD
    unset _STEP_START
  fi
}

# Step 3: Zsh 'precmd' hook logic.
# Triggered by shell just before the prompt is displayed (command finished).
precmd_track_metrics() {
  local local_repo="$(get_local_repo)"
  local exit_code=$?

  # Stop if not inside a tracked repo
  if [[ $local_repo == "" ]]; then
    unset _TRACK_CMD
    unset _STEP_START
    return
  fi

  # Proceed only if the command was captured by the 'preexec' filter
  if [[ -n "$_TRACK_CMD" && -n "$_STEP_START" ]]; then
    local end_step=$EPOCHREALTIME
    local duration_raw=$((end_step - _STEP_START))
    local duration_pretty=$(format_time $duration_raw)

    # Determine command outcome
    local cmd_status="SUCCESS"
    [[ $exit_code -ne 0 ]] && cmd_status="FAILED"

    # Step 4: Manage log file formatting
    local table_columns="| %-19s | %-30s | %-7s | %8s | %-60s |\n"
    local -a table_headers=("TIMESTAMP" "COMMAND" "STATUS" "DURATION" "REPO")

    local header=$(printf "$table_columns" "${table_headers[@]}")
    local separator=$(printf '=%.0s' {1..130})

    # Initialize log or ensure header is at the top
    if [[ ! -f "$LOG_FILE" ]]; then
      echo "$header" >"$LOG_FILE"
      echo "$separator" >>"$LOG_FILE"
    elif [[ "$(head -n 1 "$LOG_FILE")" != "$header" ]]; then
      local temp_log=$(mktemp)
      echo "$header" >"$temp_log"
      echo "$separator" >>"$temp_log"
      cat "$LOG_FILE" >>"$temp_log"
      mv "$temp_log" "$LOG_FILE"
    fi

    # Append metrics to log file
    local display_cmd=${_TRACK_CMD:0:30}
    printf "$table_columns" \
      "$(date +"$DATE_FORMAT")" \
      "$display_cmd" \
      "$cmd_status" \
      "$duration_pretty" \
      "$local_repo" >>"$LOG_FILE"

    # Cleanup temporary tracking variables
    unset _TRACK_CMD
    unset _STEP_START
  fi
}

# --- REPOSITORY UTILS ---

# Checks if current working directory is a Git repository
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

# Fetches remote origin URL to filter based on $TIME_TRACK_REPOS
get_repo_url() {
  git config --get remote.origin.url
}

get_local_repo() {
  local local_repo=""
  if is_path_inside_repo; then
    local repourl=$(get_repo_url)
    if [[ -n "$TIME_TRACK_REPOS" ]]; then
      for repo in ${[TIME_TRACK_REPOS@]}; do
        if [[ "$repourl" == "$repo"* ]]; then
          echo "$repourl"
          return 0
        fi
      done
    fi
  fi
  return 0
}

# --- REGISTRATION ---
# Attach functions to native Zsh execution hooks
autoload -Uz add-zsh-hook
add-zsh-hook preexec preexec_track_metrics
add-zsh-hook precmd precmd_track_metrics