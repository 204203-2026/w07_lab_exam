# w07_lab_exam — ข้อสอบปฏิบัติ

**รายวิชา:** 204203 Computer Science Technology
**เวลา:** 2 ชั่วโมง · **12 graded checks ข้อละ 1 คะแนน**
**ขอบเขต:** สัปดาห์ที่ 1–5 — เชลล์, log pipelines, เครื่องมือ Bash + Python, permissions และการคัดลอกอย่างปลอดภัย

**สอบในห้องปฏิบัติการเท่านั้น** — นั่งที่เครื่องในห้องแลบ `ssh` เข้า **VM ของตนเอง**
แล้วทำข้อสอบทั้งหมดบน VM ภายในเวลาที่กำหนด **ไม่มีช่องทางอื่น** และไม่มีการทำนอกเวลา

**รับโจทย์และส่งงานผ่าน GitHub** เหมือนแล็บทุกสัปดาห์ที่ผ่านมา

> ⚠️ **ห้ามทำข้อสอบนี้ในฐานะ `root`** · สั่ง `id -u` ถ้าได้ `0` ให้หยุดก่อน
> เพราะ root ข้ามการตรวจ permission ทั้งหมด Part 3 และ Part 4 จะทำงานไม่ตรงความจริง

---

## เริ่มต้นใช้งาน

ขั้นที่ 1–5 ให้ทำ **ก่อนเริ่มจับเวลา** ถ้าอาจารย์ผู้คุมสอบอนุญาต

**1. จากเครื่องในห้องแลบ ให้ `ssh` เข้า VM ของตนเอง** แล้วทำงานทุกอย่างต่อจากนี้บน VM

```bash
ssh user6805xxxxx@10.110.x.x
```

> เครื่องในห้องแลบเป็นเครื่องสาธารณะ — **ห้ามสร้างหรือเก็บ SSH private key ไว้บนเครื่องแลบ**
> key ที่ใช้กับ GitHub อยู่บน VM ของคุณตั้งแต่ `w00_setup` แล้ว

**2. Clone template** (ต้องเก็บ git history ของ template ไว้ — ห้าม `rm -rf .git`)

```bash
git clone <template-url> w07_lab_exam-6805xxxxx
cd w07_lab_exam-6805xxxxx
```

> ชื่อโฟลเดอร์ต้องลงท้ายด้วย **รหัสนักศึกษาของคุณ** เพราะ `init.sh` อ่านรหัสจากตรงนี้

**3. สร้าง submission repository บน GitHub แบบ EMPTY** — ห้ามติ๊ก README, `.gitignore` หรือ licence

```bash
gh repo create 204203-2026/w07_lab_exam-6805xxxxx --private
```

**4. ชี้ clone นี้ไปที่ repo ของคุณ และขอสิทธิ์ push workflow**

```bash
git remote set-url origin https://github.com/204203-2026/w07_lab_exam-6805xxxxx.git
gh auth refresh -h github.com -s workflow
git push -u origin main
```

**5. สร้าง fixture ของตัวเอง**

```bash
bash init.sh
```

`init.sh` อ่านรหัสนักศึกษาจากชื่อโฟลเดอร์ แล้วบันทึกไว้ในไฟล์ `.seed`
ถ้าอ่านไม่ได้ ให้สั่ง `echo 6805xxxxx > .seed` ด้วยรหัสของตัวเอง แล้วรัน `bash init.sh` อีกครั้ง
**ไฟล์ `.seed` ต้องถูก commit ขึ้นไปด้วย** เพราะตัวตรวจใช้ไฟล์นี้สร้างข้อมูลชุดเดียวกับของคุณขึ้นมาตรวจซ้ำ
ส่วนไฟล์ log ถูก gitignore ไว้และสร้างใหม่ได้เสมอ

**6. อ่านโจทย์แล้วเริ่มทำข้อสอบ** — `TASKS_TH.md` (ไทย) หรือ `TASKS_EN.md` (อังกฤษ) เนื้อหาเหมือนกัน
ดูคะแนนตัวเองได้ตลอดเวลาด้วย `bash check.sh`

**7. ส่งงาน**

```bash
bash submit.sh
```

`submit.sh` จะรัน `check.sh` ให้อีกรอบ แล้ว commit และ push ขึ้น repo ของคุณ
จากนั้นเปิด repository บน GitHub → แท็บ **Actions** และยืนยันว่า run ของ commit ล่าสุดขึ้นจริง

> **ผล run ใน Actions คือหลักฐานการส่งงานอย่างเป็นทางการ**
> งานที่ยังอยู่บน VM แต่ไม่ได้ push ไม่นับว่าส่ง

---

## สิ่งที่ต้องส่ง

| path | คืออะไร |
|---|---|
| `results/task1.txt` … `task4.txt` | คำตอบ Part 1 |
| `summary.sh` | Part 2 — มีโครงให้แล้ว เติมเฉพาะบล็อก `TODO` |
| `harden.sh` | Part 3 — มีโครงให้แล้ว เติมเฉพาะบล็อก `TODO` |
| `release.sh` | Part 4 — มีโครงให้แล้ว เติมเฉพาะบล็อก `TODO` |
| `results/report.json` | ไฟล์ที่ `check.sh` เขียนให้ |
| `.seed` | รหัสนักศึกษาของคุณ — ตัวตรวจใช้สร้าง fixture ชุดเดิมขึ้นมาใหม่ |

ไฟล์ที่ระบบสร้างขึ้นระหว่างทาง (`logs/`, `log-tool/`, `report.txt`, `harden_report.txt`)
ถูก gitignore ไว้โดยตั้งใจ **ไม่ต้องฝืน commit เข้าไป**

---

## กติกา

- เปิดหนังสือได้: repository แล็บของตนเองบน VM, `man`, `--help` เท่านั้น
- ห้ามแชต ห้ามใช้ AI assistant ห้ามค้นเว็บ
- ข้อสอบนี้ไม่ต้องใช้ `sudo` เลยแม้แต่ข้อเดียว — ถ้าคิดจะพิมพ์ `sudo` ให้กลับไปอ่านโจทย์ใหม่
- `bash check.sh` รันกี่ครั้งก็ได้ · แต่บอกแค่ **PASS หรือ FAIL** จะไม่บอกว่าคำตอบที่ถูกคืออะไร
- fixture ของคุณสร้างจากรหัสนักศึกษาของคุณเอง **ตัวเลขของเพื่อนคือคำตอบที่ผิดสำหรับคุณ**

## เกณฑ์คะแนน

required 12 checks ข้อละ 1 คะแนน บันทึกใน `results/report.json`
ส่วน challenge อีก 4 ข้อบันทึกแยกใน `results/challenge_report.json` และ **ไม่มีทางทำให้คะแนนหลักลดลง**

หลังสอบ ผู้สอนจะสร้าง fixture จาก `.seed` ของคุณแล้วรัน `check.sh` ตรวจซ้ำอีกครั้ง
**คะแนนที่นับคือผลตรวจซ้ำครั้งนั้น** การแก้ตัวเลขใน `report.json` เองจึงไม่มีประโยชน์

## เมื่อมีปัญหา

| อาการ | ให้ทำแบบนี้ |
|---|---|
| `init.sh` หารหัสนักศึกษาไม่เจอ | `echo 6805xxxxx > .seed` แล้ว `bash init.sh` |
| ทำ `log-tool/` พังจนแก้ไม่ไหว | `rm -rf log-tool && bash init.sh` (คำตอบใน `results/` ไม่หาย) |
| `check.sh` บอกว่า fixture หายไป | `bash init.sh` |
| `submit.sh` บอกว่า push ถูกปฏิเสธ (`rejected` / `non-fast-forward`) | submission repo ของคุณไม่ว่างเปล่า ให้ลบแล้วสร้างใหม่แบบ EMPTY → `git remote set-url origin <url ใหม่>` → `bash submit.sh` · **ห้ามสั่ง `git pull`** |
| `submit.sh` พูดถึง `workflow` scope | `gh auth refresh -h github.com -s workflow` แล้วส่งใหม่ |
| `gh: command not found` หรือ gh ยังไม่ได้ล็อกอิน | `gh auth login` บน VM (เหมือนที่ทำไว้ใน `w00_setup`) |

**เหลือเวลาสิบนาทีสุดท้ายไว้สำหรับ `bash submit.sh` และการยืนยันผลในแท็บ Actions**
ข้อสอบที่ทำได้เต็มแต่ไม่ได้ push มีค่าเท่ากับศูนย์
