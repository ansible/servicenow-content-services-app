#!/usr/bin/env bash

source config.sh

state_new="101"
state_assessed="102"
state_rca="103"
state_fix="104"
state_resolved="106"
state_closed="107"

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
        | jq -r -M ".result"
}

sn_post_or_patch() {
    local method="$1"
    local uri="$2"
    local payload="$3"

    local msg=$(sn_request_with_payload "$method" "$uri" "$payload")

    echo "$msg" | jq -r -M 'try(.result) // .error.message'
}

sn_delete() {
    local uri="$1"

    sn_request "DELETE" "$uri" \
        | jq -r -M ".result"
}

sn_table_get() {
    local table_name="$1"
    local fields="$2"
    local query="$3"

    sn_get "now/table/${table_name}?sysparm_fields=${fields}&sysparm_query=${query}"
}

sn_table_post() {
    local table_name="$1"
    local payload="$2"

    sn_post_or_patch "POST" "now/table/${table_name}" "$payload"
}

sn_table_patch() {
    local table_name="$1"
    local payload="$2"

    sn_post_or_patch "PATCH" "now/table/${table_name}" "$payload"
}

sn_table_delete() {
    local table_name="$1"
    local sys_id="$2"

    sn_delete "now/table/${table_name}/${sys_id}"
}

get_problem_by_number() {
    local problem_number="$1"

    sn_table_get \
        "problem" \
        "" \
        "number=${problem_number}"
}

get_user_id_at() {
    local idx="$1"

    sn_table_get \
        "sys_user" \
        "sys_id,user_name" \
        "" \
        | jq -r ".[$idx].sys_id"
}

make_dict() {
    jq --null-input -M -r --arg "$1" "$2" "$3"
}

merge_dicts() {
    echo "$@" | jq -s -r -M add
}

create_problem_full_out() {
    local desc="$1"
    local payload=$(make_dict d "$desc" '{ "short_description": $d }')

    sn_table_post \
        "problem" \
        "$payload"
}

create_problem() {
    local desc="$1"
    
    create_problem_full_out "$desc" \
        | jq -r ".number"
}

update_problem() {
    local problem_number="$1"
    local new_state="$2"
    local payload="$3"

    sn_post_or_patch \
        "PATCH" \
        "${SN_PST}/${problem_number}/new_state/${new_state}" \
        "$payload"
}

delete_problem() {
    local problem_id="$1"

    sn_table_delete "problem" "$problem_id"
}

get_problem_field() {
    local problem="$1"
    local field_name="$2"

    echo "$problem" | jq -r -M ".$field_name"
}