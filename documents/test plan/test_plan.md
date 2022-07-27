# Scoped App Test Plan

## API for Red Hat Ansible Automation Platform Certified Content Collection

Author: Uroš Paščinski (uros.pascinski@xlab.si)

Document version: 0.1 (draft)

### Design Document Breakdown

Section *ServiceNow Problem Management* in the *Application Design Document* describes how ServiceNow Platform represents and manages problems. Functionality tests, described in the following section, verify if the server-side script correctly implements the problem state transition and the validation associated with it. The tests are written as a HTTP client performing requests towards the exposed endpoint.

### Functionality Test Cases

Since the server-side script cannot create a new problem, the Table REST API is used first to create a new problem (via POST method). This is considered as the preparation on the testing. Test cases verify if updating a problem succeeds or fails with an error. To verify whether a test case succeeded or not, an HTTP GET request is performed against the respective Table REST API after the update to obtain the state and its associated fields.

| Test Case | Description                                                   | 
| --------- | ------------------------------------------------------------- |
| TC-001    | Transition a problem from state *new* to *assess* with success  |
| TC-002    | Transition a problem from state *assess* to *root cause analysis* with success |
| TC-003    | Transition a problem from state *root cause analysis* to *fix in progress* with success |
| TC-004    | Transition a problem from state *fix in progress* to *resolved* with success |
| TC-005    | Transition a problem from state *resolved* to *closed* with success |
| TC-006    | Transition a problem from state *new* to *assess* with error (no field *assigned_to*) |
| TC-007    | Transition a problem from state *new* to *assess* with error (invalid value of *assigned_to*) |
| TC-008    | Transition a problem from state *root cause analysis* to *fix in progress* with error (no field *cause_notes*) |
| TC-009    | Transition a problem from state *root cause analysis* to *fix in progress* with error (no field *fix_notes*) |
| TC-010    | Transition a problem from state *fix in progress* to *resolved* with error (no field *resolution_code=fix_applied*) |
| TC-011    | Transition a problem from state *fix in progress* to *resolved* with error (invalid value of *resolution_code*) |
| TC-012    | Transition a problem from state *closed* to *root cause analysis* with success |
| TC-013    | Transition a problem from state *root cause analysis* to *closed* as *duplicate* with success |
| TC-014    | Transition a problem from state *root cause analysis* to *closed* as *duplicate* with error (no field *duplicate_of*) |
| TC-015    | Transition a problem from state *root cause analysis* to *closed* as *duplicate* with error (invalid value of *duplicate_of*) |
| TC-016    | Transition a problem from state *root cause analysis* to *closed* as *duplicate* with error (value of *duplicate_of* points to itself) |
| TC-017    | Transition a problem from state *root cause analysis* to *closed* as *duplicate* with error (no field *resolution_code=duplicate*) |
| TC-018    | Transition a problem from state *root cause analysis* to *closed* as *risk accepted* with success |
| TC-019    | Transition a problem from state *root cause analysis* to *closed* as *risk accepted* with error (no field *resolution_code=risk_accepted*) |
| TC-020    | Transition a problem from state *root cause analysis* to *closed* as *risk accepted* with error (no field *cause_notes*) |
| TC-021    | Transition a problem from state *root cause analysis* to *closed* as *risk accepted* with error (no field *close_notes*) |
| TC-022    | Transition a problem from state *root cause analysis* to *closed* as *cancel* with success |
| TC-023    | Transition a problem from state *root cause analysis* to *closed* as *cancel* with error (no field *resolution_code=canceled*) |
| TC-024    | Transition a problem from state *root cause analysis* to *closed* as *cancel* with error (no field *close_notes*) |
| TC-025    | Transition a problem from state *new* to an invalid state with error |
| TC-026    | Transition a non-existing problem with error |
| TC-027    | Transition a problem from state *new* to *root cause analysis* with error (invalid transition) | 
| TC-028    | Transition a problem from state *new* to *fix in progress* with error (invalid transition) | 
| TC-029    | Transition a problem from state *new* to *resolved* with error (invalid transition) | 
| TC-030    | Transition a problem from state *new* to *closed* with error (invalid transition) | 
| TC-031    | Transition a problem from state *assess* to *fix in progress* with error (invalid transition) | 
| TC-032    | Transition a problem from state *assess* to *resolved* with error (invalid transition) | 
| TC-033    | Transition a problem from state *assess* to *new* with error (invalid transition) | 
| TC-034    | Transition a problem from state *root cause analysis* to *assess* with error (invalid transition) | 
| TC-035    | Transition a problem from state *root cause analysis* to *new* with error (invalid transition) | 
| TC-036    | Transition a problem from state *fix in progress* to *new* with error (invalid transition) | 
| TC-037    | Transition a problem from state *fix in progress* to *assess* with error (invalid transition) | 
| TC-038    | Transition a problem from state *resolved* to *new* with error (invalid transition) | 
| TC-039    | Transition a problem from state *resolved* to *assess* with error (invalid transition) | 
| TC-040    | Transition a problem from state *resolved* to *fix in progress* with error (invalid transition) | 
| TC-041    | Transition a problem from state *closed* to *new* with error (invalid transition) | 
| TC-042    | Transition a problem from state *closed* to *assess* with error (invalid transition) | 
| TC-043    | Transition a problem from state *closed* to *fix in progress* with error (invalid transition) | 


| Test Case | Expected Result |
| --------- | ----------------------------------------------- |
| TC-001    | Problem is in state *assess* |
| TC-002    | Problem is in state *root cause analysis* |
| TC-003    | Problem is in state *fix in progress* |
| TC-004    | Problem is in state *resolved* |
| TC-005    | Problem is in state *closed* and *resolution_code=fix_applied* |
| TC-006    | Problem is in state *new*, status code is not 200 |
| TC-007    | Problem is in state *new*, status code is not 200 |
| TC-008    | Problem is in state *root cause analysis*, status code is not 200 |
| TC-009    | Problem is in state *root cause analysis*, status code is not 200 |
| TC-010    | Problem is in state *fix in progress*, status code is not 200 |
| TC-011    | Problem is in state *fix in progress*, status code is not 200 |
| TC-012    | Problem is in state *root cause analysis* |
| TC-013    | Problem is in state *closed* and *resolution_code=duplicate* |
| TC-014    | Problem is in state *root cause analysis*, status code is not 200 |
| TC-015    | Problem is in state *root cause analysis*, status code is not 200 |
| TC-016    | Problem is in state *root cause analysis*, status code is not 200 |
| TC-017    | Problem is in state *root cause analysis*, status code is not 200 |
| TC-018    | Problem is in state *closed* and *resolution_code=risk_accepted* |
| TC-019    | Problem is in state *root cause analysis*, status code is not 200 |
| TC-020    | Problem is in state *root cause analysis*, status code is not 200 |
| TC-021    | Problem is in state *root cause analysis*, status code is not 200 |
| TC-022    | Problem is in state *closed* and *resolution_code=canceled* |
| TC-023    | Problem is in state *root cause analysis*, status code is not 200 |
| TC-024    | Problem is in state *root cause analysis*, status code is not 200 |
| TC-025    | Problem is in state *new*, status code is not 200 |
| TC-026    | Status code is not 200 |
| TC-027    | Problem is in state *new*, status code is not 200 |
| TC-028    | Problem is in state *new*, status code is not 200 |
| TC-029    | Problem is in state *new*, status code is not 200 |
| TC-030    | Problem is in state *new*, status code is not 200 |
| TC-031    | Problem is in state *assess*, status code is not 200 |
| TC-032    | Problem is in state *assess*, status code is not 200 |
| TC-033    | Problem is in state *assess*, status code is not 200 |
| TC-034    | Problem is in state *root cause analysis*, status code is not 200 |
| TC-035    | Problem is in state *root cause analysis*, status code is not 200 |
| TC-036    | Problem is in state *fix in progress*, status code is not 200 |
| TC-037    | Problem is in state *fix in progress*, status code is not 200 |
| TC-038    | Problem is in state *resolved*, status code is not 200 |
| TC-039    | Problem is in state *resolved*, status code is not 200 |
| TC-040    | Problem is in state *resolved*, status code is not 200 |
| TC-041    | Problem is in state *closed*, status code is not 200 |
| TC-042    | Problem is in state *closed*, status code is not 200 |
| TC-043    | Problem is in state *closed*, status code is not 200 |

### Debugging Demonstration
The application writes all errors to the `gs.error` log, which can be observed through the ServiceNow Platform instance.
