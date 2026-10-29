#!/usr/bin/env bash
# Publishes the key lines of a failed build log as a GitHub annotation, so the cause is
# visible from the run summary and the checks API without downloading the full log.
# Usage: report-error.sh <title> <log file>
title="$1"
log="$2"
{
  grep -A30 "What went wrong" "$log" | head -45
  grep -E "error:|ERROR|\.java:[0-9]+: |npm ERR!|Exception" "$log" | head -30
} > report-error.txt
[ -s report-error.txt ] || tail -60 "$log" > report-error.txt
message=$(sed -e 's/%/%25/g' -e 's/\r//g' report-error.txt | sed ':a;N;$!ba;s/\n/%0A/g')
echo "::error title=${title}::${message}"
