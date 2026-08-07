#!/usr/bin/env bats

@test "process_app_trigger_execution Dry run does not POST" {

    source ./sh-seekarr.sh

    SHSEEKARR_DRY_RUN=true

    api_post_command() {
        fail "POST should not happen"
    }

    body='{"name":"MoviesSearch","movieIds":[1]}'
    app=radarr
    api_version=v3
    base_url=http://localhost
    apikey=key

    run process_app_trigger_execution

    [ "$status" -eq 0 ]
}

@test "process_app_trigger_execution Failed to trigger POST" {

    source ./sh-seekarr.sh

    api_post_command() {
        return 1
    }

    body='{"name":"SeasonSearch","seriesId":1,"seasonNumber":2}'
    app=sonarr
    api_version=v3
    base_url=http://localhost
    apikey=key

    run process_app_trigger_execution

    [[ "$output" == *"Failed to trigger search command for"* ]]
    [ "$status" -eq 0 ]
}

@test "process_app_trigger_execution Failed to trigger POST - sonarr_seasons" {

    source ./sh-seekarr.sh

    api_post_command() {
        return 1
    }

    body='{"name":"SeasonSearch","seriesId":1,"seasonNumber":2}'
    app=sonarr_seasons
    sel_series=1
    sel_season=2
    api_version=v3
    base_url=http://localhost
    apikey=key

    run process_app_trigger_execution

    [[ "$output" == *"Failed to trigger SeasonSearch for seriesId=1 seasonNumber=2."* ]]
    [ "$status" -eq 0 ]
}
