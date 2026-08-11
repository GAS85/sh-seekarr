#!/usr/bin/env bats

SCRIPT="./sh-seekarr.sh"

load_script() {
    export SHSEEKARR_LOG_FORMAT="$1"
    export SHSEEKARR_SCHEDULE_INTERVAL=""

    source "$SCRIPT"

    app="test-app"

    # Deterministic timestamp.
    ts() {
        if [[ "$SHSEEKARR_LOG_FORMAT" == "json" ]]; then
            echo "2026-08-10T12:34:56.000+00:00"
        else
            echo "2026-08-10 12:34:56"
        fi
    }
}

@test "log INFO goes to stdout in text format" {
    load_script text

    stdout="$(mktemp)"
    stderr="$(mktemp)"
    trap 'rm -f "$stdout" "$stderr"' EXIT

    log INFO "hello world" >"$stdout" 2>"$stderr"

    [ "$(cat "$stdout")" = \
        "2026-08-10 12:34:56 - INFO - test-app - hello world" ]

    [ ! -s "$stderr" ]
}


@test "log DEBUG goes to stdout in text format" {
    load_script text

    stdout="$(mktemp)"
    stderr="$(mktemp)"
    trap 'rm -f "$stdout" "$stderr"' EXIT

    log DEBUG "debug message" >"$stdout" 2>"$stderr"

    [ "$(cat "$stdout")" = \
        "2026-08-10 12:34:56 - DEBUG - test-app - debug message" ]

    [ ! -s "$stderr" ]
}


@test "log WARNING goes to stderr in text format" {
    load_script text

    stdout="$(mktemp)"
    stderr="$(mktemp)"
    trap 'rm -f "$stdout" "$stderr"' EXIT

    log WARNING "something looks wrong" >"$stdout" 2>"$stderr"

    [ ! -s "$stdout" ]

    [ "$(cat "$stderr")" = \
        "2026-08-10 12:34:56 - WARNING - test-app - something looks wrong" ]
}


@test "log ERROR goes to stderr in text format" {
    load_script text

    stdout="$(mktemp)"
    stderr="$(mktemp)"
    trap 'rm -f "$stdout" "$stderr"' EXIT

    log ERROR "something failed" >"$stdout" 2>"$stderr"

    [ ! -s "$stdout" ]

    [ "$(cat "$stderr")" = \
        "2026-08-10 12:34:56 - ERROR - test-app - something failed" ]
}


@test "log INFO produces valid JSON" {
    load_script json

    stdout="$(mktemp)"
    stderr="$(mktemp)"
    trap 'rm -f "$stdout" "$stderr"' EXIT

    log INFO "hello world" >"$stdout" 2>"$stderr"

    [ ! -s "$stderr" ]

    jq -e \
        '
        .component == "test-app" and
        .level == "INFO" and
        .msg == "hello world" and
        .time == "2026-08-10T12:34:56.000+00:00"
        ' "$stdout"
}


@test "log ERROR produces JSON on stderr" {
    load_script json

    stdout="$(mktemp)"
    stderr="$(mktemp)"
    trap 'rm -f "$stdout" "$stderr"' EXIT

    log ERROR "something failed" >"$stdout" 2>"$stderr"

    [ ! -s "$stdout" ]

    jq -e \
        '
        .component == "test-app" and
        .level == "ERROR" and
        .msg == "something failed" and
        .time == "2026-08-10T12:34:56.000+00:00"
        ' "$stderr"
}


@test "log WARNING produces JSON on stderr" {
    load_script json

    stdout="$(mktemp)"
    stderr="$(mktemp)"
    trap 'rm -f "$stdout" "$stderr"' EXIT

    log WARNING "warning message" >"$stdout" 2>"$stderr"

    [ ! -s "$stdout" ]

    jq -e \
        '
        .component == "test-app" and
        .level == "WARNING" and
        .msg == "warning message" and
        .time == "2026-08-10T12:34:56.000+00:00"
        ' "$stderr"
}


@test "log JSON preserves special characters" {
    load_script json

    stdout="$(mktemp)"
    stderr="$(mktemp)"
    trap 'rm -f "$stdout" "$stderr"' EXIT

    log INFO 'hello "world" / test' >"$stdout" 2>"$stderr"

    jq -e '.msg == "hello \"world\" / test"' "$stdout"
}

@test "log JSON normalizes whitespace" {
    load_script json

    stdout="$(mktemp)"
    stderr="$(mktemp)"
    trap 'rm -f "$stdout" "$stderr"' EXIT

    log INFO $'hello   world\nthis\tis   a test' >"$stdout" 2>"$stderr"

    jq -e '.msg == "hello world this is a test"' "$stdout"

}

@test "log component comes from app" {
    load_script json

    stdout="$(mktemp)"
    stderr="$(mktemp)"
    trap 'rm -f "$stdout" "$stderr"' EXIT

    app="sonarr"

    log INFO "searching" >"$stdout" 2>"$stderr"

    jq -e '
        .component == "sonarr" and
        .level == "INFO" and
        .msg == "searching"
    ' "$stdout"
}


@test "log multiline text removes empty lines" {
    load_script text

    stdout="$(mktemp)"
    stderr="$(mktemp)"
    trap 'rm -f "$stdout" "$stderr"' EXIT

    log INFO $'first\n\n\nsecond' >"$stdout" 2>"$stderr"

    expected=$'2026-08-10 12:34:56 - INFO - test-app - first\nsecond'

    [ "$(cat "$stdout")" = "$expected" ]
    [ ! -s "$stderr" ]
}