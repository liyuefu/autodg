#!/bin/bash
source ./lib/autodglib.sh
export DB_NAME=`cat $TMPDIR/dbname.txt`
export ORACLE_BASE=`./getcfg.sh oracle_base_dg`
export ORACLE_HOME=`./getcfg.sh oracle_home_dg`
export ORACLE_SID=`./getcfg.sh oracle_dg_sid`
export DUPLICATE_ACTIVE=`./getcfg.sh duplicate_active`
export LOG_FILE="/home/oracle/autodg/tmp/autodg_dg.log"



msg_info "Standby startup listener..."
$ORACLE_HOME/bin/lsnrctl stop listener_duplicate >/dev/null 2>&1
$ORACLE_HOME/bin/lsnrctl start >/dev/null 2>&1
msg_info "Standby wait 10 seconds to reocver..."
sleep 10
msg_info "Standby alter database open read only"
msg_info "Standby alter database recover managed standby database..."
msg_info "Standby select max sequence "
if [ "$DUPLICATE_ACTIVE" = "yes" ]; then
"$ORACLE_HOME/bin/sqlplus" -s / as sysdba >> "$LOG_FILE" <<EOF
select sequence#,applied from v\$archived_log;
host sleep 10
alter database open read only;
alter system register;
alter database recover managed standby database using current logfile disconnect from session;
select max(sequence#) from v\$archived_log;
select open_mode,database_role from v\$database;
exit;
EOF
else
"$ORACLE_HOME/bin/sqlplus" -s / as sysdba >> "$LOG_FILE" <<EOF
start dg_crt_standbylog.sql;
alter database recover managed standby database using current logfile disconnect from session;
select max(sequence#) from v\$archived_log;
select open_mode,database_role from v\$database;
exit;
EOF
fi
