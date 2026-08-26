#!/usr/bin/env bash
# =============================================================================
# Part 3 — harden.sh   (โครงให้มาแล้ว · เติมเฉพาะส่วน TODO)
#                      (skeleton provided — fill in the TODO blocks only)
#
#   bash harden.sh <directory>
#
# ตาราง mode ปลายทางทั้ง 9 path อยู่ใน TASKS_TH.md / TASKS_EN.md — Part 3
# =============================================================================
set -uo pipefail

# ---------------------------------------------------------------------------
# ให้มาแล้ว: รายชื่อ path ทั้ง 9 (เรียงตามตารางในโจทย์)
# provided: the nine paths, in the same order as the table in the task sheet
# ---------------------------------------------------------------------------
PATHS=(run.sh analyze.py webserver.log report.txt secrets secrets/deploy.env secrets/api_token archive archive/old.txt)

# ---------------------------------------------------------------------------
# TODO 1 — เติม mode ปลายทางให้ตรงกับตารางในโจทย์ ให้ครบ 9 ค่า เรียงให้ตรงกับ PATHS
#          fill in the nine target modes, in the same order as PATHS
#   เช่น  MODES=(755 ... )
#   (graded by: harden_modes, harden_no_world_writable)
# ---------------------------------------------------------------------------
MODES=()      # TODO 1

usage() {
    echo "Usage: bash harden.sh <directory>" >&2
}

# ---------------------------------------------------------------------------
# TODO 2 — ตรวจ argument ก่อนทำอย่างอื่น / validate the argument first
#
#   * ถ้าไม่มี argument  หรือ $1 ไม่ใช่ directory
#       - พิมพ์ error ออก stderr
#       - return ค่าที่ "ไม่ใช่ 0"
#   * ผู้เรียกข้างล่างจะ exit ให้เอง และต้องยัง "ไม่มี" harden_report.txt ถูกสร้าง
#
#   (graded by: harden_idempotent_and_args)
# ---------------------------------------------------------------------------
check_target() {

    # TODO 2 → เขียนโค้ดตรวจตรงนี้

    return 0
}

check_target "$@" || exit 1
target="$1"

# ---------------------------------------------------------------------------
# TODO 3 — ตั้ง mode ให้ครบทั้ง 9 path ภายใต้ "$target"
#
#   * วนทีละ index ของ PATHS แล้ว chmod ให้เป็น MODES ตัวที่ตรงกัน
#   * ต้อง idempotent: รันรอบสองแล้วต้องไม่มี mode ใดเปลี่ยน และ exit 0
#     ใบ้: อ่าน mode ปัจจุบันด้วย  stat -c '%a' <path>  แล้ว chmod เฉพาะเมื่อไม่ตรง
#          จะได้นับจำนวนไฟล์ที่ "แก้จริง" ไว้ใส่ในรายงานด้วย
#   * ห้ามใช้ chmod -R ทีเดียวทั้งไดเรกทอรี — ไฟล์ข้อมูลจะกลายเป็น executable
#     และ secrets/ จะถูกเปิดให้คนทั้งเครื่อง
#
#   (graded by: harden_modes, harden_no_world_writable, harden_idempotent_and_args)
# ---------------------------------------------------------------------------

fixed=0

# TODO 3 → เขียน loop ตรงนี้



# ---------------------------------------------------------------------------
# TODO 4 — นับจำนวน path ที่ยัง world-writable เหลืออยู่ ใส่ตัวแปร ww
#          ใบ้:  find "$target" -perm -002 | wc -l
# ---------------------------------------------------------------------------

ww=""         # TODO 4
secmode="$(stat -c '%a' "$target/secrets" 2>/dev/null)"

# ---------------------------------------------------------------------------
# ให้มาแล้ว: บล็อกเขียน harden_report.txt (redirect ครั้งเดียว)
# provided: the harden_report.txt block, written with a single redirection
# ---------------------------------------------------------------------------
{
    echo "Target: $target"
    echo "Files fixed: $fixed"
    echo "World-writable paths remaining: $ww"
    echo "secrets/ mode: $secmode"
} > harden_report.txt

echo "hardened $target ($fixed changed, $ww world-writable remaining)"
exit 0

# ---------------------------------------------------------------------------
# Challenge B (bonus, ไม่บังคับ): รองรับ  bash harden.sh --audit <dir>
#   → รายงานว่าอะไรผิด แต่ "ไม่แก้" mode ใดเลย แล้ว exit 0
# ---------------------------------------------------------------------------
