#!/bin/bash
source /home/oracle/.bash_profile
CHECK_HOME=/home/oracle/autodg/dgcheck
cat > $CHECK_HOME/pri.sql <<EOF
set pagesize 9999
set linesize 120
set long 9999
set echo off
set termout off
col name for a20
col value for a50
col program for a10
col tracefile for a70
col db_unique_name for a20
col dest_2 for a99
col dest_3 for a99
col dest_4 for a99
col dest_5 for a99
col dest_6 for a99
col dest_state_2 for a10
col dest_state_3 for a10
col dest_state_4 for a10
col dest_state_5 for a10
col dest_state_6 for a10
col database_role for a15
col recovery_mode for a25
col status for a15
col message for a120

alter session set nls_language=american;
alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss';

spool $CHECK_HOME/pri.out
select sysdate from dual;
prompt ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>check v\$dataguard_status"
select message from v\$dataguard_status;
prompt ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>check database role from v\$database"
select database_role,open_mode,name from v\$database;

prompt ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>check database db_unique_name  from v\$parameter"
select value as "db_unique_name" from v\$parameter where name = 'db_unique_name';

prompt ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>check archive dest enabled and error from v\$parameter"
select value as "dest_2" from v\$parameter where name = 'log_archive_dest_2';
select value as "dest_3"  from v\$parameter where name = 'log_archive_dest_3';
select value as "dest_4"  from v\$parameter where name = 'log_archive_dest_4';
select value as "dest_5"  from v\$parameter where name = 'log_archive_dest_5';
select value as "dest_6"  from v\$parameter where name = 'log_archive_dest_6';
select value as "dest_state_2" from v\$parameter where name = 'log_archive_dest_state_2';
select value as "dest_state_3" from v\$parameter where name = 'log_archive_dest_state_3';
select value as "dest_state_4" from v\$parameter where name = 'log_archive_dest_state_4';
select value as "dest_state_5" from v\$parameter where name = 'log_archive_dest_state_5';
select value as "dest_state_6" from v\$parameter where name = 'log_archive_dest_state_6';


prompt ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>check dest status, recovery_mode from v\$archive_dest_status"
select dest_id,status,recovery_mode,error from v\$archive_dest_status where dest_id <= 6;

prompt ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>check max sequence# from v\$archived_log"
select thread#,max(sequence#) from v\$archived_log group by thread# order by thread#;

col program for a20
col tracefile for a70
prompt ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>check arch process tracefile from v\$process"
select pid, program, tracefile from v\$process where program like '%ARC%' order by pid;

prompt ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>the dump file directory is here:"
select value from v\$parameter where name = 'background_dump_dest';
prompt ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>check primary finish.please check alert file and trace file for more details."
spool off
exit;
EOF
sqlplus -s / as sysdba @$CHECK_HOME/pri.sql
