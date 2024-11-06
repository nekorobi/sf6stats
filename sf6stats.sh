#!/bin/bash
# sf6stats.sh
# MIT License © 2024 Nekorobi
version=v0.2.0
unset mode debug cacheDir yyyymm json  chara rank ranking
rankList=(rookie iron bronze silver gold platinum diamond master)

help() {
  cat << END
Usage: ./sf6stats.sh [Option]...

Show fighting stats of STREET FIGHTER 6.
Reference: https://www.streetfighter.com/6/buckler/stats/dia
This script is unofficial.

Options:
  -c, --chara Type-Chara (e.g. 'C-guile')
      Specify control type 'C' or 'M', followed by '-' and name (lower case).
      Use --rank without --chara to list all characters.
  -r, --rank rookie|iron|bronze|silver|gold|platinum|diamond|master
      Specify rank.
  --rm-cache
      Remove cache data (\$HOME/.cache/sf6stats/ranking/*.json).
  --yyyymm YearMonth (since '202306')
      The stats are updated on the second Thursday of each month.
      Default: Latest stats

  -h, --help     Show help.
  -V, --version  Show version.

sf6stats.sh $version
MIT License © 2024 Nekorobi
END
}
error() { local s=$1; shift 1; echo -e "Error: $@" 1>&2; exit $s; }

while [[ $# -gt 0 ]]; do
  case "$1" in
  -c|--chara|-r|--rank|--yyyymm)
                  [[ $# = 1 || $2 =~ ^- ]] && error 1 "$1: requires an argument";;&
  -c|--chara)     [[ $2 =~ ^(C|M)-[a-z]+$ ]] || error 1 "$1: incorrect format: $2"; chara=$2; shift 2;;
  -r|--rank)      [[ $2 =~ ^(rookie|iron|bronze|silver|gold|platinum|diamond|master)$ ]] || error 1 "$1: no such rank: $2"; rank=$2; shift 2;;
  --rm-cache)     mode=rm-cache; shift 1;;
  --yyyymm)       [[ $2 =~ ^20[0-9]{4}$ ]] || error 1 "$1: incorrect format: $2"; yyyymm=$2; shift 2;;
  --validate)     mode=validate; shift 1;;
  --debug)        debug=on; shift 1;;
  -h|--help)      help; exit 0;;
  -V|--version)   echo sf6stats.sh $version; exit 0;;
  # invalid
  -*) error 1 "$1: unknown option";;
  # Operand
  *) error 1 "$1: unknown argument";;
  esac
done

MakeCacheDir() {
  local dir=$XDG_CACHE_HOME; [[ $dir ]] || dir=$HOME/.cache; dir=$dir/$1
  mkdir -p "$dir" && [[ -w $dir && -x $dir ]] || return 1
  echo "$dir"
}
HttpGet() {
  local agent=$USER_AGENT; [[ $agent ]] || agent="Mozilla/5.0 (X11; Linux x86_64; rv:131.0) Gecko/20100101 Firefox/131.0"
  if type curl >/dev/null 2>&1; then
    curl -o "$2" --silent --compressed -A "$agent" "$1" || return 1
  elif type wget >/dev/null 2>&1; then
    wget -O "$2" --quiet --compression=auto -U "$agent" "$1" || return 2
  else return 3; fi
}
SecondThursday() { # args: year month
  local first=$(date --date $1-$2-01 +%w) # Thursday=4
  if [[ $first -le 4 ]]; then echo $((7 + 5 - $first)); else echo $((14 + 5 - $first)); fi
}

log() { if [[ $debug ]]; then echo -e "$@"; fi; }
getYyyymm() { # 2nd Friday at the earliest
  export TZ=UTC; local today=$(date +%F) # e.g. 2024-01-23
  local year=${today:0:4}  month=${today:5:2}  day=${today: -2}; month=${month#0} day=${day#0} # '08' error
  if [[ $day -gt $(SecondThursday $year $month) ]]; then ((month--)); else ((month-=2)); fi
  if [[ $month -lt 1 ]]; then ((year--)); ((month+=12)); fi
  echo $year$(printf '%.2d' $month)
}
downloadJson() {
  local url="https://www.streetfighter.com/6/buckler/api/en/stats/dia/$yyyymm"
  echo "download: $url"
  HttpGet "$url" "$json" || { [[ $? = 3 ]] && error 3 'requires curl or wget'; error 11 "can not GET: $url"; }
  jq -e '.diaData | type == "object"' "$json" >/dev/null || { rm "$json"; error 12 "can not GET JSON: $url"; }
}
validateJson() {
  local masterHeader=$(jq ".diaData.ci.d_sort.\"8\".opponent_header" "$json")
  local length=$(jq "length" <<<$masterHeader)
  [[ $length =~ ^[1-9][0-9]*$ ]] || error 20 "can not parse JSON: $json"
  log "opponent_header.length: $length"
  local every="map(has(\"input_type\"), has(\"tool_name\"), has(\"_dsort\")) | all"
  jq -e "$every" <<<$masterHeader >/dev/null || error 21 "can not parse JSON: $json"
}

rankIndex() {
  for i in ${!rankList[@]}; do
    if [[ ${rankList[$i]} = $rank ]]; then echo $((i+1)); break; fi
  done
}
makeRanking() {
  local opponent_header=".diaData.ci.d_sort.\"$(rankIndex)\".opponent_header.[]"
  local data='.input_type + "-" + .tool_name + " " + (if (._dsort | type) == "number" then ._dsort*100|tostring else "null" end)'
  local lines; lines=$(jq "$opponent_header | $data" "$json" | sed 's/"//g') ||
    error 25 "can not parse JSON: $json"
  unset ranking
  while read line; do # e.g. C-terry 54.51220338217697
    if [[ $line =~ null$ ]]; then
      ranking[${#ranking[@]}]=$(printf '%-10s --' ${line%null}) # e.g. --yyyymm 202408
    else
      ranking[${#ranking[@]}]=$(printf '%-10s %.2f%%' $line)
    fi
  done <<<$lines
  log "ranking.length: ${#ranking[@]}"
}
showRanking() {
  local i=1; for e in "${ranking[@]}"; do printf '%.2d %s\n' $i "$e"; ((i++)); done
}
showVsRanking() {
  local records=".diaData.ci.d_sort.\"$(rankIndex)\".records.[]"
  local values="select(.tool_name==\"${chara:2}\" and .input_type==\"${chara:0:1}\") | .values"
  local lines; lines=$(jq "$records | $values" "$json") || error 26 "can not parse JSON: $json"
  [[ $(jq 'length' <<<$lines) = ${#ranking[@]} ]] || error 27 "invalid JSON: $json"
  lines=$(jq ".[].val" <<<$lines | sed 's/"//g')
  local i=-1 data
  while read line; do # e.g. 5.600, 10.000, -, -.---
    ((i++)); [[ $line = - ]] && continue
    if [[ $line = -.--- ]]; then data+="--     ${ranking[$i]}"
    else data+="$line% ${ranking[$i]}"; fi
    data+=$'\n'
  done <<<$lines
  echo "[$rank] $chara's win rate (1st column):"
  sort -n -r <<<$data | sed -r 's/^([0-9])\.([0-9])/\1\2./; s/^10\.000/100.0/'
}

selectRank() {
  echo Select: rank
  select rank in "${rankList[@]}"; do [[ $rank ]] && break; done
  makeRanking; selectChara
}
selectChara() {
  echo "[$rank] win rate ranking: ${yyyymm:0:4}-${yyyymm:4}"  
  echo Select: chara
  select e in "${ranking[@]}" 'Select: rank'; do [[ $e ]] && break; done
  if [[ $e = 'Select: rank' ]]; then selectRank
  elif [[ $e =~ --$ ]]; then selectChara
  else chara=${e%% *}; showVsRanking; selectMenu; fi
}
selectMenu() {
  select e in 'Select: chara' 'Select: rank'; do [[ $e ]] && break; done
  if [[ $e = 'Select: rank' ]]; then selectRank; else selectChara; fi
}

type jq >/dev/null 2>&1 || error 3 'requires jq command'
cacheDir=$(MakeCacheDir sf6stats/ranking) || error 5 "can not use cache directory: $cacheDir"
if [[ $mode = rm-cache ]]; then rm "$cacheDir"/*.json; exit; fi
[[ $yyyymm ]] || yyyymm=$(getYyyymm)
json=$cacheDir/$yyyymm.json; log "json: $json"
[[ -f $json ]] || downloadJson
validateJson
if [[ $mode = validate ]]; then exit; fi
#
if [[ $rank && ! $chara ]]; then
  makeRanking; showRanking
elif [[ $rank && $chara ]]; then
  makeRanking; showVsRanking
else
  selectRank
fi
