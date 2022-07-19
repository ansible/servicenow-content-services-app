(function process(/*RESTAPIRequest*/ request, /*RESTAPIResponse*/ response) {
	
	// Check path parameters
	const problem_number = request.pathParams.problem_number;
	const new_state = request.pathParams.new_state;
	
	const problem = new GlideRecord("problem");
	// 1: Does a problem with the given number exist?
	const problem_exists = problem.get("number", problem_number);

	if (! problem_exists) {
		// exception: no such problem
		var msg = gs.getMessage("No problem with number {0} exists.", problem_number);
		gs.error(msg);
		return new sn_ws_err.NotFoundError(msg);
	}	
	
	// Is the problem record readable and writable?
	if (! (problem.canRead() && problem.canWrite())) {
		// exception: cannot read or write into the record
		var msg = "Cannot read or write into a problem record";
		gs.error(msg);
		return new sn_ws_err.NotAcceptableError(msg);
	}
	
	// Does problem_state and state match?
	if (problem.state != problem.problem_state) {
		var msg = gs.getMessage("Cannot determine the current state of problem {0}.", problem_number);
		gs.error(msg);
		return new sn_ws_err.ConflictError(msg);
	}
		
	// 3: Is the transition from the current state to the new state allowed?
	const current_state = problem.state;
	const possible_state_transitions = {
		"101": ["102"],
		"102": ["103", "107"],
		"103": ["104", "106", "107"],
		"104": ["103", "106", "107"],
		"106": ["103", "107"],
		"107": ["103"]
	};
	
	// 2: Does new_state point to a valid state?
	if (! (new_state in possible_state_transitions)) {
		// exception: new_state is not a valid state
		var msg = gs.getMessage("Given state {0} is not a valid state.", new_state);
		gs.error(msg);
		return new sn_ws_err.BadRequestError(msg);
	}
	
	if (possible_state_transitions[current_state].indexOf(new_state) == -1) {
		// exception: transition from current state to the new state is not allowed
		var msg = gs.getMessage("Problem state transition from state {0} to {1} is not possible.", [current_state, new_state]);
		gs.error(msg);
		return new sn_ws_err.BadRequestError(msg);
	}
	
	// Check request body parameters
	
	// 1: Does the request supply all the required fields?
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
			
	var all_required_fields = [];
	for (var i in sorted_states) {
		var state = sorted_states[i];
		fields = state_required_new_fields[state];
		all_required_fields = all_required_fields.concat(fields);
		if (state === new_state) {
			break;
		}
	}
	
	// 2: Does the target problem state contain all the required fields?
	const body_data = request.body.data;
	while (all_required_fields.length > 0) {
		var field = all_required_fields.pop();
		if (gs.nil(field)) {
			// Not sure why field can be nil!!!
			continue;
		}
				
		var value = problem.getElement(field);
		if (gs.nil(value)) {
			value = body_data[field];
			if (gs.nil(value)) {
				var msg = gs.getMessage("Missing field {0}.", field);
				gs.error(msg);
				return new sn_ws_err.BadRequestError(msg);
			}
		}
		if (field == "resolution_code") {
			// check that the value is set to one of the valid resolution codes
			// value is not nil here
			if (! (value in resolution_code_required_fields)) {
				return new sn_ws_err.BadRequestError(gs.getMessage("resolution_code is set to {0}, which is not a valid value.", value));
			}
			all_required_fields = all_required_fields.concat(resolution_code_required_fields[value]);
		}
	}
	
	// Everything looks good. Update the supplemented fields
	for (var field in body_data) {
		if (! field in problem) {
			// exception: invalid field
			gs.warn(gs.getMessage("Invalid problem field {0}.", field));
			// ignore error
			continue;
		}
		if (! gs.nil(body_data[field])) {
			if (! problem.getElement(field).canWrite()) {
				// TODO: Should we silently fail instead?
				var msg = gs.getMessage("Cannot write to field {0}.", field);
				gs.error(msg);
				// Can we just ignore it? We should.
				// return sn_ws_err.BadRequestError(msg);
			}
			problem.setValue(field, body_data[field]);
		}
	}
	
	// Change the state
	problem.setValue("state", new_state);
	problem.setValue("problem_state", new_state);
	
	if (! problem.update()) {
		// exception: could not update record
		var msg = gs.getMessage("Cannot update problem record number {0}.", problem_number);
		gs.error(msg);
		return new sn_ws_err.BadRequestError(msg);
	}
	
	// Return the updated problem record
	var display_value = "false";
	if ("sysparm_display_value" in request.queryParams) {
		display_value = request.queryParams.sysparm_display_value; // FIXME: should be converted to lower case
	}
	var result = {};
	for (var i in problem.getElements()) {
		var element = problem.getElements()[i];
		// TODO: handle display value correctly
		var value = "";
		if (display_value === "true") {
			value = element.getDisplayValue();
		}
		else if (display_value === "all") {
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
	response.setBody(result); // FIXME: Besides display_valueshould we take into account queryParams?????
})(request, response);