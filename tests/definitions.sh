#!/usr/bin/env bash

get_problem_by_number() {
    curl -s \
        -H "Accept: application/json" \
        -H "Content-Type: application/json"  \
        --user "${SN_USER}:${SN_PASSWORD}" \
        "${SN_HOST}/api/now/table/problem?sysparm_query=number=${1}"
}

create_problem() {
    curl -s \
        -X POST \
        -H "Accept: application/json" \
        -H "Content-Type: application/json"  \
        --user "${SN_USER}:${SN_PASSWORD}" \
        --data "{ \"short_description\": \"${1}\" }" \
        "${SN_HOST}/api/now/table/problem" \
    | jq ".result.number"
}

update_problem_state_new_to_assessed() {
    local problem_number="$1"
    local new_state="102"
    local assigned_to="$2"

    curl -s \
        -X POST \
        -H "Accept: application/json" \
        -H "Content-Type: application/json"  \
        --user "${SN_USER}:${SN_PASSWORD}" \
        --data "{ \"assigned_to\": \"${assigned_to}\" }" \
        "${SN_HOST}/api/${SN_PST}/${problem_number}/new_state/${new_state}" \
    | jq ".result.state"
}