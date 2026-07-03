set heading off
set echo off
set termout off
set linesize 20
set pagesize 9999
set feedback off

spool /home/oracle/autodg/src/../tmp/dbname.tmp
select lower(name) from v$database;
spool off

spool /home/oracle/autodg/src/../tmp/db_unique_name.tmp
select lower(db_unique_name) from v$database;
spool off

spool /home/oracle/autodg/src/../tmp/cluster.tmp
select value from v$parameter where name = 'cluster_database';
spool off

spool /home/oracle/autodg/src/../tmp/cluster_database_instances.tmp
select value from v$parameter where name = 'cluster_database_instances';
spool off


spool /home/oracle/autodg/src/../tmp/domain.tmp
select value from v$parameter where name = 'db_domain';
spool off

spool /home/oracle/autodg/src/../tmp/dbid.tmp
select dbid from v$database;
spool off

spool /home/oracle/autodg/src/../tmp/version.tmp
select rtrim(value) from v$parameter where name = 'compatible';
spool off


set linesize 120
spool /home/oracle/autodg/src/../tmp/dbpath.tmp
col name for a80
col member for a80
select name from v$datafile order by name;
select name from v$tempfile order by name;
spool off


spool /home/oracle/autodg/src/../tmp/logpath.tmp
col name for a80
set pagesize 9999
col member for a80
select member from v$logfile order by member;
spool off

spool /home/oracle/autodg/src/../tmp/logsize.tmp
select distinct(bytes/1024/1024) from v$log;
spool off
exit
