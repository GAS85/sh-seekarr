# sh-seekarr.sh

[![Dev Build](https://github.com/GAS85/sh-seekarr/actions/workflows/docker-dev.yml/badge.svg?branch=dev)](https://github.com/GAS85/sh-seekarr/actions/workflows/docker-dev.yml)
[![Release Build and Push to Dockerhub](https://github.com/GAS85/sh-seekarr/actions/workflows/docker-release.yml/badge.svg)](https://github.com/GAS85/sh-seekarr/actions/workflows/docker-release.yml?branch=main)
![Release](https://img.shields.io/github/actions/workflow/status/GAS85/sh-seekarr/docker-release.yml?label=release&logo=github)
[![Docker hub](https://img.shields.io/badge/Docker--hub-grey?logo=docker)][docker-hub]
[![Docker Pulls][docker-pulls]][docker-hub]
[![Docker Image Size][docker-size]][docker-hub]

[docker-hub]: https://hub.docker.com/r/gas85/sh-seekarr
[docker-pulls]: https://img.shields.io/docker/pulls/gas85/sh-seekarr
[docker-size]: https://img.shields.io/docker/image-size/gas85/sh-seekarr/latest

---

A lightweight, dependency-free replacement for the [seekarr](https://github.com/scottrobertson/seekarr/) and [seekarr](https://github.com/tumeden/seekarr) projects.

It queries Sonarr and/or Radarr for missing and/or cutoff-unmet ("upgrade") items, randomly selects up to a configurable limit, and triggers a targeted search for just those items - instead of hammering every wanted item at once.

**New!** ✅ Beta support for 🎵 Lidarr and 📚 Readarr. Vibe coded via API Specifications, I do not have them to test properly.

## ❓ Why not just use seekarr?

The Typescript-based `seekarr` project loads node image and packages that is not memory efficient at all, only idle mode requeues 50 MBs of RAM and 150+ MB docker image.

The Python-based `seekarr` kind of the same and is overloaded with functions and UI.

## Requirements

- `bash`
- `curl`
- `jq`
- coreutils (`sort`, `head`, `cut`, `wc` - present on virtually every Linux/macOS system)

No Python, no Typescript no persistent state, no database.

## How it works

1. For each configured app (Sonarr, Radarr, or both), pages through the `wanted/missing` and/or `wanted/cutoff` endpoints, depending on `SHSEEKARR_SEARCH_MODE`.
2. Optionally filters to monitored-only items, both via the API's `monitored` query param and a client-side re-check (in case the Sonarr/Radarr version being talked to ignores the query param).
3. Deduplicates and randomly shuffles the resulting id list (`sort -uR`).
4. Takes the first `SHSEEKARR_LIMIT` (or per-app override) items.
5. Logs what was picked, by name - e.g. `Breaking Bad S04E04` for Sonarr, `Heat (1995)` for Radarr.
6. Triggers a single search command (`EpisodeSearch` / `MoviesSearch`) for exactly those items - or, if `SHSEEKARR_DRY_RUN=true`, just prints what *would* be sent.

An app is skipped automatically if its URL or API key isn't configured, so you can safely run this with only Sonarr, only Radarr, or both.

## Quick start

```bash
export SHSEEKARR_SONARR_URL="http://localhost:8989"
export SHSEEKARR_SONARR_APIKEY="your-sonarr-api-key"
export SHSEEKARR_RADARR_URL="http://localhost:7878"
export SHSEEKARR_RADARR_APIKEY="your-radarr-api-key"
./seekarr.sh
```

Run it on a schedule (cron, systemd timer, build in scheduler, a Sonarr/Radarr *Custom Script* trigger, etc.) to periodically nudge your indexers toward filling gaps and upgrading files, without ever doing a full-library blast search.

### Docker

```bash
docker run --name sh-seekarr \
	-e SHSEEKARR_SONARR_URL=http://sonarr:8989/ \
	-e "SHSEEKARR_SONARR_APIKEY=your key" \
	-e SHSEEKARR_RADARR_URL=http://radarr:7878/ \
	-e "SHSEEKARR_RADARR_APIKEY=your key" \
	--restart no \
	gas85/sh-seekarr:latest
```

### Docker-compose

Please refer to [docker-compose.yml](https://github.com/GAS85/sh-seekarr/blob/main/docker-compose.yml) example.

## Configuration reference

All configuration is via environment variables, prefixed `SHSEEKARR_`.

### Connection

| Variable | Required | Default | Description |
|----------|:--------:|---------|-------------|
| `SHSEEKARR_APPS` | `sonarr`, `sonarr,radarr` ...| `sonarr,radarr` | Comma-separated list of apps to run. Any combination of `sonarr`*, `sonarr_seasons`**, `radarr`, `readarr`, `lidarr`. |
| `SHSEEKARR_SONARR_URL` | If using Sonarr | *(empty)* | Base URL of your Sonarr instance. E.g.: `http://sonarr:8989`.<br>It is needed for `sonarr` and `sonarr_seasons` apps. |
| `SHSEEKARR_SONARR_APIKEY` | If using Sonarr | *(empty)* | Sonarr API key (Settings → General).<br>It is needed for `sonarr` and `sonarr_seasons` apps. |
| `SHSEEKARR_RADARR_URL` | If using Radarr | *(empty)* | Base URL of your Radarr instance. E.g.: `http://radarr:7878`|
| `SHSEEKARR_RADARR_APIKEY` | If using Radarr | *(empty)* | Radarr API key (Settings → General). |
| `SHSEEKARR_LIDARR_URL` | If using Lidarr | *(empty)* | Base URL of your Lidarr instance. E.g.: `http://lidarr:8686`|
| `SHSEEKARR_LIDARR_APIKEY` | If using Lidarr | *(empty)* | Lidarr API key (Settings → General). |
| `SHSEEKARR_READARR_URL` | If using Readarr | *(empty)* | Base URL of your Readarr instance. E.g.: `http://readarr:8787`|
| `SHSEEKARR_READARR_APIKEY` | If using Readarr | *(empty)* | Readarr API key (Settings → General). |

\* `sonarr` will request random Episodes from a different Series and Seasons.

\*\* `sonarr_seasons` will request whole Season from random Series if at least 1 episode is missing from it.

❓ Why `sonarr` and `sonarr_seasons` exist, are they doing same job? Sometimes, especially when Season was fully released it is easer to search for a whole season, instead of particular episode, this is not covered by `sonarr` only.

If an app's URL or API key isn't set, that app is skipped with a log message rather than causing an error - so `SHSEEKARR_APPS` can safely list an app you haven't configured yet.

### Search behavior

| Variable | Default | Description |
|----------|---------|-------------|
| `SHSEEKARR_SEARCH_MODE` | `missing` | `missing` - only unaired/missing items (`wanted/missing`).<br>`upgrades` - only cutoff-unmet items (`wanted/cutoff`).<br>`both` / `all` - union of both, deduplicated by id. |
| `SHSEEKARR_MONITORED_ONLY` | `true` | `true`/`false` (also accepts `1`/`0`, `yes`/`no`). If `true`, only monitored items are considered. Usually it is not needed to set it to `false`, in this case we will search over the whole catalog of series and movies, even they are not monitored (probable already watched). |
| `SHSEEKARR_LIMIT` | `10` | Max number of items to search, **per app**, after random selection. |
| `SHSEEKARR_SONARR_LIMIT` | *(unset)* | If set, overrides `SHSEEKARR_LIMIT` for Sonarr only. |
| `SHSEEKARR_RADARR_LIMIT` | *(unset)* | If set, overrides `SHSEEKARR_LIMIT` for Radarr only. |
| `SHSEEKARR_LIDARR_LIMIT` | *(unset)* | If set, overrides `SHSEEKARR_LIMIT` for Lidarr only. |
| `SHSEEKARR_READARR_LIMIT` | *(unset)* | If set, overrides `SHSEEKARR_LIMIT` for Readarr only. |
| `SHSEEKARR_SONARR_SEASONS_LIMIT` | *(unset)* | If set, overrides `SHSEEKARR_SONARR_SEASONS_LIMIT` for Sonarr only, when requesting whole seasons instead of episodes. |
| `SHSEEKARR_PAGE_SIZE` | `200` | Page size used when paging the `wanted/*` endpoints. Larger values mean fewer HTTP round-trips but bigger individual responses. |

**Note on limits:** `SHSEEKARR_LIMIT` and its per-app overrides are applied *independently* per app - e.g. `SHSEEKARR_LIMIT=10` with both Sonarr and Radarr enabled can trigger up to 10 searches on Sonarr **and** up to 10 on Radarr, not 10 combined.

#### Test

<details>
<summary>Test with "monitored" and without it</summary>

```bash
./sh-seekarr.sh | grep -E "Search Mode|Found"                                                                                                               
                Search Mode:           upgrades,
2026-08-05 12:00:27 - INFO - sonarr - Found 51 candidate item(s) for sonarr after filtering (monitoredOnly=true).
2026-08-05 12:00:27 - INFO - sonarr_seasons - Found 13 candidate season(s) for sonarr_seasons after filtering (monitoredOnly=true).
./sh-seekarr.sh | grep -E "Search Mo|Found"
                Search Mode:           missing,
2026-08-05 12:00:46 - INFO - sonarr - Found 242 candidate item(s) for sonarr after filtering (monitoredOnly=true).
2026-08-05 12:00:47 - INFO - sonarr_seasons - Found 22 candidate season(s) for sonarr_seasons after filtering (monitoredOnly=true).
./sh-seekarr.sh | grep -E "Search Mo|Found"
                Search Mode:           both,
2026-08-05 12:01:03 - INFO - sonarr - Found 293 candidate item(s) for sonarr after filtering (monitoredOnly=true).
2026-08-05 12:01:03 - INFO - sonarr_seasons - Found 31 candidate season(s) for sonarr_seasons after filtering (monitoredOnly=true).
./sh-seekarr.sh | grep -E "Search Mo|Found"
                Search Mode:           upgrades,
2026-08-05 12:01:22 - INFO - sonarr - Found 169 candidate item(s) for sonarr after filtering (monitoredOnly=false).
2026-08-05 12:01:22 - INFO - sonarr_seasons - Found 14 candidate season(s) for sonarr_seasons after filtering (monitoredOnly=false).
./sh-seekarr.sh | grep -E "Search Mo|Found"
                Search Mode:           missing,
2026-08-05 12:03:27 - INFO - sonarr - Found 10110 candidate item(s) for sonarr after filtering (monitoredOnly=false).
2026-08-05 12:05:03 - INFO - sonarr_seasons - Found 692 candidate season(s) for sonarr_seasons after filtering (monitoredOnly=false).
./sh-seekarr.sh | grep -E "Search Mo|Found"
                Search Mode:           both,
2026-08-05 12:06:55 - INFO - sonarr - Found 10279 candidate item(s) for sonarr after filtering (monitoredOnly=false).
2026-08-05 12:08:30 - INFO - sonarr_seasons - Found 697 candidate season(s) for sonarr_seasons after filtering (monitoredOnly=false).
```

</details>

### Output & safety

| Variable | Default | Description |
|--------------------------|---------|--------------|
| `SHSEEKARR_DRY_RUN` | `true` | `true`/`false` (also accepts `1`/`0`, `yes`/`no`). If `true`, prints the exact command payload that *would* be sent to Sonarr/Radarr, without actually triggering a search. |
| `SHSEEKARR_LOG_FORMAT` | *(unset)* | Unset for human-readable log lines, `json` for one-JSON-object-per-line structured logs (useful for log aggregators). |

### Scheduler

| Variable | Default | Description |
|--------------------------|---------|--------------|
| `SHSEEKARR_SCHEDULE_INTERVAL` | *(unset)* | When set will enable scheduler. Scheduler interval can be an integer or floating-point number for seconds, or `s`,`m`,`h`, or `d`, for seconds, minutes, hours, days. E.g. `86400` = `86400s` = `1440m` = `24h` = `1d`. |
| `SHSEEKARR_SCHEDULE_RANDOMIZER` | `false` | `true`/`false` Add some random waiting seconds to the scheduler interval between 1 and 3600 seconds. |
| `SHSEEKARR_SEARCH_ON_START` | `true` | `true`/`false` Shoud search be performed upon start - `true`, or delay search based on scheduler - `false`. Works only if `SHSEEKARR_SCHEDULE_INTERVAL` is set. |

## Example: run only Sonarr, upgrades only, higher limit

```bash
SHSEEKARR_APPS="sonarr" \
SHSEEKARR_SONARR_URL="http://localhost:8989" \
SHSEEKARR_SONARR_APIKEY="xxxx" \
SHSEEKARR_SEARCH_MODE="upgrades" \
SHSEEKARR_LIMIT="15" \
./seekarr.sh
```

## Example: different limits per app

```bash
SHSEEKARR_SONARR_URL="http://localhost:8989" SHSEEKARR_SONARR_APIKEY="xxxx" \
SHSEEKARR_RADARR_URL="http://localhost:7878" SHSEEKARR_RADARR_APIKEY="yyyy" \
SHSEEKARR_SEARCH_MODE="both" \
SHSEEKARR_LIMIT="10" \
SHSEEKARR_SONARR_LIMIT="3" \
./seekarr.sh
```

This searches up to 3 Sonarr items and up to 10 Radarr items (Radarr falls
back to the global `SHSEEKARR_LIMIT` since `SHSEEKARR_RADARR_LIMIT` isn't
set).

## Example: JSON logging for log aggregation

```bash
SHSEEKARR_LOG_FORMAT="json" ./seekarr.sh
```

Each log line looks like:

```json
{"component":"sonarr","level":"INFO","msg":"Randomly selected 5 item(s) (limit=5).","time":"2026-08-01T12:20:57.614075947+00:00"}
```

## Sample output (text format, dry run)

```plain
2026-08-01 12:20:56 - INFO - sonarr - Fetching missing items for sonarr...
2026-08-01 12:20:57 - INFO - sonarr - Found 64 candidate item(s) for sonarr after filtering (monitoredOnly=true).
2026-08-01 12:20:57 - INFO - sonarr - Randomly selected 5 item(s) (limit=5).
2026-08-01 12:20:57 - INFO - sonarr - [12] Fargo S03E12
2026-08-01 12:20:57 - INFO - sonarr - [3] Fargo S03E03
2026-08-01 12:20:57 - INFO - sonarr - [10009] Fargo S09E09
2026-08-01 12:20:57 - INFO - sonarr - [10015] Fargo S06E15
2026-08-01 12:20:57 - INFO - sonarr - [30] Fargo S03E08
```

## 🔒 Security note

Don't hardcode API keys directly in the script. Keep them in environment variables, an untracked `.env` file loaded by your process manager, or a secrets manager - anything other than committing them to version control or pasting them into a script you might share.

## ⏲️ Running on a schedule

### cron

```cron
# Every 6 hours
0 */6 * * * /path/to/seekarr.sh >> /var/log/seekarr.log 2>&1
```

### systemd timer

`seekarr.service`:

```ini
[Unit]
Description=seekarr search trigger

[Service]
Type=oneshot
EnvironmentFile=/etc/seekarr.env
ExecStart=/path/to/seekarr.sh
```

`seekarr.timer`:

```ini
[Unit]
Description=Run seekarr every 6 hours

[Timer]
OnCalendar=*-*-* 0/6:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

`/etc/seekarr.env`:

```bash
SHSEEKARR_SONARR_URL=http://localhost:8989
SHSEEKARR_SONARR_APIKEY=xxxx
SHSEEKARR_RADARR_URL=http://localhost:7878
SHSEEKARR_RADARR_APIKEY=yyyy
```

### Script

```bash
export SHSEEKARR_SONARR_URL="http://localhost:8989"
export SHSEEKARR_SONARR_APIKEY="your-sonarr-api-key"
export SHSEEKARR_RADARR_URL="http://localhost:7878"
export SHSEEKARR_RADARR_APIKEY="your-radarr-api-key"
export SHSEEKARR_SCHEDULE_INTERVAL="6h"
./seekarr.sh
```

### Docker internal scheduler

```bash
docker run --name sh-seekarr \
	-e SHSEEKARR_SONARR_URL=http://sonarr:8989/ \
	-e "SHSEEKARR_SONARR_APIKEY=your key" \
	-e SHSEEKARR_RADARR_URL=http://radarr:7878/ \
	-e "SHSEEKARR_RADARR_APIKEY=your key" \
    -e "SHSEEKARR_SCHEDULE_INTERVAL=6h" \
	gas85/sh-seekarr:latest
```

For docker compose, pleaser refer to [docker-compose.yml](https://github.com/GAS85/sh-seekarr/blob/main/docker-compose.yml).

## 😵‍💫 Troubleshooting

- **"Missing required dependency: jq"** - install `jq` (e.g. `apt install jq`, `brew install jq`).
- **Nothing gets searched even though Sonarr/Radarr shows missing items** - check `SHSEEKARR_MONITORED_ONLY`; unmonitored items are excluded by default.
- **Script exits immediately with an "Invalid ..." error** - one of the env vars (`SHSEEKARR_SEARCH_MODE`, `SHSEEKARR_LIMIT`, `SHSEEKARR_SONARR_LIMIT`, `SHSEEKARR_RADARR_LIMIT`, `SHSEEKARR_MONITORED_ONLY`) has an invalid value - the error message names which one and what value it received.

## Donation

[Buy me a 🍺](https://www.paypal.com/paypalme/GeorgiySitnikov)
