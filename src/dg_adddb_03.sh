#!/bin/bash
#startup rac ,and start apply.

export DG_UNIQUE_NAME=`./getcfg.sh dg_unique_name`

srvctl start database -d $DG_UNIQUE_NAME
srvctl status database -d $DG_UNIQUE_NAME

sqlplus  / as sysdba <<EOF
recover managed standby database using current logfile disconnect;
select open_mode, database_role from v\$database;
EOF
cd dgmonitor; sh ./checkscn.sh
