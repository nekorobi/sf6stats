#!/bin/bash
cd ${0%/*}; set -e
echo test.sh:
export XDG_CACHE_HOME=$(pwd)/tmp

echo '  --validate:'
../sf6stats.sh --validate

echo '  --rank master --yyyymm 202409:'
result=$(../sf6stats.sh --rank master --yyyymm 202409 | grep C-guile)
test='18 C-guile    50.05%'
[[ $result = $test ]]

echo '  --rank master --yyyymm 202306:'
result=$(../sf6stats.sh --rank master --yyyymm 202306 | tail -4)
test='33 M-kimberly 35.50%
34 M-manon    0.00%
35 M-blanka   --
36 M-dhalsim  --'
[[ $result = $test ]]

rm -r "$XDG_CACHE_HOME/sf6stats"

echo success: test.sh
