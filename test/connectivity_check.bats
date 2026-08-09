#!/usr/bin/env bats

setup() {
    source ./sh-seekarr.sh
}

@test "Connectivity check 200 succeeds" {
    curl() {
        echo 200
    }

    run connectivity_check http://localhost key v3

    [ "$status" -eq 0 ]
}

@test "Connectivity check 400 fails" {
    curl() {
        echo 400
    }

    run connectivity_check http://localhost key v3

    [ "$status" -eq 1 ]
}

@test "Connectivity check 401 fails" {
    curl() {
        echo 401
    }

    run connectivity_check http://localhost key v3

    [ "$status" -eq 1 ]
}

@test "Connectivity check 404 fails" {
    curl() {
        echo 404
    }

    run connectivity_check http://localhost key v3

    [ "$status" -eq 1 ]
}

@test "Connectivity check 500 fails" {
    curl() {
        echo 500
    }

    run connectivity_check http://localhost key v3

    [ "$status" -eq 1 ]
}

@test "Connectivity check 000 fails" {
    curl() {
        echo 000
    }

    run connectivity_check http://localhost key v3

    [ "$status" -eq 1 ]
}

@test "Connectivity check retests indexers when failure test is enabled" {
    SHSEEKARR_INDEXER_TEST_ON_FAILURE=true
    local marker="$BATS_TEST_TMPDIR/indexer_retest"

    curl() {
        cat <<'EOF'
[
  {
    "source": "IndexerLongTermStatusCheck",
    "type": "warning",
    "message": "Indexers unavailable due to failures for more than 6 hours: Indexer"
  }
]
200
EOF
    }

    api_post_command() {
        touch "$marker"
        return 0
    }

    run connectivity_check http://localhost key v3

    [ "$status" -eq 0 ]
    [ -f "$marker" ]
}

@test "Connectivity check does not retest indexers when failure test is disabled" {
    SHSEEKARR_INDEXER_TEST_ON_FAILURE=false
    local marker="$BATS_TEST_TMPDIR/indexer_retest"

    curl() {
        cat <<'EOF'
[
  {
    "source": "IndexerLongTermStatusCheck",
    "type": "warning",
    "message": "Indexers unavailable due to failures for more than 6 hours: Indexer"
  }
]
200
EOF
    }

    api_post_command() {
        touch "$marker"
        return 0
    }

    run connectivity_check http://localhost key v3

    [ "$status" -eq 0 ]
    [ ! -f "$marker" ]
}