set serverout on
begin
  /*
  Basic test suite to test functionality of XXTF_SIMPLE_LOG_PKG is working correctly.
  */
  XXTF_SIMPLE_LOG_PKG.test;
  dbms_output.put_line('*** Start test for db table output ***');
  delete from xxtf_simple_log_output;
  XXTF_SIMPLE_LOG_PKG.test_table;
end;
/

