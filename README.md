# commands_time_tracker

A universal command time tracker that logs build and development metrics for flutter, dart, make, pod, gradle, and cache commands.

## Installation

```bash
brew tap ThiagoEvoa/commands-time-tracker
brew install commands-time-tracker
```

## Configuration

To start tracking your commands, add the following line to your `.zshrc`:

```bash
source $(brew --prefix commands-time-tracker)/share/commands-time-tracker/time_tracker.sh

# add all the repos here: e.g. https://github.com/ and/or git@github.com/
export TK_REPOS=("https://..." "git@...")
```

Directory Filtering (Optional)

You can restrict the tracker to only log commands executed within a specific project folder. Add the following environment variable to your .zshrc:

```bash
# Only track commands when the terminal path contains this folder name
export TRACK_FOLDER="my-project-name"
```

## Configuration

The tool supports automatic generation of weekly summaries. You can enable this by adding a cron job to your system.

Enable Automated Summaries

Run the following command to schedule a summary every 12 hours:

```bash
(crontab -l 2>/dev/null; echo "0 */12 * * * $(brew --prefix)/bin/summarize >> ~/summarizer.log 2>&1") | crontab -
```

## Usage

Use the `summarize` command to view your time tracking summary.

## Uninstall Automation

To remove the scheduled cron job, run:

```bash
summarize --uninstall
```
