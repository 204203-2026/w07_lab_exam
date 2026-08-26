#!/usr/bin/env bash
# submit.sh — ตรวจงานครั้งสุดท้าย แล้ว commit + push ขึ้น submission repo ของคุณ
set -u

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    echo "โฟลเดอร์นี้ไม่ใช่ git repository — คุณ clone template มาหรือยัง?"
    exit 1
}
cd "$ROOT"

if [ ! -f .seed ]; then
    echo "ไม่พบไฟล์ .seed — ให้รัน 'bash init.sh' ก่อน"
    exit 1
fi

echo "== ตรวจงานครั้งสุดท้าย =="
bash check.sh || true
echo

if [ ! -f results/report.json ]; then
    echo "ไม่พบ results/report.json — check.sh ทำงานไม่จบ แก้ตรงนั้นก่อน"
    exit 1
fi

for f in summary.sh harden.sh release.sh; do
    [ -f "$f" ] || echo "หมายเหตุ: ไม่พบ $f — ข้อของ Part นั้นจะได้ 0 คะแนน"
done

git add -A
if git diff --cached --quiet; then
    echo "ไม่มีอะไรใหม่ให้ commit"
else
    git commit -m "Exam submission: $(date '+%Y-%m-%d %H:%M:%S')" >/dev/null
    echo "commit เรียบร้อย"
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
echo "กำลัง push branch $BRANCH ..."
out="$(git push -u origin "$BRANCH" 2>&1)"; st=$?
printf '%s\n' "$out"

if [ $st -ne 0 ]; then
    echo
    case "$out" in
        *"fetch first"*|*non-fast-forward*|*rejected*)
            echo "submission repo ของคุณไม่ว่างเปล่า git จึงไม่ยอม push ทับ"
            echo "**ห้ามสั่ง git pull** ให้ทำแบบนี้แทน:"
            echo "  1. ลบ repo นั้นบน GitHub แล้วสร้างใหม่แบบ EMPTY"
            echo "     (ห้ามติ๊ก README, .gitignore หรือ licence)"
            echo "  2. git remote set-url origin <url ของ repo ใหม่>"
            echo "  3. bash submit.sh"
            ;;
        *workflow*)
            echo "token ของ GitHub ยัง push โฟลเดอร์ .github/workflows/ ไม่ได้ ให้สั่ง:"
            echo "  gh auth refresh -h github.com -s workflow"
            echo "แล้วสั่ง bash submit.sh อีกครั้ง"
            ;;
        *)
            echo "push ไม่สำเร็จ ตรวจ remote ด้วย:  git remote -v"
            ;;
    esac
    exit 1
fi

echo
echo "push สำเร็จแล้ว — เปิด repository ของคุณบน GitHub → แท็บ Actions"
echo "รอจนกว่า workflow จะทำงานจบ แล้วยืนยันว่ามี run ของ commit ล่าสุดขึ้นจริง"
echo "ผล run ใน Actions คือหลักฐานการส่งงานอย่างเป็นทางการ"
