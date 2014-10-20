#!/bin/sh
command -v perl >/dev/null 2>&1 || { echo >&2 "perl required"; exit 1; }
command -v R >/dev/null 2>&1 || { echo >&2 "R required"; exit 1; }
if [ $# -ne 2 ]; then echo "usage: accesslog.sh httpd.conf access.log"; exit 1; fi
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CUSTOMLOG=`grep "^\s*CustomLog" "$1" | sed -n "s/.*\s\([^\s]\+\)$/\1/p"`
export LOGFORMAT=`grep "^\s*LogFormat .* ${CUSTOMLOG}$" "$1" | sed -n "s/LogFormat\s\+\"\(.*\)\"\s\+[^\s]\+.*$/\1/p"`
if [ -z "$LOGFORMAT" ]; then echo "Could not find LogFormat. First argument should be a file with CustomLog and LogFormat lines. To use the default: $ echo -e \"CustomLog common\\nLogFormat \\\"%h %l %u %t \\\\\\\"%r\\\\\\\" %>s %b\\\" common\" > httpd.conf"; exit 1; fi
echo "LogFormat: ${LOGFORMAT}"
export INPUT_TITLE="access log response times ms ${2}"
export INPUT_PNGFILE="${INPUT_TITLE//[^a-zA-Z0-9_]/}.png"
#export INPUT_COLS=2
cat "$2" |\
  perl -n "${DIR}/accesslog.pl" \
    > "$2.csv"
export TZ=`head -1 "$2.csv" | sed -n "s/^Time (\([^)]\+\)).*$/\1/p"`
R --silent --no-save -f "${DIR}/../r/graphcsv.r" < "$2.csv" && \
  if hash readlink 2>/dev/null; then
    readlink -f "${INPUT_PNGFILE}" 2>/dev/null
  fi &&
    if hash eog 2>/dev/null; then
      eog "${INPUT_PNGFILE}" > /dev/null 2>&1 &
    fi
