#!/usr/bin/env bats

setup() {
    source ./sh-seekarr.sh
}

@test "rejects invalid SHSEEKARR_LIMIT" {
    run env SHSEEKARR_LIMIT=abc ./sh-seekarr.sh

    [ "$status" -eq 1 ]
    [[ "$output" == *"SHSEEKARR_LIMIT must be a non-negative integer"* ]]


    run env SHSEEKARR_LIMIT=-1 ./sh-seekarr.sh

    [ "$status" -eq 1 ]
    [[ "$output" == *"SHSEEKARR_LIMIT must be a non-negative integer"* ]]
}

@test "rejects invalid SHSEEKARR_SONARR_LIMIT" {
    run env SHSEEKARR_SONARR_LIMIT=abc ./sh-seekarr.sh

    [ "$status" -eq 1 ]
    [[ "$output" == *"SHSEEKARR_SONARR_LIMIT must be a non-negative integer"* ]]


    run env SHSEEKARR_SONARR_LIMIT=-1 ./sh-seekarr.sh

    [ "$status" -eq 1 ]
    [[ "$output" == *"SHSEEKARR_SONARR_LIMIT must be a non-negative integer"* ]]
}

@test "rejects invalid SHSEEKARR_SONARR_SEASONS_LIMIT" {
    run env SHSEEKARR_SONARR_SEASONS_LIMIT=abc ./sh-seekarr.sh

    [ "$status" -eq 1 ]
    [[ "$output" == *"SHSEEKARR_SONARR_SEASONS_LIMIT must be a non-negative integer"* ]]


    run env SHSEEKARR_SONARR_SEASONS_LIMIT=-1 ./sh-seekarr.sh

    [ "$status" -eq 1 ]
    [[ "$output" == *"SHSEEKARR_SONARR_SEASONS_LIMIT must be a non-negative integer"* ]]
}

@test "rejects invalid SHSEEKARR_RADARR_LIMIT" {
    run env SHSEEKARR_RADARR_LIMIT=abc ./sh-seekarr.sh

    [ "$status" -eq 1 ]
    [[ "$output" == *"SHSEEKARR_RADARR_LIMIT must be a non-negative integer"* ]]


    run env SHSEEKARR_RADARR_LIMIT=-1 ./sh-seekarr.sh

    [ "$status" -eq 1 ]
    [[ "$output" == *"SHSEEKARR_RADARR_LIMIT must be a non-negative integer"* ]]
}

@test "rejects invalid SHSEEKARR_LIDARR_LIMIT" {
    run env SHSEEKARR_LIDARR_LIMIT=abc ./sh-seekarr.sh

    [ "$status" -eq 1 ]
    [[ "$output" == *"SHSEEKARR_LIDARR_LIMIT must be a non-negative integer"* ]]


    run env SHSEEKARR_LIDARR_LIMIT=-1 ./sh-seekarr.sh

    [ "$status" -eq 1 ]
    [[ "$output" == *"SHSEEKARR_LIDARR_LIMIT must be a non-negative integer"* ]]
}

@test "rejects invalid SHSEEKARR_READARR_LIMIT" {
    run env SHSEEKARR_READARR_LIMIT=abc ./sh-seekarr.sh

    [ "$status" -eq 1 ]
    [[ "$output" == *"SHSEEKARR_READARR_LIMIT must be a non-negative integer"* ]]


    run env SHSEEKARR_READARR_LIMIT=-1 ./sh-seekarr.sh

    [ "$status" -eq 1 ]
    [[ "$output" == *"SHSEEKARR_READARR_LIMIT must be a non-negative integer"* ]]
}

@test "rejects invalid SHSEEKARR_MONITORED_ONLY" {
    run env SHSEEKARR_MONITORED_ONLY=abc ./sh-seekarr.sh

    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid SHSEEKARR_MONITORED_ONLY"* ]]
}