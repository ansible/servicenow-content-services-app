function getProblem(problem_number) {
    const problem = new GlideRecord("problem");
    // Does a problem with the given number exist?
    const problem_exists = problem.get("number", problem_number);

    if (!problem_exists) {
        // exception: no such problem
        var msg = gs.getMessage("No problem with number {0} exists.", problem_number);
        gs.error(msg);
        throw new sn_ws_err.NotFoundError(msg);
    }
    return problem;
}

function validateProblem(problem) {
    // Is the problem record readable and writable?
    if (!(problem.canRead() && problem.canWrite())) {
        // exception: cannot read or write into the record
        var msg = "Cannot read or write into a problem record";
        gs.error(msg);
        throw new sn_ws_err.NotAcceptableError(msg);
    }

    // Does problem_state and state match?
    if (problem.state != problem.problem_state) {
        var msg = gs.getMessage("Cannot determine the current state of problem {0}.", problem_number);
        gs.error(msg);
        throw new sn_ws_err.ConflictError(msg);
    }
}

function validateStateTransition(current_state, new_state) {
    const possible_state_transitions = {
        "101": ["102"],
        "102": ["103", "107"],
        "103": ["104", "106", "107"],
        "104": ["103", "106", "107"],
        "106": ["103", "107"],
        "107": ["103"]
    };

    // Is current state valid?
    if (!(current_state in possible_state_transitions)) {
        var err = new sn_ws_err.ServiceError();
        err.setStatus(500);
        var msg = gs.getMessage("Current state is not valid.");
        err.setMessage(msg);
        gs.error(msg);
        throw err;
    }

    // Is new state valid?
    if (!(new_state in possible_state_transitions)) {
        // exception: new_state is not a valid state
        var msg = gs.getMessage("Given new state {0} is not a valid state.", new_state);
        gs.error(msg);
        throw new sn_ws_err.BadRequestError(msg);
    }

    // Is the transition from the current state to the new state allowed?
    if (possible_state_transitions[current_state].indexOf(new_state) == -1) {
        // exception: transition from current state to the new state is not allowed
        var msg = gs.getMessage("Problem state transition from state {0} to {1} is not possible.", [current_state, new_state]);
        gs.error(msg);
        throw new sn_ws_err.BadRequestError(msg);
    }
}

function validateMandatoryFields(problem, current_state, new_state, body_data) {
    // Does the request supply all the required fields?
    const state_required_new_fields = {
        "101": ["short_description"],
        "102": ["assigned_to"],
        "103": [],
        "104": ["fix_notes", "cause_notes"],
        "106": ["resolution_code"],
        "107": []
    };

    const resolution_code_required_fields = {
        "fix_applied": ["cause_notes", "fix_notes"],
        "risk_accepted": ["cause_notes", "close_notes"],
        "canceled": ["close_notes"],
        "duplicate": ["duplicate_of"]
    };

    var sorted_states = [];
    for (var state in state_required_new_fields) {
        sorted_states.push(state);
    }
    sorted_states.sort();

    var target_state = new_state;
	if (new_state == "107")
		target_state = current_state;
	
	var all_required_fields = [];
	
    for (var i in sorted_states) {
        var state = sorted_states[i];
        var fields = state_required_new_fields[state];
        all_required_fields = all_required_fields.concat(fields);
        if (state == target_state) {
            break;
        }
    }
	
	if (new_state == "107")
		all_required_fields.push("resolution_code");

    // Does the new problem state contain all the required fields?
    while (all_required_fields.length > 0) {
        var field = all_required_fields.pop();
        
        var value;
        if (field in problem) {
            value = problem.getElement(field);
        }
        if (field in body_data) {
            value = body_data[field];
        }

        if (gs.nil(value)) {
            var msg = gs.getMessage("Missing field {0}.", field);
            gs.error(msg);
            throw new sn_ws_err.BadRequestError(msg);
        }

        if (field == "resolution_code") {
            // check that the value is set to one of the valid resolution codes
            // value is not nil here
            if (!(value in resolution_code_required_fields)) {
                var msg = gs.getMessage("resolution_code is set to {0}, which is not a valid value.", value);
                gs.error(msg);
                throw new sn_ws_err.BadRequestError(msg);
            }
            all_required_fields = all_required_fields.concat(resolution_code_required_fields[value]);
        }
    }
}

function assignSuppliedFields(problem, body_data) {
    // Everything looks good. Update the supplemented fields
    for (var field in body_data) {
        if (!field in problem) {
            // exception: invalid field
            gs.warn(gs.getMessage("Invalid problem field {0}.", field));
            // ignore error
            continue;
        }
        var value = body_data[field];
        if (!gs.nil(value)) {
            if (!problem.getElement(field).canWrite()) {
                var msg = gs.getMessage("Cannot write to field {0}.", field);
				// Despite looking as an error, we can still write to the record
                gs.warn(msg);
            }
            problem.setValue(field, value);
        }
    }
}

function transitionProblemState(problem, new_state) {
    // Change the state
    problem.setValue("state", new_state);
    problem.setValue("problem_state", new_state);
}

function updateProblemRecord(problem) {
    if (!problem.update("State transition")) {
        // exception: could not update record
        var msg = gs.getMessage("Cannot update problem record number {0}.", problem.number);
        gs.error(msg);
        throw new sn_ws_err.BadRequestError(msg);
    }
}

function getURLFromReferenceTable(ref_table, value) {
	var url = gs.getProperty("glide.servlet.uri");
	url = url + "api/now/table/";
	url = url + ref_table;
	url = url + "/" + value;
	return url;
}

function getLink(element, value) {
	var link = "";
	if (!gs.nil(element)) {
		var ed = element.getED();
		if (!gs.nil(ed)) {
			if ("reference" == ed.getInternalType()) {
				link = getURLFromReferenceTable(element.getReferenceTable(), value);
			}	
		}
	}
	return link;
}

function buildResponse(problem, query_params) {
    var display_value_param = "false";
    if ("sysparm_display_value" in query_params) {
        display_value_param = String(query_params.sysparm_display_value || "false");
        display_value_param = display_value_param.toLowerCase();
    }
	
	var exclude_reference_link = false;
	if ("sysparm_exclude_reference_link" in query_params) {
		exclude_reference_link = Boolean(query_params.sysparm_exclude_reference_link || "false");
	}
	
	var fields = [];
	if ("sysparm_fields" in query_params) {
		fields = String(query_params.sysparm_fields || "").split(",");
	}
	var out_fields;
	if (fields.length == 0) {
		out_fields = [];
		for (var f in problem) {
			out_fields.push(f);
		}
	}
	else {
		out_fields = fields;
	}
	
	var result = {};
    for (var i in out_fields) {
        var field = out_fields[i];
		
		var value = problem.getValue(field);
		var display_value = problem.getDisplayValue(field);
		var link;
		var field_value;
		
		if (!exclude_reference_link) {
			link = getLink(problem.getElement(field), value);
		}
		
		if (gs.nil(link)) {
			if (display_value_param == "true") {
				field_value = {
					"display_value": display_value
				};
			} else if (display_value_param == "all") {
				field_value = {
					"display_value": display_value,
					"value": value
				};
			} else {
				field_value = value;
			}
		}
		else {
			if (display_value_param == "all") {
				field_value = {
					"display_value": display_value,
					"link": link,
					"value": value
				};
			}
			else if (display_value_param == "true") {
				field_value = {
					"display_value": display_value,
					"link": link
				};
			}
			else {
				field_value = {
					"link": link,
					"value": value
				};
			}
		}
		
        result[field] = field_value;
    }

    return result;
}

(function process( /*RESTAPIRequest*/ request, /*RESTAPIResponse*/ response) {
    // Get and validate
    const problem_number = String(request.pathParams.problem_number || "");

    const problem = getProblem(problem_number);
    validateProblem(problem);

    const current_state = problem.state.toString();
    const new_state = String(request.pathParams.new_state || "");

    validateStateTransition(current_state, new_state);

    const body_data = request.body.data;
    validateMandatoryFields(problem, current_state, new_state, body_data);

    // Assign new values
    assignSuppliedFields(problem, body_data);
    transitionProblemState(problem, new_state);
    updateProblemRecord(problem);

    // Prepare the result
    var result = buildResponse(problem, request.queryParams);
    response.setBody(result);
})(request, response);