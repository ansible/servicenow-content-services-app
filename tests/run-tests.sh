#!/usr/bin/env bash

set -e -o pipefail

source scenarios.sh

declare -a problems

cleanup() {
    for p in "${problems[@]}"
    do
        echo "Delete problem $p"
        delete_problem "$p"
    done
    unset problems
}

# Create a new problem
p1=$(create_problem_full_out "A new problem from curl (1)")
p1_number=$(get_problem_field "$p1" "number")
p1_sys_id=$(get_problem_field "$p1" "sys_id")
problems+=($p1_sys_id)
trap "cleanup" SIGQUIT SIGINT SIGABRT SIGKILL SIGTERM RETURN
echo "Created problem: $p1_number"

# Create a new problem
p=$(create_problem_full_out "A new problem from curl (2)")
p_number=$(get_problem_field "$p" "number")
p_sys_id=$(get_problem_field "$p" "sys_id")
problems+=($p_sys_id)
trap "cleanup" SIGQUIT SIGINT SIGABRT SIGKILL SIGTERM RETURN
echo "Created problem: $p_number"

# Get some user sys_id
user=$(get_user_id_at 0)
echo "Obtained user id: $user"

# TC-025: Change problem's state from new to an invalid state with error
err=$(problem_new_to_invalid_state "$p_number")
echo "New -> Invalid State (failed): $err"

# TC-026: Invalid problem number
err=$(invalid_problem_number)
echo "Invalid problem number (failed): $err"

# TC-027: Change problem's state from new to root cause analysis with error: invalid transition
err=$(problem_new_to_rca "$p_number")
echo "New -> Root Cause Analysis (failed): $err"

# TC-028: Change problem's state from new to fix in progress with error: invalid transition
err=$(problem_new_to_fix "$p_number")
echo "New -> Fix in Progress (failed): $err"

# TC-029: Change problem's state from new to resolved with error: invalid transition
err=$(problem_new_to_resolved "$p_number")
echo "New -> Resolved (failed): $err"

# TC-030: Change problem's state from new to closed with error: invalid transition
err=$(problem_new_to_closed "$p_number")
echo "New -> Closed (failed): $err"

# TC-001: Change problem's state from new to assessed
p=$(problem_new_to_assessed "$p_number" "$user")
state=$(get_problem_field "$p" "state")
echo "New -> Assessed: $state"

# TC-031: Change problem's state from assessed to fix in progress with error: invalid transition
err=$(problem_assessed_to_fix "$p_number")
echo "Assessed -> Fix in Progress (failed): $err"

# TC-032: Change problem's state from assessed to resolved with error: invalid transition
err=$(problem_assessed_to_resolved "$p_number")
echo "Assessed -> Resolved (failed): $err"

# TC-033: Change problem's state from assessed to new with error: invalid transition
err=$(problem_assessed_to_new "$p_number")
echo "Assessed -> New (failed): $err"

# TC-002: Change problem's state from assessed to root cause analysis
p=$(problem_assessed_to_rca "$p_number")
state=$(get_problem_field "$p" "state")
echo "Assessed -> Root Cause Analysis: $state"

# TC-034: Change problem's state from root cause analysis to assessed with error: invalid transition
err=$(problem_rca_to_assessed "$p_number")
echo "Root Cause Analysis -> Assessed (failed): $err"

# TC-035: Change problem's state from root cause analysis to new with error: invalid transition
err=$(problem_rca_to_new "$p_number")
echo "Root Cause Analysis -> New (failed): $err"

# TC-008: Change problem's state from root cause analysis to fix in progress with error: no field fix_notes
err=$(problem_rca_to_fix_no_fix_notes "$p_number" "some cause notes")
echo "Root Cause Analysis -> Fix in Progress (failed): $err"

# TC-009: Change problem's state from root cause analysis to fix in progress with error: no field cause_notes
err=$(problem_rca_to_fix_no_cause_notes "$p_number" "some fix notes")
echo "Root Cause Analysis -> Fix in Progress (failed): $err"

# TC-003: Change problem's state from root cause analysis to fix in progress
p=$(problem_rca_to_fix "$p_number" "some fix notes" "some cause notes")
state=$(get_problem_field "$p" "state")
echo "Root Cause Analysis -> Fix in Progress: $state"

# TC-036: Change problem's state from fix in progress to new with error: invalid transition
err=$(problem_fix_to_new "$p_number")
echo "Fix in Progress -> New (failed): $err"

# TC-037: Change problem's state from fix in progress to assessed with error: invalid transition
err=$(problem_fix_to_assessed "$p_number")
echo "Fix in Progress -> Assessed (failed): $err"

# TC-0010: Change problem's state from fix in progress to resolved with error: no field resolution_code
err=$(problem_fix_to_resolved_no_resolution_code "$p_number")
echo "Fix in Progress -> Resolved (failed): $err"

# TC-0011: Change problem's state from fix in progress to resolved with error: invalid resolution_code
err=$(problem_fix_to_resolved_invalid_resolution_code "$p_number")
echo "Fix in Progress -> Resolved (failed): $err"

# TC-004: Change problem's state from fix in progress to resolved
p=$(problem_fix_to_resolved "$p_number")
state=$(get_problem_field "$p" "state")
echo "Fix in Progress -> Resolved: $state"

# TC-038: Change problem's state from resolved to new with error: invalid transition
err=$(problem_resolved_to_new "$p_number")
echo "Resolved -> New (failed): $err"

# TC-039: Change problem's state from resolved to assessed with error: invalid transition
err=$(problem_resolved_to_assessed "$p_number")
echo "Resolved -> Assessed (failed): $err"

# TC-040: Change problem's state from resolved to fix in progress with error: invalid transition
err=$(problem_resolved_to_fix "$p_number")
echo "Resolved -> Fix in Progress (failed): $err"

# TC-005: Change problem's state from resolved to closed
p=$(problem_resolved_to_closed "$p_number")
state=$(get_problem_field "$p" "state")
echo "Resolved -> Closed: $state"

# TC-041: Change problem's state from closed to new with error: invalid transition
err=$(problem_closed_to_new "$p_number")
echo "Closed -> New (failed): $err"

# TC-042: Change problem's state from closed to assessed with error: invalid transition
err=$(problem_closed_to_assessed "$p_number")
echo "Closed -> Assessed (failed): $err"

# TC-043: Change problem's state from closed to fix in progress with error: invalid transition
err=$(problem_closed_to_fix "$p_number")
echo "Closed -> Fix in Progress (failed): $err"

# TC-006: Problem state new to assessed with error: no field assigned_to
err=$(problem_new_to_assessed_no_assigned_to "$p1_number")
echo "New -> Assessed (failed): $err"

# TC-012: Change problem's state from closed to root cause analysis
p=$(problem_closed_to_rca "$p_number")
state=$(get_problem_field "$p" "state")
echo "Closed -> Root Cause Analysis: $state"

# TC-014: Change problem's state from root cause analysis to closed by duplicate with error: no field duplicate_of
err=$(problem_rca_to_closed_by_duplicate_no_duplicate_of "$p_number")
echo "Root Cause Analysis -> Closed (by duplicate) (failed): $err"

# TC-015: Change problem's state from root cause analysis to closed by duplicate with error: no field resolution_code
err=$(problem_rca_to_closed_by_duplicate_no_resolution_code "$p_number" "$p1_sys_id")
echo "Root Cause Analysis -> Closed (by duplicate) (failed): $err"

# TC-013: Change problem's state from root cause analysis to closed by duplicate
p=$(problem_rca_to_closed_by_duplicate "$p_number" "$p1_sys_id")
state=$(get_problem_field "$p" "state")
echo "Root Cause Analysis -> Closed (by duplicate): $state"

# Problem closed (as duplicate) to root cause analysis (not possible from UI to reopen again?)
p=$(problem_closed_to_rca "$p_number")
state=$(get_problem_field "$p" "state")
echo "Closed -> Root Cause Analysis: $state"

# TC-019: Change problem's state from root cause analysis to closed by risk accepted with error: no resolution_code
err=$(problem_rca_to_closed_by_risk_accepted_no_resolution_code "$p_number" "some close notes")
echo "Root Cause Analysis -> Closed (by risk accepted) (failed): $err"

# TC-021: Change problem's state from root cause analysis to closed by risk accepted with error: no close_notes
err=$(problem_rca_to_closed_by_risk_accepted_no_close_notes "$p_number")
echo "Root Cause Analysis -> Closed (by risk accepted) (failed): $err"

# TC-018: Change problem's state from root cause analysis to closed by risk accepted
p=$(problem_rca_to_closed_by_risk_accepted "$p_number" "some close notes")
state=$(get_problem_field "$p" "state")
echo "Root Cause Analysis -> Closed (by risk accepted): $state"

# Problem closed (by risk accepted) to root cause analysis
p=$(problem_closed_to_rca "$p_number")
state=$(get_problem_field "$p" "state")
echo "Closed -> Root Cause Analysis: $state"

# TC-024: Change problem's state from root cause analysis to closed by cancel with error: no close notes
err=$(problem_rca_to_closed_by_cancel_no_close_notes "$p_number")
echo "Root Cause Analysis -> Closed (by cancel) (failed): $err"

# TC-022: Change problem's state from root cause analysis to closed by cancel
p=$(problem_rca_to_closed_by_cancel "$p_number" "some close notes")
state=$(get_problem_field "$p" "state")
echo "Root Cause Analysis -> Closed (by cancel): $state"

cleanup

exit


######################################################
# TC-007: Problem state new to assessed with error: invalid value for assigned_to
# This actually does not fail!
err=$(problem_new_to_assessed "$p1_number" "invalid")
echo "New -> Assessed (failed): $err"

# TC-016: Change problem's state from root cause analysis to closed by duplicate with error: duplicate of itself
# This does not fail!
err=$(problem_rca_to_closed_by_duplicate_self_duplicate "$p_number" "$p_sys_id")
echo "Root Cause Analysis -> Closed (by duplicate) (failed): $err"