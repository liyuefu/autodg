
alter database add standby logfile thread 1  group 4 ('/u02/oradata/orcldg/dg_redo_4.log') size 100M;
alter database add standby logfile thread 1  group 5 ('/u02/oradata/orcldg/dg_redo_5.log') size 100M;
alter database add standby logfile thread 1  group 6 ('/u02/oradata/orcldg/dg_redo_6.log') size 100M;
alter database add standby logfile thread 1  group 7 ('/u02/oradata/orcldg/dg_redo_7.log') size 100M;
