#!/usr/bin/env bash
# init.sh — build the exam fixtures. Safe to run more than once.
#
# Everything it generates is gitignored and rebuilt from `.seed`, so CI
# regenerates byte-identical fixtures when it re-checks your work.
set -e
umask 022

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

# ---------------------------------------------------------------- your seed
# The fixtures are generated from your student ID, so your answers are yours.
if [ -f .seed ]; then
    STUDENT_ID="$(tr -d '[:space:]' < .seed)"
else
    if [ -z "${STUDENT_ID:-}" ]; then
        STUDENT_ID="$(basename "$ROOT" | sed -n 's/.*-\([0-9][0-9]*\)$/\1/p')"
    fi
    if [ -z "$STUDENT_ID" ]; then
        echo "init.sh: cannot work out your student ID from the folder name."
        echo
        echo "  Run this once, with your own ID, then run init.sh again:"
        echo "      echo 6805xxxxx > .seed"
        exit 1
    fi
    printf '%s\n' "$STUDENT_ID" > .seed
fi

case "$STUDENT_ID" in
    ''|*[!0-9]*) echo "init.sh: .seed must contain digits only (your student ID)"; exit 1 ;;
esac

SEED="$(printf '%s' "$STUDENT_ID" | awk '{
    h = 7; n = split($0, c, "")
    for (i = 1; i <= n; i++) h = (h * 31 + (c[i] + 0)) % 100003
    print h
}')"

echo "Student ID : $STUDENT_ID"
echo "Fixture seed: $SEED"

# ------------------------------------------------------------------ the logs
mkdir -p logs results
awk -v seed="$SEED"                 -f tools/genlog.awk > logs/access.log
awk -v seed="$(( (SEED + 7919) % 100003 ))" -f tools/genlog.awk > logs/second.log
chmod 644 logs/access.log logs/second.log
echo "logs/access.log : $(wc -l < logs/access.log) lines"
echo "logs/second.log : $(wc -l < logs/second.log) lines"

# ----------------------------------------------------------- the broken tree
# Modes are set here, never committed: git records only the executable bit, so
# every other mode would come from your checkout umask and differ per machine.
rm -rf log-tool
mkdir -p log-tool/secrets log-tool/archive

cat > log-tool/run.sh <<'SH'
#!/usr/bin/env bash
# Placeholder release artefact — the exam grades how it is copied, not what it does.
echo "run.sh: nothing to do"
SH

cat > log-tool/analyze.py <<'PY'
#!/usr/bin/env python3
"""Placeholder release artefact for the 204203 lab exam."""
import sys


def main():
    print("analyze.py: nothing to do")
    return 0


if __name__ == "__main__":
    sys.exit(main())
PY

head -500 logs/access.log > log-tool/webserver.log

cat > log-tool/report.txt <<'TXT'
Total requests: 0
200 responses: 0
404 responses: 0
500 responses: 0
TXT

cat > log-tool/secrets/deploy.env <<'TXT'
DEPLOY_USER=releasebot
DEPLOY_TOKEN=demo-not-a-real-token-4f2a91
TXT

printf 'demo-api-token-8c1d77e0-not-real\n' > log-tool/secrets/api_token

cat > log-tool/archive/old.txt <<'TXT'
Total requests: 412
200 responses: 300
404 responses: 82
500 responses: 30
TXT

chmod 644 log-tool/run.sh
chmod 777 log-tool/analyze.py
chmod 600 log-tool/webserver.log
chmod 666 log-tool/report.txt
chmod 755 log-tool/secrets
chmod 666 log-tool/secrets/deploy.env
chmod 644 log-tool/secrets/api_token
chmod 744 log-tool/archive
chmod 640 log-tool/archive/old.txt

echo
echo "Ready. Fixtures built:"
echo "  logs/access.log, logs/second.log   (Part 1 and Part 2)"
echo "  log-tool/                          (Part 3 and Part 4)"
echo
echo "อ่านโจทย์ที่ TASKS_TH.md (หรือ TASKS_EN.md) แล้วรัน 'bash check.sh' เพื่อดูคะแนนได้ตลอดเวลา"
echo "Read TASKS_TH.md (or TASKS_EN.md), then run 'bash check.sh' to see your score."
