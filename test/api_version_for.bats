#!/usr/bin/env bats

setup() {
    source ./sh-seekarr.sh
}

@test "Sonarr uses v3" {
    run api_version_for sonarr

    [ "$status" -eq 0 ]
    [ "$output" = "v3" ]
}

@test "Sonarr seasons uses v3" {
    run api_version_for sonarr_seasons

    [ "$output" = "v3" ]
}

@test "Radarr uses v3" {
    run api_version_for radarr

    [ "$output" = "v3" ]
}

@test "Lidarr uses v1" {
    run api_version_for lidarr

    [ "$output" = "v1" ]
}

@test "Readarr uses v1" {
    run api_version_for readarr

    [ "$output" = "v1" ]
}