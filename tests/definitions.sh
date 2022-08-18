#!/usr/bin/env bash

source config.sh

sn_request() {
    local method="$1"
    local uri="$2"

    curl -s \
        -X "$method" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        --user "${SN_USER}:${SN_PASSWORD}" \
        "${SN_HOST}/api/${uri}"
}

sn_request_with_payload() {
    local method="$1"
    local uri="$2"
    local payload="$3"

    curl -s \
        -X "$method" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        --user "${SN_USER}:${SN_PASSWORD}" \
        "${SN_HOST}/api/${uri}" \
        --data "$payload"
}

sn_get() {
    local uri="$1"

    sn_request "GET" "$uri" \
        | jq -r ".result"
}

sn_post() {
    local uri="$1"
    local payload="$2"

    sn_request_with_payload "POST" "$uri" "$payload" \
        | jq -r ".result"
}

sn_patch() {
    local uri="$1"
    local payload="$2"

    sn_request_with_payload "PATCH" "$uri" "$payload" \
        | jq -r ".result"
}

get_problem_by_number() {
    local problem_number="$1"

    sn_get "now/table/problem?sysparm_query=number=${problem_number}"
}

get_user_id_at() {
    local idx="$1"

    sn_get "now/table/sys_user?sysparm_fields=sys_id,user_name" \
        | jq -r ".[$idx].sys_id"
}

create_problem() {
    local desc="$1"
    local payload="{ \"short_description\": \"${desc}\" }"

    sn_post "now/table/problem/" "$payload" \
        | jq -r ".number"
}

update_problem() {
    local problem_number="$1"
    local new_state="$2"
    local payload="$3"

    sn_patch \
        "${SN_PST}/${problem_number}/new_state/${new_state}" \
        "$payload"
}

update_problem_state_new_to_assessed() {
    local problem_number="$1"
    local new_state="102"
    local assigned_to="$2"

    local payload="{ \"assigned_to\": \"${assigned_to}\" }"

    update_problem "$problem_number" "$new_state" "$payload" \
        | jq -r ".state"
}
