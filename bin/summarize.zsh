#!/bin/zsh

# ==============================================================================
# Build Metric Summarizer & Log Rotator
# This script archives the current 'track_build_metrics.txt' file into a
# timestamped summary file and resets the main log.
#
# Usage:
#   ./summarize.sh           # Runs the summarization process
#   ./summarize.sh --uninstall # Removes associated cron jobs
# ==============================================================================

HOME="${HOME:-$(eval echo ~)}"
LOG_FILE="${TRACK_BUILD_METRICS_FILE:-$HOME/track_build_metrics.txt}"
SUMMARY_DIR="${TRACK_BUILD_SUMMARIES_DIR:-$HOME/summaries}"

# Ensure the archive directory exists
mkdir -p "$SUMMARY_DIR"
SUMMARY_FILE="$SUMMARY_DIR/build_summary_$(date +%Y-%m-%d).txt"

# Uninstall logic: Removes entries containing 'summarize' from the user's crontab
if [[ "$1" == "--uninstall" ]]; then
    echo "🧹 Removing cron job..."
    crontab -l | grep -v "summarize" | crontab -
    echo "✅ Cron job removed successfully."
    exit 0
fi

# Debug: cron may not have HOME set; log location should be explicit
echo "💡 summarize running with HOME=$HOME, LOG_FILE=$LOG_FILE, SUMMARY_FILE=$SUMMARY_FILE"

# Validation: Skip if log doesn't exist or contains only headers (<= 2 lines)
if [[ ! -f "$LOG_FILE" ]] || [[ $(wc -l < "$LOG_FILE") -le 2 ]]; then
    echo "📭 No metrics found to summarize."
    exit 0
fi

# Rotate Logs: Archive current metrics to the daily summary file
cp "$LOG_FILE" "$SUMMARY_FILE"

# --- Reset: Overwrite with the exact Header and Separator used in the main tracker ---
# Define the format to match the Zsh tracking script
TABLE_COLS="| %-19s | %-30s | %-7s | %8s | %-60s |\n"

printf "$TABLE_COLS" "TIMESTAMP" "COMMAND" "STATUS" "DURATION" "REPO" > "$LOG_FILE"
printf '=%.0s' {1..130} >> "$LOG_FILE"
echo "" >> "$LOG_FILE" # Newline for cleanliness