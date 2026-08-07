#!/usr/bin/env bats

setup() {
    source ./sh-seekarr.sh

}

@test "main_app dispatches enabled apps" {
    process_app() {
        echo "$1"
    }

    SHSEEKARR_APPS="sonarr,sonarr_seasons,radarr,lidarr,readarr"

    run main_app

    [ "$status" -eq 0 ]
    [[ "$output" == *sonarr_seasons* ]]
    [[ "$output" == *sonarr* ]]
    [[ "$output" == *radarr* ]]
    [[ "$output" == *lidarr* ]]
    [[ "$output" == *readarr* ]]
}

@test "main_app wrong app" {
    process_app() {
        echo "$1"
    }

    SHSEEKARR_APPS="buldazavr"

    run main_app

    [ "$status" -eq 0 ]
    grep "Unknown app in SHSEEKARR_APPS" <<< $output
}