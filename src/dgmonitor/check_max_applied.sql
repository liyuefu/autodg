set heading off
set echo off
set termout off
spool check_max_applied1.txt
select max(sequence#) from v$archived_log where thread# = 1 and applied in ('YES','IN-MEMORY') and resetlogs_id in ( select * from (SELECT resetlogs_id FROM v$archived_log ORDER BY first_time) where rownum=1);

spool off
spool check_max_applied2.txt
select max(sequence#) from v$archived_log where thread# = 2 and applied in ('YES','IN-MEMORY') and resetlogs_id in ( select * from (SELECT resetlogs_id FROM v$archived_log ORDER BY first_time) where rownum=1);
spool off
exit
