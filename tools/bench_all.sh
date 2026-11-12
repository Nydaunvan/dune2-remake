#!/bin/bash
# Lance toutes les confrontations (2 processus en parallèle). Usage : tools/bench_all.sh SORTIE [graines...]
G=${GODOT:-/tmp/godot_bin/Godot_v4.7-stable_linux.x86_64}
OUT=${1:-/tmp/bench.jsonl}; shift
SEEDS=${@:-1 2}
: > "$OUT"
jobs_list=()
for s in $SEEDS; do for a in solis kharn vael conclave; do for b in solis kharn vael conclave; do
  [ "$a" = "$b" ] && continue
  jobs_list+=("$a $b $s")
done; done; done
printf '%s\n' "${jobs_list[@]}" | xargs -P 2 -L 1 bash -c 'FAC_A=$0 FAC_B=$1 SEED=$2 timeout 400 '"$G"' --headless --fixed-fps 60 --path . --script tools/bench.gd 2>&1 | grep "^BENCH\|SCRIPT ERROR" | sort -u >> '"$OUT"
