/* ServiceNow: Script to Populate Variable Parameters in Incident Forms Raised by Record Producers

Run Location: Record Producers --> What it will contain

Builds Tested On: Eureka

Usage: Add the script to the 'Script' section under 'What it will contain' in a Record Producer. Modify / Add the variables to be populated on the Incident Record to suite your requirements

Reference: http://www.servicenowguru.com/scripting/adding-redirect-message-record-producer

Tips: 

You can add the value of anything from the generated record to the message by accessing the ‘current’ record object followed by the name of the field you want to access (current.short_description, current.number, etc.)

You can add the value of any record producer variable to the message by accessing the ‘producer’ object followed by the name of the variable you want to access (producer.var1, producer.var2, etc)

*/


//Get the values of the Record Producer variables to populate the generated Incident record
var notes = "New Consultant Request Form Submitted";
//Populate the 'work_notes' field
current.work_notes = notes;
//Populate the 'short_description' field
current.short_description = 'New Consultant Request Form';

//Populate reference fields
current.caller_id = gs.getUserID(); //Populate Caller with current user
current.assignment_group.setDisplayValue('SNOW.SD.SERVICE.DESK'); //Populate Assignment Group (name must be unique)
current.category.setDisplayValue('Service'); //Populate Category (name must be unique);
current.subcategory.setDisplayValue('User Administration'); //Populate SubCategory (name must be unique);
current.contact_type.setDisplayValue('Email'); //Populate ContactType (name must be unique);
current.u_business_service.setDisplayValue('Infrastructure Services'); //Populate BusinessService (name must be unique);
current.cmdb_ci.setDisplayValue('Account Management (FIM)'); //Populate ConfigurationItem (name must be unique);

//Create an information message 
var message = 'An incident ' + current.number + ' has been opened for you.<br/>';
message += 'The IT Service Desk will contact you for further information if necessary.<br/>';
//Add the information message
gs.addInfoMessage(message);
//Redirect the user to the 'cms' homepage
producer.redirect = '/asp/incident_status.do';