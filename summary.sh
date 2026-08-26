#!/usr/bin/env bash
# =============================================================================
# Part 2 — summary.sh   (โครงให้มาแล้ว · เติมเฉพาะส่วน TODO)
#                       (skeleton provided — fill in the TODO blocks only)
#
#   bash summary.sh <logfile>
#
# อ่านสัญญาของโปรแกรมเต็ม ๆ ใน TASKS_TH.md / TASKS_EN.md — Part 2
# =============================================================================
set -uo pipefail

# ---------------------------------------------------------------------------
# ให้มาแล้ว: regular expression ของ "valid line" (ไม่ต้องพิมพ์เอง)
# provided: the "valid line" regular expression — no need to retype it
# ใช้กับ grep -E เช่น:  grep -E "$VALID" "$log"
# ---------------------------------------------------------------------------
VALID='^[^ ]+ [^ ]+ [^ ]+ \[[^]]+\] "[^ ]+ [^ ]+ [^ ]+" [0-9]+ [^ ]+$'

usage() {
    echo "Usage: bash summary.sh <logfile>" >&2
}

# ---------------------------------------------------------------------------
# TODO 1 — ตรวจ argument ก่อนทำอย่างอื่น / validate the argument first
#
#   * ถ้าไม่มี argument เลย  หรือไฟล์ที่ระบุไม่มีอยู่/อ่านไม่ได้
#       - พิมพ์ข้อความ error ออก stderr
#       - exit ด้วยค่าที่ "ไม่ใช่ 0"
#       - และต้องยังไม่มีการสร้างไฟล์ report.txt ใด ๆ ทั้งสิ้น
#   * ระวังลำดับ: ถ้าเขียนไฟล์ก่อนแล้วค่อยตรวจ จะไม่ผ่าน check tool_arg_handling
#
#   (graded by: tool_arg_handling)
# ---------------------------------------------------------------------------

# TODO 1 → เขียนโค้ดตรวจ argument ตรงนี้



log="$1"        # ชื่อไฟล์ log ที่จะวิเคราะห์ — มาจาก $1 เท่านั้น ห้าม hardcode

# ---------------------------------------------------------------------------
# ให้มาแล้ว: helper สำหรับดึงเฉพาะบรรทัดที่ valid ออกมา
# provided: helper that emits only the valid lines
# ---------------------------------------------------------------------------
valid_lines() {
    grep -E "$VALID" "$log"
}

# ---------------------------------------------------------------------------
# TODO 2 — คำนวณค่าทั้งหกจาก "บรรทัดที่ valid เท่านั้น"
#          compute the six values from valid lines only
#
#   total    = จำนวนบรรทัดที่ valid ทั้งหมด
#   s200     = จำนวนบรรทัด valid ที่ status ($9) เท่ากับ 200
#   s404     = ... 404
#   s500     = ... 500
#   topip    = client IP ($1 ของบรรทัด log) ที่ปรากฏมากที่สุด
#   toppage  = path ($7 ของบรรทัด log) ที่ถูกเรียกมากที่สุด
#
#   ใบ้: valid_lines | wc -l ·  valid_lines | awk '$9 == 200' ·
#        valid_lines | awk '{print $1}' | sort | uniq -c | sort -rn | head -1
#        (ระวัง: uniq ยุบเฉพาะบรรทัดซ้ำที่อยู่ติดกัน)
#
#   (graded by: tool_accuracy_renamed, tool_second_log)
# ---------------------------------------------------------------------------

total=""      # TODO 2
s200=""       # TODO 2
s404=""       # TODO 2
s500=""       # TODO 2
topip=""      # TODO 2
toppage=""    # TODO 2

# ---------------------------------------------------------------------------
# ให้มาแล้ว: บล็อกเขียน report.txt — label ตรงตามที่ตัวตรวจต้องการแล้ว
# provided: the report.txt block — the labels already match what the grader wants
# (ห้ามแก้ข้อความ label · redirect ครั้งเดียวตอนท้าย)
# ---------------------------------------------------------------------------
{
    echo "Total requests: $total"
    echo "200 responses: $s200"
    echo "404 responses: $s404"
    echo "500 responses: $s500"
    echo "Top IP: $topip"
    echo "Top page: $toppage"
} > report.txt

cat report.txt
exit 0

# ---------------------------------------------------------------------------
# Challenge D (bonus, ไม่บังคับ): รองรับ  bash summary.sh --top-only <log>
#   → พิมพ์เฉพาะบรรทัด "Top IP:" และ "Top page:" แล้ว exit 0
#     (ต้องไม่มีบรรทัด "Total requests:" ออกมา)
# ---------------------------------------------------------------------------
