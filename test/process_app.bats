#!/usr/bin/env bats

# setup() {
#     source ./sh-seekarr.sh
# }

@test "process_app Radarr builds MoviesSearch command" {

    source ./sh-seekarr.sh

    fetch_wanted_ids() {
    cat <<EOF >"$5"
11	The Matrix
42	Inception
EOF
    }

    api_post_command() {
        echo "$4"
    }

    SHSEEKARR_LIMIT=2
    #SHSEEKARR_LOG_FORMAT=json

    run process_app \
        radarr \
        http://localhost \
        key \
        v3 \
        wanted/missing \
        wanted/cutoff \
        movieIds \
        MoviesSearch \
        "" \
        '.'

    [ "$status" -eq 0 ]

    echo "$output" | grep "Triggering MoviesSearch on radarr for 2 item"
}

@test "process_app Sonarr builds EpisodeSearch command" {

    source ./sh-seekarr.sh

    fetch_wanted_ids() {
cat <<EOF >"$5"
11	Show S01E01
42	Show S01E02
EOF
    }

    api_post_command() {
        echo "$4"
    }

    SHSEEKARR_LIMIT=2

    run process_app \
        sonarr \
        http://localhost \
        key \
        v3 \
        wanted/missing \
        wanted/cutoff \
        episodeIds \
        EpisodeSearch \
        "" \
        '.'

    [ "$status" -eq 0 ]
    [[ "$output" == *"Triggering EpisodeSearch on sonarr for 2 item"* ]]
}

@test "process_app Lidarr builds AlbumSearch command" {

    source ./sh-seekarr.sh

    fetch_wanted_ids() {
cat <<EOF >"$5"
11	Artist - Album One
42	Artist - Album Two
EOF
    }

    api_post_command() {
        echo "$4"
    }

    SHSEEKARR_LIMIT=2

    run process_app \
        lidarr \
        http://localhost \
        key \
        v1 \
        wanted/missing \
        wanted/cutoff \
        albumIds \
        AlbumSearch \
        "" \
        '.'

    [ "$status" -eq 0 ]
    [[ "$output" == *"Triggering AlbumSearch on lidarr for 2 item"* ]]
}

@test "process_app Readarr builds BookSearch command" {

    source ./sh-seekarr.sh

    fetch_wanted_ids() {
cat <<EOF >"$5"
11	Author - Book One
42	Author - Book Two
EOF
    }

    api_post_command() {
        echo "$4"
    }

    SHSEEKARR_LIMIT=2

    run process_app \
        readarr \
        http://localhost \
        key \
        v1 \
        wanted/missing \
        wanted/cutoff \
        bookIds \
        BookSearch \
        "" \
        '.'

    [ "$status" -eq 0 ]
    [[ "$output" == *"Triggering BookSearch on readarr for 2 item"* ]]
}

@test "process_app JSON logs - Radarr builds MoviesSearch command" {

    source ./sh-seekarr.sh

    fetch_wanted_ids() {
    cat <<EOF >"$5"
11	The Matrix
42	Inception
EOF
    }

    # process_app_trigger_execution() {
    #     echo "$body"
    # }

    api_post_command() {
        echo "$4"
    }

    SHSEEKARR_LIMIT=2
    SHSEEKARR_LOG_FORMAT=json

    run process_app \
        radarr \
        http://localhost \
        key \
        v3 \
        wanted/missing \
        wanted/cutoff \
        movieIds \
        MoviesSearch \
        "" \
        '.'

    [ "$status" -eq 0 ]
    echo "$output" | jq
}

@test "process_app Missing URL and API key skips app" {

    source ./sh-seekarr.sh

    run process_app \
        radarr \
        "" \
        "" \
        v3 \
        wanted/missing \
        wanted/cutoff \
        movieIds \
        MoviesSearch \
        "" \
        '.'

    [ "$status" -eq 0 ]

    [[ "$output" == *"Skipping radarr"* ]]
}

@test "process_app search mode - missing" {

    source ./sh-seekarr.sh

    SHSEEKARR_SEARCH_MODE=missing

    fetch_wanted_ids () {
        echo -e "10\n20\n30" > $5
    }

    process_app_trigger_execution() {
        return 0
    }

    run process_app \
        radarr \
        http://localhost \
        key \
        v3 \
        wanted/missing \
        wanted/cutoff \
        movieIds \
        MoviesSearch \
        "" \
        '.'

    [[ "$output" == *"Fetching missing items for"* ]]
    [[ "$output" == *"Found 3 candidate item"* ]]
    [ "$status" -eq 0 ]
}


@test "process_app search mode - upgrades" {

    source ./sh-seekarr.sh

    SHSEEKARR_SEARCH_MODE=upgrades

    fetch_wanted_ids () {
        echo -e "10\n20\n30" > $5
    }

    process_app_trigger_execution() {
        return 0
    }

    run process_app \
        radarr \
        http://localhost \
        key \
        v3 \
        wanted/missing \
        wanted/cutoff \
        movieIds \
        MoviesSearch \
        "" \
        '.'

    [[ "$output" == *"Fetching cutoff-unmet"* ]]
    [[ "$output" == *"Found 3 candidate item"* ]]
    [ "$status" -eq 0 ]
}