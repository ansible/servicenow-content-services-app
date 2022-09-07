#!/usr/bin/env bash

source definitions.sh

problem_new_to_assessed() {
    # assume: problem.state == 101
    local problem_number="$1"
    local new_state="$state_assessed"
    local assigned_to="$2"

    local payload=$(make_dict at "$assigned_to" '{ "assigned_to": $at }')

    update_problem "$problem_number" "$new_state" "$payload"
}

problem_new_to_rca() {
    # assume: problem.state == 101
    local problem_number="$1"
    local new_state="$state_rca"
    
    update_problem "$problem_number" "$new_state"
}

problem_new_to_fix() {
    # assume: problem.state == 101
    local problem_number="$1"
    local new_state="$state_fix"
    
    update_problem "$problem_number" "$new_state"
}

problem_new_to_resolved() {
    # assume: problem.state == 101
    local problem_number="$1"
    local new_state="$state_resolved"
    
    update_problem "$problem_number" "$new_state"
}

problem_new_to_closed() {
    # assume: problem.state == 101
    local problem_number="$1"
    local new_state="$state_closed"
    
    update_problem "$problem_number" "$new_state"
}

# Should fail
problem_new_to_assessed_no_assigned_to() {
    # assume: problem.state == 101
    local problem_number="$1"
    local new_state="$state_assessed"
    local assigned_to="$2"

    update_problem "$problem_number" "$new_state" 
}

problem_assessed_to_rca() {
    # assume: problem.state == 102
    local problem_number="$1"
    local new_state="$state_rca"

    update_problem "$problem_number" "$new_state"
}

problem_assessed_to_fix() {
    # assume: problem.state == 102
    local problem_number="$1"
    local new_state="$state_fix"

    update_problem "$problem_number" "$new_state"
}

problem_assessed_to_new() {
    # assume: problem.state == 102
    local problem_number="$1"
    local new_state="$state_new"

    update_problem "$problem_number" "$new_state"
}

problem_assessed_to_resolved() {
    # assume: problem.state == 102
    local problem_number="$1"
    local new_state="$state_resolved"

    update_problem "$problem_number" "$new_state"
}

problem_rca_to_fix() {
    # assume: problem.state == 103
    local problem_number="$1"
    local new_state="$state_fix"
    local fix_notes="$2"
    local cause_notes="$3"

    local fix_notes_d=$(make_dict fix "$fix_notes" '{ "fix_notes": $fix}')
    local cause_notes_d=$(make_dict cause "$cause_notes" '{ "cause_notes": $cause}')

    local payload=$(merge_dicts "$fix_notes_d" "$cause_notes_d")

    update_problem "$problem_number" "$new_state" "$payload"
}

problem_rca_to_assessed() {
    # assume: problem.state == 103
    local problem_number="$1"
    local new_state="$state_assessed"
    
    update_problem "$problem_number" "$new_state"
}

problem_rca_to_new() {
    # assume: problem.state == 103
    local problem_number="$1"
    local new_state="$state_new"
    
    update_problem "$problem_number" "$new_state"
}

problem_rca_to_fix_no_fix_notes() {
    # assume: problem.state == 103
    local problem_number="$1"
    local new_state="$state_fix"
    local cause_notes="$2"

    local payload=$(make_dict cause "$cause_notes" '{ "cause_notes": $cause}')

    update_problem "$problem_number" "$new_state" "$payload"
}

problem_rca_to_fix_no_cause_notes() {
    # assume: problem.state == 103
    local problem_number="$1"
    local new_state="$state_fix"
    local fix_notes="$2"
    
    local payload=$(make_dict fix "$fix_notes" '{ "fix_notes": $fix}')
    
    update_problem "$problem_number" "$new_state" "$payload"
}

problem_rca_to_closed_by_risk_accepted() {
    # assume: problem.state == 103
    local problem_number="$1"
    local new_state="$state_closed"
    local close_notes="$2"
    
    local close_notes_d=$(make_dict cn "$close_notes" '{ "close_notes": $cn }')
    local resolution_code_d='{ "resolution_code": "risk_accepted" }'
    local payload=$(merge_dicts "$close_notes_d" "$resolution_code_d")

    update_problem "$problem_number" "$new_state" "$payload"
}

problem_rca_to_closed_by_risk_accepted_no_resolution_code() {
    # assume: problem.state == 103
    local problem_number="$1"
    local new_state="$state_closed"
    local close_notes="$2"
    
    local payload=$(make_dict cn "$close_notes" '{ "close_notes": $cn }')
    
    update_problem "$problem_number" "$new_state" "$payload"
}

problem_rca_to_closed_by_risk_accepted_no_close_notes() {
    # assume: problem.state == 103
    local problem_number="$1"
    local new_state="$state_closed"
        
    local payload='{ "resolution_code": "risk_accepted" }'
    
    update_problem "$problem_number" "$new_state" "$payload"
}

problem_fix_to_resolved() {
    # assume: problem.state == 104
    local problem_number="$1"
    local new_state="$state_resolved"
    
    local payload='{ "resolution_code": "fix_applied" }'

    update_problem "$problem_number" "$new_state" "$payload"
}

problem_fix_to_new() {
    # assume: problem.state == 104
    local problem_number="$1"
    local new_state="$state_new"

    update_problem "$problem_number" "$new_state"
}

problem_fix_to_assessed() {
    # assume: problem.state == 104
    local problem_number="$1"
    local new_state="$state_assessed"

    update_problem "$problem_number" "$new_state"
}

problem_fix_to_resolved_no_resolution_code() {
    # assume: problem.state == 104
    local problem_number="$1"
    local new_state="$state_resolved"
    
    update_problem "$problem_number" "$new_state"
}

problem_fix_to_resolved_invalid_resolution_code() {
    # assume: problem.state == 104
    local problem_number="$1"
    local new_state="$state_resolved"
    
    local payload='{ "resolution_code": "invalid" }'

    update_problem "$problem_number" "$new_state" "$payload"
}

problem_resolved_to_closed() {
    # assume: problem.state == 106
    local problem_number="$1"
    local new_state="$state_closed"
    
    update_problem "$problem_number" "$new_state"
}

problem_resolved_to_new() {
    # assume: problem.state == 106
    local problem_number="$1"
    local new_state="$state_new"
    
    update_problem "$problem_number" "$new_state"
}

problem_resolved_to_assessed() {
    # assume: problem.state == 106
    local problem_number="$1"
    local new_state="$state_assessed"
    
    update_problem "$problem_number" "$new_state"
}

problem_resolved_to_fix() {
    # assume: problem.state == 106
    local problem_number="$1"
    local new_state="$state_fix"
    
    update_problem "$problem_number" "$new_state"
}

problem_closed_to_rca() {
    # assume: problem.state == 107
    local problem_number="$1"
    local new_state="$state_rca"
    
    update_problem "$problem_number" "$new_state"
}

problem_closed_to_new() {
    # assume: problem.state == 107
    local problem_number="$1"
    local new_state="$state_new"
    
    update_problem "$problem_number" "$new_state"
}

problem_closed_to_assessed() {
    # assume: problem.state == 107
    local problem_number="$1"
    local new_state="$state_assessed"
    
    update_problem "$problem_number" "$new_state"
}

problem_closed_to_fix() {
    # assume: problem.state == 107
    local problem_number="$1"
    local new_state="$state_fix"
    
    update_problem "$problem_number" "$new_state"
}

problem_rca_to_closed_by_duplicate() {
    # assume: problem.state == 103
    local problem_number="$1"
    local new_state="$state_closed"
    local duplicate_of="$2"

    local resolution_code='{ "resolution_code": "duplicate" }'
    local duplicate_of_d=$(make_dict d "$duplicate_of" '{ "duplicate_of": $d }')

    local payload=$(merge_dicts "$resolution_code" "$duplicate_of_d")

    update_problem "$problem_number" "$new_state" "$payload"
}

problem_rca_to_closed_by_duplicate_no_duplicate_of() {
    # assume: problem.state == 103
    local problem_number="$1"
    local new_state="$state_closed"
    
    local payload='{ "resolution_code": "duplicate" }'
    
    update_problem "$problem_number" "$new_state" "$payload"
}

problem_rca_to_closed_by_duplicate_no_resolution_code() {
    # assume: problem.state == 103
    local problem_number="$1"
    local new_state="$state_closed"
    local duplicate_of="$2"

    local payload=$(make_dict d "$duplicate_of" '{ "duplicate_of": $d }')

    update_problem "$problem_number" "$new_state" "$payload"
}

problem_rca_to_closed_by_duplicate_self_duplicate() {
    # assume: problem.state == 103
    # assume: problem_number is problem.sys_id
    local problem_number="$1"
    local new_state="$state_closed"
    local duplicate_of="$2"  # itself

    local resolution_code='{ "resolution_code": "duplicate" }'
    local duplicate_of_d=$(make_dict d "$duplicate_of" '{ "duplicate_of": $d }')

    local payload=$(merge_dicts "$resolution_code" "$duplicate_of_d")

    update_problem "$problem_number" "$new_state" "$payload"
}

problem_rca_to_closed_by_cancel() {
    # assume: problem.state == 103
    local problem_number="$1"
    local new_state="$state_closed"
    local close_notes="$2"
    
    local close_notes_d=$(make_dict cn "$close_notes" '{ "close_notes": $cn }')
    local resolution_code_d='{ "resolution_code": "canceled" }'
    local payload=$(merge_dicts "$close_notes_d" "$resolution_code_d")

    update_problem "$problem_number" "$new_state" "$payload"
}

problem_rca_to_closed_by_cancel_no_close_notes() {
    # assume: problem.state == 103
    local problem_number="$1"
    local new_state="$state_closed"
        
    local payload='{ "resolution_code": "canceled" }'
    
    update_problem "$problem_number" "$new_state" "$payload"
}

problem_new_to_invalid_state() {
    # assume: problem.state == 101
    local problem_number=$1
    local new_state="100"

    update_problem "$problem_number" "$new_state"
}

invalid_problem_number() {
    local problem_number="PRB1"
    local new_state="$state_assessed"

    update_problem "$problem_number" "$new_state"
}