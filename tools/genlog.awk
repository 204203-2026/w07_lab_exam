# genlog.awk — deterministic web-server log generator for the 204203 lab exam.
#
#   awk -v seed=12345 -f tools/genlog.awk > access.log
#
# No rand(). Integer arithmetic only, so the same seed produces a byte-identical
# file on every VM and in CI — which is what lets check.sh recompute the expected
# answers instead of hard-coding them.
BEGIN {
    if (seed == "") { print "genlog.awk: -v seed=NNN is required" > "/dev/stderr"; exit 1 }
    seed = seed % 100003
    if (seed < 0) seed = -seed

    N = 2500 + (seed % 501)              # 2500..3000 valid request lines

    # Five hosts on five distinct networks, so the octets can never collide.
    ip[1] = "203.0.113."   ((seed        % 200) + 10)
    ip[2] = "198.51.100."  (((seed * 7)  % 200) + 10)
    ip[3] = "192.0.2."     (((seed * 13) % 200) + 10)
    ip[4] = "45.9.148."    (((seed * 29) % 200) + 10)
    ip[5] = "185.220.101." (((seed * 41) % 200) + 10)

    # Traffic mix. Per-host totals are 43 / 23 / 13 / 12 / 9 percent — all
    # distinct, so "top IP" and "top 3 IPs" are never ambiguous.
    n = 0
    n++; who[n]=1; pct[n]=40; meth[n]="GET";  path[n]="/index.html";    st[n]=200; by[n]=1893
    n++; who[n]=1; pct[n]=3;  meth[n]="GET";  path[n]="/about.html";    st[n]=200; by[n]=1450
    n++; who[n]=2; pct[n]=20; meth[n]="GET";  path[n]="/products.html"; st[n]=200; by[n]=2210
    n++; who[n]=2; pct[n]=3;  meth[n]="POST"; path[n]="/checkout.php";  st[n]=500; by[n]=612
    n++; who[n]=3; pct[n]=13; meth[n]="GET";  path[n]="/style.css";     st[n]=200; by[n]=894
    n++; who[n]=5; pct[n]=9;  meth[n]="GET";  path[n]="/app.js";        st[n]=200; by[n]=1310
    n++; who[n]=4; pct[n]=8;  meth[n]="GET";  path[n]="/wp-login.php";  st[n]=404; by[n]=505
    n++; who[n]=4; pct[n]=4;  meth[n]="GET";  path[n]="/admin.php";     st[n]=404; by[n]=505
    nblocks = n

    used = 0
    for (b = 2; b <= nblocks; b++) { cnt[b] = int(N * pct[b] / 100); used += cnt[b] }
    cnt[1] = N - used                    # the remainder always lands in block 1

    # Build the ordered list of request lines.
    k = 0
    for (b = 1; b <= nblocks; b++)
        for (j = 0; j < cnt[b]; j++) { k++; blk[k] = b }

    # Fixed, rand-free shuffle: idx = (i * P) % N with P coprime to N visits
    # every index exactly once, so hosts are interleaved and `uniq` without a
    # preceding `sort` gives the wrong answer — on purpose.
    P = int(N * 7 / 17) + 1
    while (gcd(P, N) != 1) P++

    mcount = build_malformed()
    for (m = 1; m <= mcount; m++) at[int(N * m / (mcount + 1))] = m

    sec = 0
    for (i = 0; i < N; i++) {
        b = blk[(i * P) % N + 1]
        hh = 8 + int(sec / 3600); mm = int((sec % 3600) / 60); ss = sec % 60
        printf "%s - - [20/Jul/2026:%02d:%02d:%02d +0700] \"%s %s HTTP/1.1\" %d %d\n", \
               ip[who[b]], hh, mm, ss, meth[b], path[b], st[b], by[b]
        sec++
        if (i in at) print bad[at[i]]
    }
}

function gcd(a, b,   t) { while (b != 0) { t = a % b; a = b; b = t } return a }

function build_malformed(   c) {
    c = 0
    c++; bad[c] = "this line is not a log entry at all"
    c++; bad[c] = ip[3] " - - not-a-timestamp \"GET /x.html HTTP/1.1\" 200 500"
    c++; bad[c] = ip[3] " - - [20/Jul/2026:09:00:00 +0700] \"GET /truncated.html"
    c++; bad[c] = ""
    c++; bad[c] = ip[3] " - - [20/Jul/2026:09:01:11 +0700] \"GET /no-status.html HTTP/1.1\""
    c++; bad[c] = "just some garbage text mid-file"
    c++; bad[c] = ip[3] " - - 20/Jul/2026:09:02:22 +0700 \"BADMETHODNOQUOTE /weird.html HTTP/1.1\" 200 12"
    c++; bad[c] = "###CORRUPTED-ENTRY###"
    c++; bad[c] = ip[3] " [20/Jul/2026:09:03:33 +0700] \"GET /missing-dashes.html HTTP/1.1\" 200 44"
    c++; bad[c] = ip[3] " - - \"GET /no-timestamp.html HTTP/1.1\" 200 44"
    c++; bad[c] = "<<binary junk 0xFF 0x00>>"
    c++; bad[c] = ip[3] " - - [20/Jul/2026:09:05:55 +0700] \"GET /bad-status.html HTTP/1.1\" NOTASTATUS 44"
    return c
}
