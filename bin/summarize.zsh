#!/bin/zsh

LOG_FILE="$HOME/track_build_metrics.txt"
SUMMARY_FILE="$HOME/weekly_build_summary.txt"

if [[ ! -f "$LOG_FILE" ]] || [[ $(wc -l < "$LOG_FILE") -le 2 ]]; then
    echo "📭 No metrics found to summarize."
    exit 0
fi

if [[ ! -f "$SUMMARY_FILE" ]]; then
    echo "DATE                          | TOTAL DURATION" > "$SUMMARY_FILE"
    echo "-----------------------------------------------" >> "$SUMMARY_FILE"
fi

START_DATE=$(sed -n '3p' "$LOG_FILE" | cut -d' ' -f1)
END_DATE=$(date +"%Y-%m-%d")
WEEK_RANGE="$START_DATE to $END_DATE"

TOTAL_SECONDS=0

while IFS='|' read -r timestamp cmd cmd_status duration; do
    [[ "$timestamp" =~ "TIMESTAMP" || "$timestamp" =~ "---" || -z "$duration" ]] && continue
    
    h=$(echo "$duration" | grep -oE '[0-9]+h' | tr -d 'h' || echo 0)
    m=$(echo "$duration" | grep -oE '[0-9]+m' | tr -d 'm' || echo 0)
    s=$(echo "$duration" | grep -oE '[0-9]+s' | tr -d 's' || echo 0)
    
    h=${h:-0}; m=${m:-0}; s=${s:-0}
    
    TOTAL_SECONDS=$(( TOTAL_SECONDS + (h * 3600) + (m * 60) + s ))
done < "$LOG_FILE"

format_total() {
    local t=$1
    local h=$(( t / 3600 ))
    local m=$(( (t % 3600) / 60 ))
    local s=$(( t % 60 ))
    
    if (( h > 0 )); then
        printf "%dh %dm %ds" $h $m $s
    elif (( m > 0 )); then
        printf "%dm %ds" $m $s
    else
        printf "%ds" $s
    fi
}

TOTAL_PRETTY=$(format_total $TOTAL_SECONDS)

printf "%-29s | %s\n" "$WEEK_RANGE" "$TOTAL_PRETTY" >> "$SUMMARY_FILE"

echo "TIMESTAMP           | COMMAND                        | STATUS  | DURATION" > "$LOG_FILE"
echo "--------------------------------------------------------------------------" >> "$LOG_FILE"

echo "✅ Summary generated: $WEEK_RANGE"
echo "📊 Total Time: $TOTAL_PRETTY"
echo "🧹 $LOG_FILE has been cleared."