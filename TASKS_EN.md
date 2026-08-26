# w07_lab_exam — Practical Examination Tasks

*ฉบับภาษาไทยอยู่ที่ `TASKS_TH.md` — เนื้อหาเหมือนกันทุกประการ*
*(Thai version: `TASKS_TH.md` — identical in substance.)*

**2 hours** · Work on **your own VM**, reached by `ssh` from a lab machine · Open book:
your own lab repositories, `man` and `--help` · No messaging, no AI assistants, no web
search · The clone and submission steps are in `README.md`

> **Set up:** `bash init.sh`
> **Check your score any time:** `bash check.sh`
> **Submit:** `bash submit.sh`, then confirm the run in the Actions tab on GitHub

There are **12 graded checks, one mark each**. Your fixtures are generated from your own
student ID, so **every student's answers are different — copying a neighbour's numbers
scores zero**.

**The four parts are independent.** If one defeats you, move on: nothing depends on an
earlier part. `check.sh` reports only **PASS / FAIL** — it will not tell you what the
right answer was.

> **Parts 2–4 come with script skeletons.** `summary.sh`, `harden.sh` and `release.sh` are
> already in the folder — you are not writing them from scratch. Open each one and fill in
> only the blocks marked `TODO`. The provided parts (shebang, basic checks, the report block,
> the regex) may be changed if you want to, but there are no marks for rewriting them.

Suggested pacing: Part 1 · 25 min — Part 2 · 28 min — Part 3 · 27 min — Part 4 · 18 min,
leaving the first 10 minutes for cloning and repository setup and **the last 10 minutes
for submitting**.

---

## The data

`init.sh` generates **`logs/access.log`** (and a second log used only by the grader).
Most lines are ordinary **Common Log Format**:

```
203.0.113.42 - - [20/Jul/2026:08:00:00 +0700] "GET /index.html HTTP/1.1" 200 1893
```

Reading it by whitespace field: `$1` is the client IP, `$7` is the requested path, `$9`
is the HTTP status, `$10` is the byte count · the bracketed timestamp contains a space,
so it occupies fields `$4` and `$5`.

**The log also contains malformed lines** — garbage text, an empty line, a truncated
line, a line with no bracketed timestamp, a line whose status is not a number · they are
there on purpose.

> ### Definition — a **valid** line
> A line is valid exactly when it matches this extended regular expression (ERE):
>
> ```
> ^[^ ]+ [^ ]+ [^ ]+ \[[^]]+\] "[^ ]+ [^ ]+ [^ ]+" [0-9]+ [^ ]+$
> ```
>
> Everywhere in this exam, "request" means **a valid line only**
> → **`wc -l` on the whole file is not the answer to anything in this exam**

---

## Part 1 — Read the log (4 marks)

Save each answer in the `results/` folder · trailing whitespace is forgiven, extra text
is not.

### 1.1 → create `results/task1.txt`

**What to do:** count every **valid** request in `logs/access.log`
**Required output:** that number alone in the file, with no other text (e.g. `2544`)

### 1.2 → create `results/task2.txt`

**What to do:** find every distinct client IP that appears **in a valid line**
**Required output:** one IP per line, in `sort` order
Malformed lines also contain IP-looking text — none of it may reach your answer.

### 1.3 → create `results/task3.txt`

**What to do:** find the **three busiest client IPs** across the valid lines
**Required output:** 3 lines, most requests first, each line the count followed by the IP —
the output shape of `sort | uniq -c | sort -rn`
The grader normalises whitespace before comparing, so `    900 203.0.113.42` and
`900 203.0.113.42` both count.

### 1.4 → create `results/task4.txt`

**What to do:** extract every valid line whose **status is 4xx or 5xx**
**Required output:** the original lines unchanged, in the order they appear in the file
This one is compared **byte for byte**.

---

## Part 2 — `summary.sh` (3 marks)

**What to do:** write a log-analysis tool that takes its input filename as an argument
**File:** **`summary.sh`** — **a skeleton is already provided** at the top level of the exam
folder. Open it and fill in only the blocks marked `TODO`; the provided parts (the regex, the
`report.txt` block) need no editing.

```
bash summary.sh <logfile>
```

**Contract**

| Item | Requirement |
|---|---|
| input | the log file to analyse, taken from **`$1`** only. Never hard-code a filename. |
| output file | **`report.txt`**, written in the **current working directory** |
| on success | `exit 0` |
| when the input file is missing or unreadable | print an error, exit **non-zero**, and **do not create `report.txt`** |

**`report.txt` must contain these six lines** — the label exactly as shown, then a colon,
then at least one space, then the computed value alone to the end of the line:

```
Total requests: <count of valid lines>
200 responses: <valid lines with status 200>
404 responses: <valid lines with status 404>
500 responses: <valid lines with status 500>
Top IP: <IP with the most valid requests>
Top page: <path in $7 requested most often>
```

Pure Bash, Python, or Bash calling Python — your choice · The grader copies the `*.sh`
and `*.py` files at the top level of the exam folder into a temporary directory and runs
`bash summary.sh <log>` there, so relative paths between your own files still work, but
nothing else from the exam folder will be present.

**How it is graded**

| check | what the grader does |
|---|---|
| `tool_arg_handling` | runs it with a filename that does not exist → must exit non-zero **and** leave no `report.txt` |
| `tool_accuracy_renamed` | runs it against a **renamed copy of `logs/access.log`** in a temporary directory → all six values correct |
| `tool_second_log` | runs it against **a different log you have never analysed** → all six values correct, exit 0 |

The third check is why hard-coding your Part 1 answers cannot work.

---

## Part 3 — `harden.sh` (3 marks)

`init.sh` deliberately leaves `log-tool/` in a mess of wrong permissions.

**What to do:** write a script that fixes the permissions of the directory it is given
**File:** **`harden.sh`** — **a skeleton is already provided**; fill in only the `TODO` blocks
(including the `MODES` values, taken from the table below)

```
bash harden.sh <directory>
```

**Target modes — all 9 paths inside the directory it is given**

| path | starts as | must end as |
|---|---|---|
| `run.sh` | `644` | **`755`** |
| `analyze.py` | `777` | **`755`** |
| `webserver.log` | `600` | **`644`** |
| `report.txt` | `666` | **`644`** |
| `secrets/` | `755` | **`700`** |
| `secrets/deploy.env` | `666` | **`600`** |
| `secrets/api_token` | `644` | **`600`** |
| `archive/` | `744` | **`755`** |
| `archive/old.txt` | `640` | **`644`** |

**Requirements**

1. Take the target directory from `$1`
2. If `$1` is missing or is not a directory: print an error, exit **non-zero**, and
   **write no `harden_report.txt`**
3. After it runs, `find <dir> -perm -002` must print nothing at all
4. It must be **idempotent** — a second run exits `0` and changes no mode on any path
5. On success write **`harden_report.txt`** in the current working directory with a
   single redirection, containing at least: the target, how many world-writable paths
   remain, and the mode of `secrets/`
6. No `sudo` — every file is already yours

> `chmod -R 755 log-tool/` is not a shortcut — it makes every data file executable
> and re-opens `secrets/` to everyone on the machine.

**How it is graded:** the grader builds a fresh broken copy in a temporary directory; it
never grades your own `log-tool/`. The checks are: all nine modes exact (`harden_modes`) ·
nothing world-writable (`harden_no_world_writable`) · a second run changes nothing **and**
a bad argument exits non-zero without writing a report (`harden_idempotent_and_args`).

---

## Part 4 — `release.sh` (2 marks)

**What to do:** write a deployment script that copies files to a destination while
preserving modes and modification times
**File:** **`release.sh`** — **a skeleton is already provided**; fill in only the `TODO` block
(a single transfer command)

```
bash release.sh <destination-directory>
```

**Contract**

| Item | Requirement |
|---|---|
| source | always `log-tool/` in the current directory — never an argument |
| destination | `$1`, a directory that already exists |
| what must arrive | the **contents** of `log-tool/`, i.e. `<dest>/run.sh`, **not** `<dest>/log-tool/run.sh` |
| what must not arrive | `secrets/`, in any form |
| modes and timestamps | must arrive **unchanged** |
| on success | `exit 0` |

The grader runs your script under **`umask 077`** against an already-hardened,
time-stamped source, then compares the checksum, the **mode and the modification time
(mtime)** of every file at the destination.
**A copy that re-stamps the files is not a deployment.**

**How it is graded:** `release_preserves` (checksum + mode + mtime on four files) and
`release_layout` (contents not nested, `secrets/` absent, the tool files present).

---

## Challenge — bonus marks (no effect on your main score)

Bonus results are recorded separately in `results/challenge_report.json` and in a
separate GitHub action that is always green, so they can never pull your main score down.

- **A.** `release.sh --dry-run <dest>` — report what would be copied, copy nothing, `exit 0`
- **B.** `harden.sh --audit <dir>` — report what is wrong, change nothing, `exit 0`
- **C.** `release.sh` appends a line to `deploy.log` on every run
- **D.** `summary.sh --top-only <log>` — print only the `Top IP:` and `Top page:` lines

---

## Submitting

```bash
bash check.sh
bash submit.sh
```

Then open your repository on GitHub → the **Actions** tab and confirm that a run for your
latest commit really appears.

> **The Actions run is the official record of your submission.** Leave ten minutes for
> this — an exam that scores full marks but is never pushed is worth zero.
> If the push is rejected, see the "เมื่อมีปัญหา" table in `README.md`, and
> **do not run `git pull`**.
