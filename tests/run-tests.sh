#!/usr/bin/env bash

source ./config.sh
source ./definitions.sh

# Create a new problem
p_number=$(create_problem "A new problem from curl")
echo "Created a problem: ${p_number}"

# Change problem's state from new to assessed
update_problem_state_new_to_assessed "${p_number}" "102" "d3dbbf173b331300ad3cc9bb34efc466"