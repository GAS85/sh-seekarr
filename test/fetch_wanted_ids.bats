#!/usr/bin/env bats

@test "fetch_wanted_ids writes ids" {

    source ./sh-seekarr.sh

    connectivity_check() {
        :
    }

    api_get() {
cat <<EOF
{
  "totalRecords":1,
  "records":[
    {
      "id":42,
      "title":"Movie",
      "year":1999,
      "monitored":true
    }
  ]
}
EOF
    }

    tmp=$(mktemp)

    fetch_wanted_ids \
        http://x \
        key \
        v3 \
        wanted/missing \
        "$tmp" \
        "" \
        '[(.id|tostring), .title] | @tsv'

    run cat "$tmp"

    [ "$output" = $'42\tMovie' ]
}