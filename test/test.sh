#!/bin/bash
cd ${0%/*}; set -e
echo test.sh:
export XDG_CACHE_HOME=$(pwd)/tmp

echo '  --validate:'
../sf6stats.sh --validate

rm -r "$XDG_CACHE_HOME/sf6stats"

echo success: test.sh
