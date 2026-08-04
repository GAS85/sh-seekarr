#!/bin/bash
#
# sh-seekarr.sh - lightweight replacement for the "seekarr" project.
#
# https://github.com/GAS85/sh-seekarr
#
# Queries Sonarr and/or Radarr for missing / cutoff-unmet (upgrade) items,
# randomly selects up to a configurable limit, and triggers a search for
# just those items. Designed to keep memory low: only numeric ids are ever
# held in memory/disk, never full episode/movie/series JSON objects.
#
# ---------------------------------------------------------------------------
# Configuration (environment variables)
# ---------------------------------------------------------------------------
#   SHSEEKARR_APPS              Comma separated list of apps to run.
#                               Default: "sonarr,radarr"
#
#   SHSEEKARR_SONARR_URL        Base URL of Sonarr, e.g. http://localhost:8989
#   SHSEEKARR_SONARR_APIKEY     Sonarr API key
#   SHSEEKARR_RADARR_URL        Base URL of Radarr, e.g. http://localhost:7878
#   SHSEEKARR_RADARR_APIKEY     Radarr API key
#
#   SHSEEKARR_SEARCH_MODE       "missing" | "upgrades" | "both" | "all"
#                                missing  -> only wanted/missing
#                                upgrades -> only wanted/cutoff (unmet)
#                                both/all -> union of both, deduplicated
#                                Default: "missing"
#
#   SHSEEKARR_MONITORED_ONLY    "true" | "false". Default: "true"
#
#   SHSEEKARR_LIMIT             Max number of items to search PER APP.
#                               Default: 10
#
#   SHSEEKARR_SONARR_LIMIT      Set individual of items to search for Sonarr. 
#
#   SHSEEKARR_RADARR_LIMIT      Set individual of items to search for Radarr. 
#
#   SHSEEKARR_PAGE_SIZE         Page size used when paging the Sonarr/Radarr
#                               wanted endpoints. Default: 200
#
#   SHSEEKARR_DRY_RUN           "true" | "false". If true, prints what would
#                                be sent to the command API instead of POSTing
#                                it. Default: "false"
#
#  SHSEEKARR_SCHEDULE_INTERVAL  Scheduler interval can be integer number for seconds,
#                               or 's','m','h', or 'd', for seconds, minutes, hours, days.
#
#  SHSEEKARR_SCHEDULE_RANDOMIZER Add some random waiting seconds to scheduler interval
#
#  SHSEEKARR_LOG_FORMAT          "text" or "json". Default: "text"
#
# An app (sonarr/radarr) is skipped automatically if its URL or API key is
# not configured.
#
# Requires: curl, jq, sort
# ---------------------------------------------------------------------------

set -euo pipefail

# ---- Config ---------------------------------------------------------------

SHSEEKARR_APPS="${SHSEEKARR_APPS:-sonarr,radarr}"
SHSEEKARR_SEARCH_MODE="${SHSEEKARR_SEARCH_MODE:-missing}"
SHSEEKARR_MONITORED_ONLY="${SHSEEKARR_MONITORED_ONLY:-true}"
SHSEEKARR_LIMIT="${SHSEEKARR_LIMIT:-10}"
SHSEEKARR_PAGE_SIZE="${SHSEEKARR_PAGE_SIZE:-200}"
SHSEEKARR_DRY_RUN="${SHSEEKARR_DRY_RUN:-}"
SHSEEKARR_SCHEDULE_INTERVAL="${SHSEEKARR_SCHEDULE_INTERVAL:-}"
SHSEEKARR_SCHEDULE_RANDOMIZER="${SHSEEKARR_SCHEDULE_RANDOMIZER:-false}"
SHSEEKARR_LOG_FORMAT="${SHSEEKARR_LOG_FORMAT:-text}" # "text" or "json"

SHSEEKARR_SONARR_URL="${SHSEEKARR_SONARR_URL:-}"
SHSEEKARR_SONARR_APIKEY="${SHSEEKARR_SONARR_APIKEY:-}"
SHSEEKARR_SONARR_LIMIT="${SHSEEKARR_SONARR_LIMIT:-}"

SHSEEKARR_RADARR_URL="${SHSEEKARR_RADARR_URL:-}"
SHSEEKARR_RADARR_APIKEY="${SHSEEKARR_RADARR_APIKEY:-}"
SHSEEKARR_RADARR_LIMIT="${SHSEEKARR_RADARR_LIMIT:-}"

VERSION="${VERSION:-}"
VCS_REF="${VCS_REF:-}"

# ---- Logging --------------------------------------------------------------

app="main"

if [[ ${SHSEEKARR_LOG_FORMAT} == "json" ]]; then
  # strict RFC 3339
  ts() { date -Ins | sed 's/,/./'; }
else
  # Keep date format for the shell
  ts() { date +"%Y-%m-%d %H:%M:%S"; }
fi

log() {
  if [[ ${SHSEEKARR_LOG_FORMAT} == "json" ]]; then
    echo "{\"component\":\"${app}\",\"level\":\"$1\",\"msg\":\"$(echo $2 | sed 's/[[:space:]]\+/ /g; s/\\t//g')\",\"time\":\"$(ts)\"}"
  else
    echo -e "$(ts) - $1 - ${app} - $(echo "$2" | grep -v '^$')"
  fi
}

# ---- Startup summary --------------------------------------------------------

log INFO "Welcome to SH Seekarr$([ -n "${VERSION}" ] && echo " version: ${VERSION}")$([ -n "${VCS_REF}" ] && echo " build ${VCS_REF}").
\t\tApps enabled:          ${SHSEEKARR_APPS},
\t\tSearch Mode:           ${SHSEEKARR_SEARCH_MODE},
\t\tSearch Monitored only: ${SHSEEKARR_MONITORED_ONLY},
\t\tSearch items limit:    ${SHSEEKARR_LIMIT},
\t\tPage size:             ${SHSEEKARR_PAGE_SIZE},
$([ -n "${SHSEEKARR_DRY_RUN}" ] && echo "\t\tDry run:               ${SHSEEKARR_DRY_RUN},")
$([ -n "${SHSEEKARR_SCHEDULE_INTERVAL}" ] && echo "\t\tScheduler interval:    ${SHSEEKARR_SCHEDULE_INTERVAL},")
$([ "${SHSEEKARR_SCHEDULE_RANDOMIZER}" = "true" ] && echo "\t\tScheduler randomizer:  enabled,")
\t\tLog format:            ${SHSEEKARR_LOG_FORMAT},
$([ -n "${SHSEEKARR_SONARR_URL}" ] && echo "\t\tSonarr URL:            ${SHSEEKARR_SONARR_URL},")
$([ -n "${SHSEEKARR_SONARR_APIKEY}" ] && echo "\t\tSonarr API Key:        set,")
$([ -n "${SHSEEKARR_SONARR_LIMIT}" ] && echo "\t\tSonarr items limit:    ${SHSEEKARR_SONARR_LIMIT},")
$([ -n "${SHSEEKARR_RADARR_URL}" ] && echo "\t\tRadarr URL:            ${SHSEEKARR_RADARR_URL},")
$([ -n "${SHSEEKARR_RADARR_APIKEY}" ] && echo "\t\tRadarr API Key:        set,")
$([ -n "${SHSEEKARR_RADARR_LIMIT}" ] && echo "\t\tRadarr items limit:    ${SHSEEKARR_RADARR_LIMIT}")
"

# ---- Sanity checks ----------------------------------------------------------

need_bin() {
  command -v "$1" >/dev/null 2>&1 || {
    log ERROR "Missing required dependency: $1" >&2
    exit 1
  }
}
need_bin curl
need_bin jq
need_bin sort

case "$SHSEEKARR_SEARCH_MODE" in
missing | upgrades | both | all) ;;
*)
  log ERROR "Invalid SHSEEKARR_SEARCH_MODE: '${SHSEEKARR_SEARCH_MODE}' (expected missing|upgrades|both|all)" >&2
  exit 1
  ;;
esac

if ! [[ "$SHSEEKARR_LIMIT" =~ ^[0-9]+$ ]]; then
  log ERROR "SHSEEKARR_LIMIT must be a non-negative integer, got: '${SHSEEKARR_LIMIT}'" >&2
  exit 1
elif [[ -n "${SHSEEKARR_SONARR_LIMIT:-}" ]] && ! [[ "$SHSEEKARR_SONARR_LIMIT" =~ ^[0-9]+$ ]]; then
  log ERROR "SHSEEKARR_SONARR_LIMIT must be a non-negative integer, got: '${SHSEEKARR_SONARR_LIMIT}'" >&2
  exit 1
elif [[ -n "${SHSEEKARR_RADARR_LIMIT:-}" ]] && ! [[ "$SHSEEKARR_RADARR_LIMIT" =~ ^[0-9]+$ ]]; then
  log ERROR "SHSEEKARR_RADARR_LIMIT must be a non-negative integer, got: '${SHSEEKARR_RADARR_LIMIT}'" >&2
  exit 1
fi

case "$(echo "$SHSEEKARR_MONITORED_ONLY" | tr '[:upper:]' '[:lower:]')" in
true | 1 | yes) MONITORED_ONLY="true" ;;
false | 0 | no) MONITORED_ONLY="false" ;;
*)
  log ERROR "Invalid SHSEEKARR_MONITORED_ONLY: '${SHSEEKARR_MONITORED_ONLY}' (expected true|false)" >&2
  exit 1
  ;;
esac

case "$(echo "$SHSEEKARR_DRY_RUN" | tr '[:upper:]' '[:lower:]')" in
true | 1 | yes) SHSEEKARR_DRY_RUN="true" ;;
*) SHSEEKARR_DRY_RUN="false" ;;
esac

# ---- HTTP helpers -----------------------------------------------------------

api_get() {
  # $1=base_url $2=apikey $3=path (starting with /, e.g. /wanted/missing?...)
  curl -fsS --max-time 30 \
    -H "X-Api-Key: ${2}" \
    "${1%/}/api/v3${3}"
}

api_post_command() {
  # $1=base_url $2=apikey $3=json body
  curl -fsS --max-time 30 \
    -H "X-Api-Key: ${2}" \
    -H "Content-Type: application/json" \
    -X POST -d "${3}" \
    "${1%/}/api/v3/command"
}

ConnectivityCheck() {
  # $1=base_url $2=apikey $3=path (starting with /, e.g. /wanted/missing?...)
  local connectivityCheck
  connectivityCheck="$(curl -fsL -m 3 --retry 1 -o /dev/null -w %{http_code} -H "X-Api-Key: ${2}" "${1%/}/api/v3/wanted/missing?page=0&pageSize=1" 2>&1 || echo 000)"

	#connectivityCheck=${apiCall: -3}

	# This is success
	[[ "$connectivityCheck" == "200" ]] && return

	# This is an error
	[[ "$connectivityCheck" == "400" ]] && { log ERROR "Bad Request"; exit 1; }
	[[ "$connectivityCheck" == "401" ]] && { log ERROR "Unauthorized. Please check API Token"; exit 1; }
	[[ "$connectivityCheck" == "404" ]] && { log ERROR "Not Found under ${1%/}/api/v3"; exit 1; }
	[[ "$connectivityCheck" == "500" ]] && { log ERROR "Server Error by calling ${1%/}/api/v3"; exit 1 ; }
	[[ "$connectivityCheck" == "000" ]] && { log ERROR "Host is not reachable. Please check if Server and Port are correct. Current config is ${1%/}"; exit 1 ; }

}

# ---- Fetch wanted items into a file, one "id<TAB>label" per line ----------

fetch_wanted_ids() {
  local base_url="$1" apikey="$2" endpoint="$3" out_file="$4" extra_qs="$5" record_jq="$6"
  local page=1 total_records=1 fetched=0 page_count qs resp filter

  : >"$out_file"

  ConnectivityCheck "$base_url" "$apikey"

  while (((page - 1) * SHSEEKARR_PAGE_SIZE < total_records)); do
    qs="?page=${page}&pageSize=${SHSEEKARR_PAGE_SIZE}&sortKey=id&sortDirection=ascending${extra_qs}"
    if [[ "$MONITORED_ONLY" == "true" ]]; then
      qs+="&monitored=true"
    fi

    if ! resp="$(api_get "$base_url" "$apikey" "/${endpoint}${qs}")"; then
      log WARNING "Request to ${endpoint} (page ${page}) failed, stopping pagination." >&2
      break
    fi

    total_records="$(echo "$resp" | jq -r '.totalRecords // 0')"
    page_count="$(echo "$resp" | jq -r '.records | length')"

    # Re-filter on "monitored" client-side too, in case the API version
    # being talked to ignores the query param.
    if [[ "$MONITORED_ONLY" == "true" ]]; then
      filter=".records[] | select(.monitored == true) | ${record_jq}"
    else
      filter=".records[] | ${record_jq}"
    fi
    echo "$resp" | jq -r "$filter" >>"$out_file"

    fetched=$((fetched + page_count))

    if ((page_count == 0)); then
      break
    fi
    page=$((page + 1))
  done
}

# ---- Per-app processing ------------------------------------------------------

process_app() {
  local app="$1" base_url="$2" apikey="$3"
  local missing_endpoint="$4" cutoff_endpoint="$5"
  local id_field="$6" command_name="$7" extra_qs="$8" record_jq="$9"

  if [[ -z "$base_url" || -z "$apikey" ]]; then
    log WARNING "Skipping ${app}: ${app} URL, and / or APIKEY not configured."
    return 0
  fi

#  log INFO "== ${app} =="

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '${tmp_dir}'" RETURN

  # Lines are "id<TAB>label", e.g. "42\tThe Matrix (1999)" or
  # "133\tSome Show S02E07"
  local ids_file="${tmp_dir}/ids.txt"
  : >"$ids_file"

  if [[ "$SHSEEKARR_SEARCH_MODE" == "missing" || "$SHSEEKARR_SEARCH_MODE" == "both" || "$SHSEEKARR_SEARCH_MODE" == "all" ]]; then
    log INFO "Fetching missing items for ${app}..."
    fetch_wanted_ids "$base_url" "$apikey" "$missing_endpoint" "${tmp_dir}/missing.txt" "$extra_qs" "$record_jq"
    cat "${tmp_dir}/missing.txt" >>"$ids_file"
  fi

  if [[ "$SHSEEKARR_SEARCH_MODE" == "upgrades" || "$SHSEEKARR_SEARCH_MODE" == "both" || "$SHSEEKARR_SEARCH_MODE" == "all" ]]; then
    log INFO "Fetching cutoff-unmet (upgrade) items for ${app}..."
    fetch_wanted_ids "$base_url" "$apikey" "$cutoff_endpoint" "${tmp_dir}/cutoff.txt" "$extra_qs" "$record_jq"
    cat "${tmp_dir}/cutoff.txt" >>"$ids_file"
  fi

  sort -uR "$ids_file" -o "$ids_file"

  local total_found
  total_found="$(wc -l <"$ids_file" | tr -d ' ')"
  log INFO "Found ${total_found} candidate item(s) for ${app} after filtering (monitoredOnly=${MONITORED_ONLY})."

  if ((total_found == 0)); then
    log INFO "Nothing to search for ${app}."
    return 0
  fi

  local LIMIT

  if [[ "$app" == "sonarr" ]] && [[ -n "${SHSEEKARR_SONARR_LIMIT:-}" ]]; then
    LIMIT="${SHSEEKARR_SONARR_LIMIT}"
  elif [[ "$app" == "radarr" ]] && [[ -n "${SHSEEKARR_RADARR_LIMIT:-}" ]]; then
    LIMIT="${SHSEEKARR_RADARR_LIMIT}"
  else
    LIMIT="${SHSEEKARR_LIMIT}"
  fi

  local selected_file="${tmp_dir}/selected.txt"
  head -n "$LIMIT" "$ids_file" >"$selected_file"

  local selected_count
  selected_count="$(wc -l <"$selected_file" | tr -d ' ')"
  log INFO "Randomly selected ${selected_count} item(s) (limit=${LIMIT})."

  if ((selected_count == 0)); then
    return 0
  fi
 
  # Show what was picked, by name.
  local sel_id sel_label
  while IFS=$'\t' read -r sel_id sel_label; do
    # log INFO "${sel_id}\t- ${sel_label}"
    log INFO "Request - ${sel_label}"
  done <"$selected_file"

  local ids_json body
  ids_json="$(cut -f1 "$selected_file" | jq -R -s -c 'split("\n") | map(select(length > 0) | tonumber)')"
  body="$(jq -n \
    --arg name "$command_name" \
    --argjson ids "$ids_json" \
    --arg field "$id_field" \
    '{name: $name} + {($field): $ids}')"

  if [[ "$SHSEEKARR_DRY_RUN" == "true" ]]; then
    log INFO "[DRY RUN] Would POST to ${app} /api/v3/command:"
    echo "$body" | jq .
    return 0
  fi

  log INFO "Triggering ${command_name} on ${app} for ${selected_count} item(s)..."
  local resp
  if resp="$(api_post_command "$base_url" "$apikey" "$body")"; then
    log INFO "$(echo "$resp" | jq -c '{id, name, status}' 2>/dev/null)"
  else
    log WARNING "Failed to trigger search command for ${app}." >&2
  fi
}

# ---- Main -------------------------------------------------------------------
 
main_app () {
# Sonarr's wanted endpoints only embed the parent series (needed for the series title) if includeSeries=true is requested.
SONARR_EXTRA_QS="&includeSeries=true"
# jq: [id, "Series Name S01E05"] as a 2-column @tsv line. Season/episode numbers are zero-padded to 2 digits (numbers >= 100 are left as-is).
SONARR_RECORD_JQ='[(.id|tostring), ((.series.title // "Unknown Series") + " S" + ((.seasonNumber|tostring) | if (length < 2) then "0" + . else . end) + "E" + ((.episodeNumber|tostring) | if (length < 2) then "0" + . else . end))] | @tsv'
 
# Radarr's wanted endpoints return MovieResource records directly, which already carry title/year - no extra query param needed.
RADARR_EXTRA_QS=""
# jq: [id, "Movie Title (Year)"] as a 2-column @tsv line.
RADARR_RECORD_JQ='[(.id|tostring), ((.title // "Unknown Movie") + " (" + ((.year // "?")|tostring) + ")")] | @tsv'

IFS=',' read -ra APPS_ARR <<<"$SHSEEKARR_APPS"

for raw_app in "${APPS_ARR[@]}"; do
  app="$(echo "$raw_app" | xargs | tr '[:upper:]' '[:lower:]')"
  case "$app" in
  sonarr)
    process_app "sonarr" "$SHSEEKARR_SONARR_URL" "$SHSEEKARR_SONARR_APIKEY" \
      "wanted/missing" "wanted/cutoff" "episodeIds" "EpisodeSearch" \
      "$SONARR_EXTRA_QS" "$SONARR_RECORD_JQ"
    ;;
  radarr)
    process_app "radarr" "$SHSEEKARR_RADARR_URL" "$SHSEEKARR_RADARR_APIKEY" \
      "wanted/missing" "wanted/cutoff" "movieIds" "MoviesSearch" \
      "$RADARR_EXTRA_QS" "$RADARR_RECORD_JQ"
    ;;
  "") ;;
  *)
    log ERROR "Unknown app in SHSEEKARR_APPS: '${app}' (expected sonarr and/or radarr)" >&2
    ;;
  esac
done
}

if [[ -n ${SHSEEKARR_SCHEDULE_INTERVAL} ]]; then
    random_sleep=""
    # Infinity loop with periodical check
    while :
    do
        main_app

        # Add randomizer between 1 and 3600 seconds
        if [[ ${SHSEEKARR_SCHEDULE_RANDOMIZER} == "true" ]]; then
            random_sleep="$(echo $((1 + $RANDOM % 3600)))"
        fi
        app="main"
        log INFO "Will sleep for a $SHSEEKARR_SCHEDULE_INTERVAL $([ -n "${random_sleep:-}" ] && echo "plus ${random_sleep} seconds")"
        sleep ${SHSEEKARR_SCHEDULE_INTERVAL} ${random_sleep}
    done
else
  main_app
fi

app="main"
log INFO "All done."
exit 0
