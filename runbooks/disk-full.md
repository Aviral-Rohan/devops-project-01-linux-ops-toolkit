# Runbook: Disk full on a Linux server

**Owner:** Platform team · **Last tested:** 2026-10-08 on `brewcart-staging`

## Symptoms

- Application errors such as `No space left on device`, or writes silently failing
- `health_check.sh` reports `ALERT: <mount> is NN% full` and exits with code 1
- Services fail to start or crash shortly after starting

## 1. Confirm which filesystem is full

```bash
df -h
```

Look at the **Use%** column. Note the **Mounted on** path of anything at or near 100%.

## 2. Find what is using the space

Work down from the full mount, one level at a time:

```bash
du -xsh /var/log/* 2>/dev/null | sort -h      # biggest at the bottom
du -xsh /var/log/brewcart/* 2>/dev/null | sort -h
```

- `-x` stays on one filesystem (does not wander into other mounts)
- `2>/dev/null` hides permission and `/proc` noise

Usual suspects: a runaway log file, old rotated logs, core dumps, Docker images, temp files.

## 3. Free space safely

| Situation | Action |
|---|---|
| A log file still being written by a running process | **Empty it, do not delete it:** `truncate -s 0 <file>` |
| Old rotated logs nobody needs | Compress or delete with `scripts/log_cleanup.sh` (run `--dry-run` first) |
| Unsure whether a file is needed | Do not delete. Move it to another disk or ask the owning team. |

**Why `truncate` instead of `rm`:** if a process has the file open, `rm` removes the name but the space is only released when that process closes the file. `df` keeps showing the disk as full. `truncate -s 0` empties the file in place and frees the space immediately.

If space is still not freed after deleting files, find deleted-but-open files:

```bash
lsof +L1        # or: ls -l /proc/*/fd 2>/dev/null | grep deleted
```

Restart the process holding them, or truncate via its file descriptor.

## 4. Verify

```bash
df -h <mount>
/opt/toolkit/scripts/health_check.sh; echo "exit code: $?"
```

Expect usage well below the threshold and `exit code: 0`.

## 5. Prevent it happening again

- `log_cleanup.sh` scheduled nightly (`cron/toolkit.crontab`): compress after 7 days, delete after 30
- `health_check.sh` scheduled every 5 minutes, alerting at 80%
- Ask the application team to fix the root cause (here: debug logging left enabled in a release)

## Escalate when

- The disk refills within minutes of clearing it: something is writing continuously, so stop or fix the writer first
- The full filesystem is a database volume: involve the database owner before deleting anything
