
CREATE OR REPLACE PACKAGE XXTF_SIMPLE_LOG_PKG AS

/******************************************************************************

  Copyright 2020 togglefox.

  For details see www.togglefox.com/blogs/logging

  Ver   When    Who             What
  ----- ------- --------------- -------------------------
  1.0   01Feb20 Michael Carroll Initial creation.

******************************************************************************/

  type file_table is table of varchar2(4000);

  procedure set_dir_name(p_value in varchar2);
  procedure set_file_name(p_value in varchar2);
  procedure set_max_line_len(p_value in number);
  procedure set_table_name(p_value in varchar2);
  procedure remove;
  procedure log(p_text in varchar2);
  function copy_to_plsql_table(p_delete_flag in boolean) return file_table;
  procedure copy_to_table(p_delete_flag in boolean);
  procedure do_dbms_output(p_delete_flag in boolean);
  procedure test(p_delete_flag in boolean default true);
  procedure test_table(p_delete_flag in boolean default true);

  g_dir_name varchar2(30) := 'TMP';
  g_file_name varchar2(30) := 'togglefox.log';
  g_max_line_len number := 300;
  g_table_name varchar2(30) := 'xxtf_simple_log_output';

END XXTF_SIMPLE_LOG_PKG;
/

show errors

CREATE OR REPLACE PACKAGE BODY XXTF_SIMPLE_LOG_PKG AS

/******************************************************************************

  Copyright 2020 togglefox.

  For details see www.togglefox.com/blogs/logging

  Ver   When    Who             What
  ----- ------- --------------- -------------------------
  1.0   01Feb20 Michael Carroll Initial creation.

******************************************************************************/

  procedure set_dir_name(p_value in varchar2) is
  begin
    g_dir_name := p_value;
  end set_dir_name;

  procedure set_file_name(p_value in varchar2) is
  begin
    g_file_name := p_value;
  end set_file_name;

  procedure set_max_line_len(p_value in number) is
  begin
    g_max_line_len := p_value;
  end set_max_line_len;

  procedure set_table_name(p_value in varchar2) is
  begin
    g_table_name := p_value;
  end set_table_name;

  procedure file_close(p_handle in utl_file.file_type) is
    v_handle utl_file.file_type := p_handle;
  begin
    if utl_file.is_open(v_handle) then
      utl_file.fclose(v_handle);
    end if;
  exception
    when others then null;
  end file_close;

  function build_text(p_text in varchar2) return varchar2 is
  begin
    return substr(to_char(sysdate,'DDMMYY HH24:MI:SS.SSSS ')||p_text,1,g_max_line_len);
  end build_text;

  procedure remove is
  begin
    utl_file.fremove(g_dir_name, g_file_name);
  exception
    when others then null;
  end remove;
  
  procedure log(p_text in varchar2) is
    v_handle utl_file.file_type;
  begin
    v_handle := utl_file.fopen(g_dir_name, g_file_name, 'a', g_max_line_len);
    if p_text is not null then
      utl_file.put_line(v_handle, build_text(p_text));
    end if;
    file_close(v_handle);
  exception
    when others then
      file_close(v_handle);
  end log;

  function copy_to_plsql_table(p_delete_flag in boolean) return file_table is
    v_file_table file_table := file_table();
    v_handle utl_file.file_type;
    v_value varchar2(4000);
  begin
    v_handle := utl_file.fopen(g_dir_name, g_file_name, 'r');
    loop
      begin
        utl_file.get_line(v_handle,v_value);
        v_file_table.extend;
        v_file_table(v_file_table.count) := v_value;
      exception  
        when no_data_found then
          exit;
      end;
    end loop;
    file_close(v_handle);
    if p_delete_flag then
      remove;
    end if;
    return v_file_table;
  exception
    when others then
      file_close(v_handle);
      raise;
  end copy_to_plsql_table;

  procedure copy_to_table(p_delete_flag in boolean) is
    v_file_table file_table;
    v_sql varchar2(100);
  begin
    v_file_table := copy_to_plsql_table(p_delete_flag);
    v_sql := 'begin insert into '||g_table_name||' values (:output); end;';
    for a in 1..v_file_table.count loop
      execute immediate v_sql using in v_file_table(a);
    end loop;
  end copy_to_table;

  procedure do_dbms_output(p_delete_flag in boolean) is
    v_file_table file_table;
  begin
    dbms_output.enable(1000000);
    v_file_table := copy_to_plsql_table(p_delete_flag);
    for a in 1..v_file_table.count loop
      dbms_output.put_line(v_file_table(a));
    end loop;
  end do_dbms_output;

  procedure test(p_delete_flag in boolean default true) is
  begin
    remove;
    log('first test line.');
    log('another test line.');
    log('yet another test line.');
    log('final test line.');
    do_dbms_output(p_delete_flag);
  end test;

  procedure test_table(p_delete_flag in boolean default true) is
    type cursor_typ is ref cursor;
    v_cursor cursor_typ;
    v_output varchar2(4000);
  begin
    remove;
    log('first test line to db table.');
    log('another test line to db table.');
    log('yet another test line to db table.');
    log('final test line to db table.');
    copy_to_table(p_delete_flag);

    open v_cursor for 'select output from '||g_table_name||' order by output';
    loop
      fetch v_cursor into v_output;
      exit when v_cursor%notfound;
      dbms_output.put_line(v_output);
    end loop;
    close v_cursor;
  end test_table;

/* ****************************
To run tests as a basic test suite use the below;

set serverout on
begin
  XXTF_SIMPLE_LOG_PKG.test;
  dbms_output.put_line('*** Start test for db table output ***');
  delete from xxtf_simple_log_output;
  XXTF_SIMPLE_LOG_PKG.test_table;
end;
**************************** */



END XXTF_SIMPLE_LOG_PKG;
/

show errors

