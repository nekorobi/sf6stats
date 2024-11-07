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

echo '  --chara C-blanka --rank rookie --yyyymm 202409:'
result=$(../sf6stats.sh --chara C-blanka --rank rookie --yyyymm 202409 | head -3)
test='100.0% M-vega
100.0% M-kimberly
100.0% C-lily'
[[ $result = $test ]]

echo '  --chara C-dhalsim --rank rookie --yyyymm 202408:'
result=$(../sf6stats.sh --chara C-dhalsim --rank rookie --yyyymm 202408 | tail -3)
test='00.00% M-dhalsim
-----% M-terry
-----% C-terry'
[[ $result = $test ]]

rm -r "$XDG_CACHE_HOME/sf6stats"

echo success: test.sh
