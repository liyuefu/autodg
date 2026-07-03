--readme: 
--change to manual managemnet, rename all log file, and then clear them. 
--as there will be a standby logfile whose status is active, and can not be renamed until being cleaned .
--so rename all the standby log file again, and then clean them (as we don't know which one is active)
--after that, change back to auto and recover automaticaly.

--usage: 
--change the online log, standby log file path and name according to the v$lofile information. then run it as sysdba.

startup mount force;
alter system set standby_file_management='manual';

select member from v$logfile;
select group#,status from v$standby_log;

-- rename online log
alter database rename file '/u01/app/oracle/oradata/O19/redo01.log' to '/u02/oradata/o19dg2/redo01.log';
alter database rename file '/u01/app/oracle/oradata/O19/redo02.log' to '/u02/oradata/o19dg2/redo02.log';
alter database rename file '/u01/app/oracle/oradata/O19/redo03.log' to '/u02/oradata/o19dg2/redo03.log';


--clear standby logfile

--rename standby log
alter database rename file '/u02/oradata/o19dg/dg_redo_4.log' to '/u02/oradata/o19dg2/dg_redo_4.log';
alter database rename file '/u02/oradata/o19dg/dg_redo_5.log' to '/u02/oradata/o19dg2/dg_redo_5.log';
alter database rename file '/u02/oradata/o19dg/dg_redo_6.log' to '/u02/oradata/o19dg2/dg_redo_6.log';
alter database rename file '/u02/oradata/o19dg/dg_redo_7.log' to '/u02/oradata/o19dg2/dg_redo_7.log';

alter database clear logfile group 1;
alter database clear logfile group 2;
alter database clear logfile group 3;
alter database clear logfile group 4;
alter database clear logfile group 5;
alter database clear logfile group 6;
alter database clear logfile group 7;

alter database rename file '/u02/oradata/o19dg/dg_redo_4.log' to '/u02/oradata/o19dg2/dg_redo_4.log';
alter database rename file '/u02/oradata/o19dg/dg_redo_5.log' to '/u02/oradata/o19dg2/dg_redo_5.log';
alter database rename file '/u02/oradata/o19dg/dg_redo_6.log' to '/u02/oradata/o19dg2/dg_redo_6.log';
alter database rename file '/u02/oradata/o19dg/dg_redo_7.log' to '/u02/oradata/o19dg2/dg_redo_7.log';

alter database clear logfile group 4;
alter database clear logfile group 5;
alter database clear logfile group 6;
alter database clear logfile group 7;
--check which standby logfile is not renamed. (because of active )
select member from v$logfile;

alter system set standby_file_management='auto';
recover managed standby database disconnect;
recover managed standby database cancel;
alter database open;
recover managed standby database disconnect;

