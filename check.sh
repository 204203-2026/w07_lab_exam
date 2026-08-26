#!/usr/bin/env bash
# check.sh — exam grader. Run it as often as you like.
#
# Exam rules for this script (deliberately different from the weekly labs):
#   * it reports PASS or FAIL and nothing else — no hints, no expected values
#   * it never grades your working tree; every check runs against a fresh copy
#   * every expected answer is recomputed from your own fixtures at run time
#   * it always exits 0; the result lives in results/report.json
#
# No `set -e` — this script handles its own errors.

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT=""
[ -n "$ROOT" ] || ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT" || exit 0

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT INT TERM
scratch() { mktemp -d -p "$TMPROOT"; }

RESULTS="$ROOT/results"
LOG="$ROOT/logs/access.log"
LOG2="$ROOT/logs/second.log"
mkdir -p "$RESULTS"

VALID_RE='^[^ ]+ [^ ]+ [^ ]+ \[[^]]+\] "[^ ]+ [^ ]+ [^ ]+" [0-9]+ [^ ]+$'

if [ ! -f "$LOG" ] || [ ! -f "$LOG2" ] || [ ! -d "$ROOT/log-tool" ]; then
    echo "Fixtures are missing. Run: bash init.sh"
    exit 0
fi

# --------------------------------------------------------------- utilities
names=(); statuses=()
bnames=(); bstatuses=()
pass_count=0; bonus_count=0

record()  { names+=("$1");  statuses+=("$2"); [ "$2" = pass ]  && pass_count=$((pass_count + 1)); }
brecord() { bnames+=("$1"); bstatuses+=("$2"); [ "$2" = bonus ] && bonus_count=$((bonus_count + 1)); }

check() {  # check <name> <0-or-1>
    if [ "$2" -eq 0 ]; then record "$1" pass; printf '  PASS  %s\n' "$1"
    else                    record "$1" fail; printf '  FAIL  %s\n' "$1"; fi
}
bcheck() {
    if [ "$2" -eq 0 ]; then brecord "$1" bonus; printf '  DONE  %s\n' "$1"
    else                    brecord "$1" todo;  printf '  --    %s\n' "$1"; fi
}

saved()   { [ -f "$RESULTS/$1" ] || return 0; tr -d '\r' < "$RESULTS/$1"; }
squeeze() { sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]\{1,\}/ /g' -e 's/[[:space:]]*$//'; }
trim()    { tr -d '[:space:]'; }

valid_lines() { grep -E "$VALID_RE" "$1"; }

# Reference answers, recomputed from the student's own fixtures.
exp_total="$(valid_lines "$LOG" | wc -l | trim)"
exp_ips="$(valid_lines "$LOG" | awk '{print $1}' | sort -u)"
exp_top3="$(valid_lines "$LOG" | awk '{print $1}' | sort | uniq -c | sort -rn | head -3 | squeeze)"
exp_errors="$(valid_lines "$LOG" | awk '$9 ~ /^[45]/')"

summary_of() {  # summary_of <logfile> -> six expected values, one per line
    local f="$1"
    printf '%s\n' "$(valid_lines "$f" | wc -l | trim)"
    printf '%s\n' "$(valid_lines "$f" | awk '$9 == 200' | wc -l | trim)"
    printf '%s\n' "$(valid_lines "$f" | awk '$9 == 404' | wc -l | trim)"
    printf '%s\n' "$(valid_lines "$f" | awk '$9 == 500' | wc -l | trim)"
    printf '%s\n' "$(valid_lines "$f" | awk '{print $1}' | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')"
    printf '%s\n' "$(valid_lines "$f" | awk '{print $7}' | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')"
}

report_ok() {  # report_ok <report.txt> <logfile>
    local rep="$1" f="$2" vals line i=0
    [ -f "$rep" ] || return 1
    mapfile -t vals < <(summary_of "$f")
    local labels=("Total requests" "200 responses" "404 responses" "500 responses" "Top IP" "Top page")
    while [ $i -lt 6 ]; do
        grep -qE "^${labels[$i]}:[[:space:]]+$(printf '%s' "${vals[$i]}" | sed 's/[.[\*^$]/\\&/g')[[:space:]]*$" "$rep" || return 1
        i=$((i + 1))
    done
    return 0
}

WANT_PATHS=(run.sh analyze.py webserver.log report.txt secrets secrets/deploy.env secrets/api_token archive archive/old.txt)
WANT_MODES=(755    755        644            644        700     600                600               755     644)
REL_FILES=(run.sh analyze.py webserver.log report.txt)

make_broken_tree() {  # make_broken_tree <dir> — a fresh copy of the state init.sh leaves behind
    # Built from scratch on purpose: grading must not depend on what you did to
    # your own log-tool/, and cannot be sabotaged by deleting a fixture file.
    local d="$1"
    ( umask 022
      mkdir -p "$d/log-tool/secrets" "$d/log-tool/archive"
      printf '#!/usr/bin/env bash\necho "run.sh: nothing to do"\n'      > "$d/log-tool/run.sh"
      printf '#!/usr/bin/env python3\nprint("analyze.py: nothing")\n'   > "$d/log-tool/analyze.py"
      head -200 "$LOG" 2>/dev/null                                     > "$d/log-tool/webserver.log"
      printf 'Total requests: 0\n200 responses: 0\n'                    > "$d/log-tool/report.txt"
      printf 'DEPLOY_USER=releasebot\nDEPLOY_TOKEN=demo-not-real\n'     > "$d/log-tool/secrets/deploy.env"
      printf 'demo-api-token-not-real\n'                                > "$d/log-tool/secrets/api_token"
      printf 'Total requests: 412\n404 responses: 82\n'                 > "$d/log-tool/archive/old.txt"
      chmod 644 "$d/log-tool/run.sh"
      chmod 777 "$d/log-tool/analyze.py"
      chmod 600 "$d/log-tool/webserver.log"
      chmod 666 "$d/log-tool/report.txt"
      chmod 755 "$d/log-tool/secrets"
      chmod 666 "$d/log-tool/secrets/deploy.env"
      chmod 644 "$d/log-tool/secrets/api_token"
      chmod 744 "$d/log-tool/archive"
      chmod 640 "$d/log-tool/archive/old.txt" )
}

make_hardened_tree() {  # make_hardened_tree <dir> — already correct, and time-stamped
    local d="$1" i=0
    make_broken_tree "$d"
    while [ $i -lt ${#WANT_PATHS[@]} ]; do
        chmod "${WANT_MODES[$i]}" "$d/log-tool/${WANT_PATHS[$i]}" 2>/dev/null
        i=$((i + 1))
    done
    chmod 755 "$d/log-tool"
    find "$d/log-tool" -exec touch -d '2026-01-02 03:04:05' {} + 2>/dev/null
}

copy_tools() {  # copy_tools <dir> — the student's scripts, so relative paths still work
    local d="$1"
    cp "$ROOT"/*.sh "$d/" 2>/dev/null
    cp "$ROOT"/*.py "$d/" 2>/dev/null
    rm -f "$d/check.sh" "$d/init.sh" "$d/submit.sh"
    chmod u+rwx "$d"/*.sh 2>/dev/null
}

snapshot_modes() { find "$1" -printf '%m %P\n' 2>/dev/null | sort; }

echo "Grading. This never touches your working tree."
echo
echo "Part 1 — the log"

# 1 -------------------------------------------------------------- pipe_total
[ "$(saved task1.txt | trim)" = "$exp_total" ]; check pipe_total $?

# 2 --------------------------------------------------------- pipe_unique_ips
[ "$(saved task2.txt | squeeze | sed '/^$/d')" = "$exp_ips" ]; check pipe_unique_ips $?

# 3 ---------------------------------------------------------------- pipe_top3
[ "$(saved task3.txt | squeeze | sed '/^$/d')" = "$exp_top3" ]; check pipe_top3 $?

# 4 -------------------------------------------------------- pipe_errors_exact
[ "$(saved task4.txt)" = "$exp_errors" ]; check pipe_errors_exact $?

echo
echo "Part 2 — summary.sh"

# 5 --------------------------------------------------------- tool_arg_handling
rc=1
if [ -f "$ROOT/summary.sh" ]; then
    W="$(scratch)"; copy_tools "$W"
    ( cd "$W" && bash ./summary.sh no-such-file-here.log >/dev/null 2>&1 ); st=$?
    [ "$st" -ne 0 ] && [ ! -f "$W/report.txt" ] && rc=0
    rm -rf "$W"
fi
check tool_arg_handling $rc

# 6 ---------------------------------------------------- tool_accuracy_renamed
rc=1
if [ -f "$ROOT/summary.sh" ]; then
    W="$(scratch)"; copy_tools "$W"
    cp "$LOG" "$W/traffic_2f9c.log"
    ( cd "$W" && bash ./summary.sh traffic_2f9c.log >/dev/null 2>&1 ); st=$?
    [ "$st" -eq 0 ] && report_ok "$W/report.txt" "$LOG" && rc=0
    rm -rf "$W"
fi
check tool_accuracy_renamed $rc

# 7 -------------------------------------------------------- tool_second_log
rc=1
if [ -f "$ROOT/summary.sh" ]; then
    W="$(scratch)"; copy_tools "$W"
    cp "$LOG2" "$W/traffic_b41e.log"
    ( cd "$W" && bash ./summary.sh traffic_b41e.log >/dev/null 2>&1 ); st=$?
    [ "$st" -eq 0 ] && report_ok "$W/report.txt" "$LOG2" && rc=0
    rm -rf "$W"
fi
check tool_second_log $rc

echo
echo "Part 3 — harden.sh"

S1="$(scratch)"; make_broken_tree "$S1"; copy_tools "$S1"
h_ran=1
if [ -f "$ROOT/harden.sh" ]; then
    ( cd "$S1" && bash ./harden.sh log-tool >/dev/null 2>&1 ); h_ran=$?
fi

# 8 ------------------------------------------------------------- harden_modes
rc=0; i=0
while [ $i -lt ${#WANT_PATHS[@]} ]; do
    got="$(stat -c '%a' "$S1/log-tool/${WANT_PATHS[$i]}" 2>/dev/null)"
    [ "$got" = "${WANT_MODES[$i]}" ] || rc=1
    i=$((i + 1))
done
[ "$h_ran" -eq 0 ] || rc=1
check harden_modes $rc

# 9 -------------------------------------------------- harden_no_world_writable
rc=1
if [ "$h_ran" -eq 0 ] && [ -z "$(find "$S1/log-tool" -perm -002 2>/dev/null)" ]; then rc=0; fi
check harden_no_world_writable $rc

# 10 ------------------------------------------------ harden_idempotent_and_args
rc=1
if [ "$h_ran" -eq 0 ]; then
    before="$(snapshot_modes "$S1/log-tool")"
    ( cd "$S1" && bash ./harden.sh log-tool >/dev/null 2>&1 ); second=$?
    after="$(snapshot_modes "$S1/log-tool")"
    A="$(scratch)"; copy_tools "$A"
    ( cd "$A" && bash ./harden.sh no-such-directory >/dev/null 2>&1 ); bad=$?
    if [ "$second" -eq 0 ] && [ "$before" = "$after" ] \
       && [ "$bad" -ne 0 ] && [ ! -f "$A/harden_report.txt" ]; then rc=0; fi
    rm -rf "$A"
fi
check harden_idempotent_and_args $rc

echo
echo "Part 4 — release.sh"

W="$(scratch)"; make_hardened_tree "$W"; copy_tools "$W"
DEST="$(scratch)/out"; mkdir -p "$DEST"
r_ran=1
if [ -f "$ROOT/release.sh" ]; then
    ( cd "$W" && umask 077 && bash ./release.sh "$DEST/" >/dev/null 2>&1 ); r_ran=$?
fi

# 11 ------------------------------------------------------- release_preserves
rc=0
[ "$r_ran" -eq 0 ] || rc=1
for f in "${REL_FILES[@]}"; do
    src="$W/log-tool/$f"; dst="$DEST/$f"
    [ -f "$dst" ] || { rc=1; continue; }
    [ "$(md5sum < "$src" | awk '{print $1}')" = "$(md5sum < "$dst" | awk '{print $1}')" ] || rc=1
    [ "$(stat -c '%a' "$src")" = "$(stat -c '%a' "$dst")" ] || rc=1
    [ "$(stat -c '%Y' "$src")" = "$(stat -c '%Y' "$dst")" ] || rc=1
done
check release_preserves $rc

# 12 ---------------------------------------------------------- release_layout
rc=1
if [ -f "$DEST/run.sh" ] && [ -f "$DEST/webserver.log" ] \
   && [ ! -e "$DEST/secrets" ] && [ ! -e "$DEST/log-tool" ]; then rc=0; fi
check release_layout $rc

# ------------------------------------------------------------------- bonus
echo
echo "Challenge (bonus — never affects your score)"

# A: release.sh --dry-run copies nothing and still exits 0
#    (a real run must work too, or an empty destination proves nothing)
rc=1
if [ -f "$ROOT/release.sh" ]; then
    B="$(scratch)"; make_hardened_tree "$B"; copy_tools "$B"
    DR="$(scratch)/real"; mkdir -p "$DR"
    D2="$(scratch)/dry";  mkdir -p "$D2"
    ( cd "$B" && bash ./release.sh "$DR/" >/dev/null 2>&1 )
    ( cd "$B" && bash ./release.sh --dry-run "$D2/" >/dev/null 2>&1 ); st=$?
    # the flag must be consumed by the script, not passed through to rsync:
    # with --dry-run and no destination it must complain, not succeed
    ( cd "$B" && bash ./release.sh --dry-run >/dev/null 2>&1 ); nodest=$?
    if [ -f "$DR/run.sh" ] && [ "$st" -eq 0 ] && [ -z "$(ls -A "$D2" 2>/dev/null)" ] \
       && [ "$nodest" -ne 0 ]; then rc=0; fi
    rm -rf "$B"
fi
bcheck challengeA_dry_run $rc

# B: harden.sh --audit reports without changing anything
#    (a normal run must actually fix the tree, or "changed nothing" proves nothing)
rc=1
if [ -f "$ROOT/harden.sh" ]; then
    B="$(scratch)"; make_broken_tree "$B"; copy_tools "$B"
    before="$(snapshot_modes "$B/log-tool")"
    ( cd "$B" && bash ./harden.sh --audit log-tool >/dev/null 2>&1 ); st=$?
    after="$(snapshot_modes "$B/log-tool")"
    ( cd "$B" && bash ./harden.sh log-tool >/dev/null 2>&1 )
    fixed="$(stat -c '%a' "$B/log-tool/analyze.py" 2>/dev/null)"
    if [ "$st" -eq 0 ] && [ "$before" = "$after" ] && [ "$fixed" = "755" ]; then rc=0; fi
    rm -rf "$B"
fi
bcheck challengeB_audit $rc

# C: release.sh keeps a deploy log
rc=1
if [ -f "$ROOT/release.sh" ]; then
    B="$(scratch)"; make_hardened_tree "$B"; copy_tools "$B"
    D3="$(scratch)/out"; mkdir -p "$D3"
    ( cd "$B" && bash ./release.sh "$D3/" >/dev/null 2>&1 )
    [ -s "$B/deploy.log" ] && rc=0
    rm -rf "$B"
fi
bcheck challengeC_deploy_log $rc

# D: summary.sh --top-only prints just the two "top" lines
rc=1
if [ -f "$ROOT/summary.sh" ]; then
    B="$(scratch)"; copy_tools "$B"; cp "$LOG" "$B/t.log"
    out="$( cd "$B" && bash ./summary.sh --top-only t.log 2>/dev/null )"; st=$?
    if [ "$st" -eq 0 ] \
       && printf '%s\n' "$out" | grep -q '^Top IP:' \
       && printf '%s\n' "$out" | grep -q '^Top page:' \
       && ! printf '%s\n' "$out" | grep -q '^Total requests:'; then rc=0; fi
    rm -rf "$B"
fi
bcheck challengeD_top_only $rc

# ------------------------------------------------------------------ reports
{
    printf '{\n  "score": %d,\n  "total": %d,\n  "results": [\n' "$pass_count" "${#names[@]}"
    i=0
    while [ $i -lt ${#names[@]} ]; do
        sep=","; [ $((i + 1)) -eq ${#names[@]} ] && sep=""
        printf '    {"name": "%s", "status": "%s"}%s\n' "${names[$i]}" "${statuses[$i]}" "$sep"
        i=$((i + 1))
    done
    printf '  ]\n}\n'
} > "$RESULTS/report.json"

{
    printf '{\n  "bonus": %d,\n  "bonus_total": %d,\n  "results": [\n' "$bonus_count" "${#bnames[@]}"
    i=0
    while [ $i -lt ${#bnames[@]} ]; do
        sep=","; [ $((i + 1)) -eq ${#bnames[@]} ] && sep=""
        printf '    {"name": "%s", "status": "%s"}%s\n' "${bnames[$i]}" "${bstatuses[$i]}" "$sep"
        i=$((i + 1))
    done
    printf '  ]\n}\n'
} > "$RESULTS/challenge_report.json"

echo
echo "Score: $pass_count / ${#names[@]} required    Bonus: $bonus_count / ${#bnames[@]}"
echo "Written to results/report.json — commit it with bash submit.sh"
exit 0
