function getProblem(problem_number) {
	const problem = new GlideRecord("problem");
	// Does a problem with the given number exist?
	const problem_exists = problem.get("number", problem_number);

	if (! problem_exists) {
		// exception: no such problem
		var msg = gs.getMessage("No problem with number {0} exists.", problem_number);
		gs.error(msg);
		throw new sn_ws_err.NotFoundError(msg);
	}
	return problem;
}

function validateProblem(problem) {
	// Is the problem record readable and writable?
	if (! (problem.canRead() && problem.canWrite())) {
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
	if (! (current_state in possible_state_transitions)) {
		var err = new sn_ws_err.ServiceError();
		err.setStatus(500);
		var msg = gs.getMessage("Current state is not valid.");
		err.setMessage(msg);
		gs.error(msg);
		throw err;
	}
	
	// Is new state valid?
	if (! (new_state in possible_state_transitions)) {
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

function validateSuppliedFields(problem, new_state, body_data) {
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
		"fix_applied"  : ["cause_notes", "fix_notes"],
		"risk_accepted": ["cause_notes", "close_notes"],
		"canceled"     : ["close_notes"],
		"duplicate"    : ["duplicate_of"]
	};
	
	var sorted_states = [];
	for (var state in state_required_new_fields) {
		sorted_states.push(state);
	}
	sorted_states.sort();
	
	var all_required_fields = [];
	for (var i in sorted_states) {
		var state = sorted_states[i];
		var fields = state_required_new_fields[state];
		all_required_fields = all_required_fields.concat(fields);
		if (state == new_state) {
			break;
		}
	}
	
	// Does the new problem state contain all the required fields?
	while (all_required_fields.length > 0) {
		var field = all_required_fields.pop();
		if (field === undefined) { 
			// Not sure why field can be nil!!!
			throw new sn_ws_err.BadRequestError("field is undefined");
		}
		if (gs.nil(field)) {
			throw new sn_ws_err.BadRequestError("field is null");
		}
		
		var value;
		if (field in problem) {
			value = problem.getElement(field);
		}
		if (field in body_data) {
			value = body_data[field];
		}
		
		if (value === undefined || gs.nil(value)) {
			var msg = gs.getMessage("Missing field {0}.", field);
			gs.error(msg);
			throw new sn_ws_err.BadRequestError(msg);
		}
				
		if (field == "resolution_code") {
			// check that the value is set to one of the valid resolution codes
			// value is not nil here
			if (! (value in resolution_code_required_fields)) {
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
		if (! field in problem) {
			// exception: invalid field
			gs.warn(gs.getMessage("Invalid problem field {0}.", field));
			// ignore error
			continue;
		}
		var value = body_data[field];
		if (! gs.nil(value)) {
			if (! problem.getElement(field).canWrite()) {
				var msg = gs.getMessage("Cannot write to field {0}.", field);
				gs.warn(msg);
				// Can we just ignore it? We should.
				// throw new sn_ws_err.BadRequestError(msg);
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
	if (! problem.update("State transition")) {
		// exception: could not update record
		var msg = gs.getMessage("Cannot update problem record number {0}.", problem.number);
		gs.error(msg);
		throw new sn_ws_err.BadRequestError(msg);
	}
}

function buildResponse(problem, query_params) {
	var display_value = "false";
	if ("sysparm_display_value" in query_params) {
		display_value = String(query_params.sysparm_display_value || "false");
		display_value = display_value.toLowerCase();
	}
	
	var result = {};
	var msgs = [];
	for (var i in problem.getElements()) {
		var element = problem.getElements()[i];
		
		var value = "";
		if (display_value == "true") {
			value = element.getDisplayValue();
		}
		else if (display_value == "all") {
			value = {
				"display_value": element.getDisplayValue(),
				"value": element.toString()
			};
		}
		else {
			value = element.toString();
		}
			
		result[element.getName()] = value;
	}
	
	return result;
}

(function process(/*RESTAPIRequest*/ request, /*RESTAPIResponse*/ response) {
	// Get and validate
	const problem_number = String(request.pathParams.problem_number || "");
	
	const problem = getProblem(problem_number);
	validateProblem(problem);
	
	const current_state = problem.state.toString();
	const new_state = String(request.pathParams.new_state || "");
	
	validateStateTransition(current_state, new_state);
	
	const body_data = request.body.data;
	validateSuppliedFields(problem, new_state, body_data);
	
	// Assign new values
	assignSuppliedFields(problem, body_data);
	transitionProblemState(problem, new_state);
	updateProblemRecord(problem);
	
	// Prepare the result
	var result = buildResponse(problem, request.queryParams);
	response.setBody(result); // FIXME: Besides display_value should we take into account other queryParams?
})(request, response);