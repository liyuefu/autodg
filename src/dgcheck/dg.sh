#!/bin/bash
source /home/oracle/.bash_profile
CHECK_HOME=/home/oracle/autodg/dgcheck
cat > $CHECK_HOME/dg.sql <<EOF
set pagesize 9999
set linesize 120
set long 9999
set echo off
set termout off
col name for a20
col value for a50
col program for a20
col tracefile for a70
col db_unique_name for a20
col database_role for a20
col open_mode for a20
col message for a100

alter session set nls_language=american;
alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss';

spool $CHECK_HOME/dg.out
select sysdate from dual;

prompt ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>check v\$dataguard_status"
select message from v\$dataguard_status;

prompt ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>check database role from v\$database"
select database_role,open_mode,name from v\$database;
prompt ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>check db_unique_name from v\$parameter"
select value as "db_unique_name" from v\$parameter where name = 'db_unique_name';

prompt ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>check gap from v\$archive_gap"
select * from v\$archive_gap;

prompt ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>archived log BUT no applied yet from v\$archived_log"
select thread#,sequence#,applied from v\$archived_log where applied ='NO';

prompt ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>check max sequence#"
select thread#,max(sequence#) from v\$archived_log group by thread# order by thread#;

--too slow on product system
--SELECT ARCH.THREAD# "Thread", ARCH.SEQUENCE# "Last Sequence Received", APPL.SEQUENCE# "Last Sequence Applied", (ARCH.SEQUENCE# - APPL.SEQUENCE#) "Difference" FROM (SELECT THREAD# ,SEQUENCE# FROM V\$ARCHIVED_LOG WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V\$ARCHIVED_LOG GROUP BY THREAD#)) ARCH, (SELECT THREAD# ,SEQUENCE# FROM V\$LOG_HISTORY WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V\$LOG_HISTORY GROUP BY THREAD#)) APPL WHERE ARCH.THREAD# = APPL.THREAD# order by 1;


prompt ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>check MRP process from v\$managed_standby"
select process, thread#, sequence#, status from v\$managed_standby ;

prompt ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>check MRP trace file from v\$process"
select pid, program, tracefile from v\$process where program like '%MRP%';

--prompt ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>set arch log trace level 11"
--ALTER SYSTEM SET log_archive_trace=11 SCOPE=both;

prompt ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>the dump file directory is here:"
select value from v\$parameter where name = 'background_dump_dest';
prompt ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>"please check oracle alert file and mrp trace file for more details."

spool off
exit;

EOF
sqlplus -s / as sysdba  @$CHECK_HOME/dg.sql

if [ -f $CHECK_HOME/dg.sql ]; then
  rm $CHECK_HOME/dg.sql
fi
