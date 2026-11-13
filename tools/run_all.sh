#!/bin/bash
# Lance tous les contrôles rapides du projet. À exécuter avant chaque envoi.
# Usage : tools/run_all.sh   (GODOT=chemin/vers/godot pour un autre exécutable)
# Chaque ligne : nom du test, variables d'environnement, motif attendu dans la sortie.
G=${GODOT:-/tmp/godot_bin/Godot_v4.7-stable_linux.x86_64}
cd "$(dirname "$0")/.."
fail=0
run() { # nom  motif_attendu  [VAR=val ...]
  local name=$1 want=$2; shift 2
  local out
  out=$(env "$@" timeout 150 "$G" --headless --fixed-fps 60 --path . --script "tools/$name.gd" 2>&1)
  if echo "$out" | grep -q "SCRIPT ERROR\|Parse Error"; then
    echo "ÉCHEC  $name $* : erreur de script"; echo "$out" | grep -m3 "SCRIPT ERROR\|Parse Error"; fail=1
  elif ! echo "$out" | grep -q "$want"; then
    echo "ÉCHEC  $name $* : « $want » absent"; fail=1
  else
    echo "ok     $name $*"
  fi
}
run smoke_test "FIN OK"
run save_test "save ok=true"
run desc_test "descriptions manquantes: 0"
run guide_test "conclave "
run feasible_test "TOTAL problemes=0"
run mount_test "INACCESSIBLES=0"
run fair_test "inégales=0"
for f in solis kharn vael conclave; do
  run startres_test "OK" FAC=$f
  run campaign_test "CAMPAGNE OK" FACTION=$f MISSION=0
  run campaign_test "CAMPAGNE OK" FACTION=$f MISSION=9
done
run group_test "GROUPE OK"
run dock_test "OK" KIND=recolteur
run dock_test "OK" KIND=mineur
run dock_test3 "OK" KIND=recolteur
run dock_test3 "OK" KIND=mineur
[ $fail = 0 ] && echo "TOUT EST BON" || echo "DES CONTRÔLES ONT ÉCHOUÉ"
exit $fail
