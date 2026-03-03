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

LOG_FILE="$HOME/track_build_metrics.txt"
SUMMARY_DIR="$HOME/summaries"

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

# Validation: Skip if log doesn't exist or contains only headers (<= 2 lines)
if [[ ! -f "$LOG_FILE" ]] || [[ $(wc -l < "$LOG_FILE") -le 2 ]]; then
    echo "📭 No metrics found to summarize."
    exit 0
fi

# Rotate Logs: Archive current metrics to the daily summary file
cp "$LOG_FILE" "$SUMMARY_FILE"

# Reset: Overwrite the active log file with the header to prepare for a new day
echo "TIMESTAMP           | COMMAND                        | STATUS  | DURATION" > "$LOG_FILE"
echo "--------------------------------------------------------------------------" >> "$LOG_FILE"

echo "✅ Summary created: $SUMMARY_FILE"
echo "🧹 $LOG_FILE has been cleared."