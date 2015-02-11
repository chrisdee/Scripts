/* ServiceNow: Script to Merge Duplicate User Records

Run Location: System Definition --> Fix Scripts

Builds Tested On: Dublin / Eureka

Usage: 

Replace 'sys_id1' with the Sys ID of the user you want to merge, and replace 'sys_id2' with the Sys ID of the user you want to keep as the 'master' record
Remember to manually delete the 'sys_id1' user record after completing the merge

Reference: http://wiki.servicenow.com/index.php?title=Useful_User_Scripts

Tip:

Retrieve user sys_id details from the sys_user table: select first_name, last_name, user_name, email, sys_id from sys_user where first_name = 'UserFirstName'

*/

doit('sys_id1','sys_id2');
 
function doit(username1,username2) {
 
  var usr1 = new GlideRecord('sys_user');
  var usr2 = new GlideRecord('sys_user');
  var num = 0;
 
  if (usr1.get('sys_id',username1) && usr2.get('sys_id',username2)) {
    var ref;
    var dict = new GlideRecord('sys_dictionary');
    dict.addQuery('reference','sys_user');
    dict.addQuery('internal_type','reference');
    dict.addQuery('sys_class_name','!=','wf_activity_variable');
    dict.query();
    while (dict.next()) {
      num = 0;
      ref = new GlideRecord(dict.name.toString());
      ref.addQuery(dict.element,usr1.sys_id);
      ref.query();
      while (ref.nextRecord()) {
        ref.setValue(dict.element.toString(),usr2.sys_id);
        ref.setWorkflow(false);
        ref.update();
        num++;
      }
      if (num > 0) {
        gs.print(dict.element + ' changed from ' + usr1.user_name +
          ' to ' + usr2.user_name + ' in ' + num + ' ' + dict.name + ' records');
      }
    }
  }
}
