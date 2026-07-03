#!/bin/bash

source ./lib/autodglib.sh
#create path for standby.
#audit, data_path, log_path,arch_path
#source $HOME/.bash_profile
#rac-rac, 必须设置echo "  set db_create_online_log_dest_1='"$DGPATH"'"  否则standby日志不能自动建立.log_convert参数没用.
#update: 2024.04.24. add exist dg support.
#update: 2024.04.27. 如果主库备库ORACLE_BASE不同,需要在spfile中set audit_file_dest 和 diagnostic_dest. 否则dg库启动失败.
#update: 2024.05.29. 增加参数 dgomf, 取值yes, 设置 db_create_file_dest,使用OMF.否则不设置.
#update: 2026.02.07. dup.cmd,当不使用OMF时，设置db_create_file_dest为空字符串''. 否则从RAC 搭建时缺省是'+data',而dg建数据文件有限使用db_create_file_dest这个参数，而不是convert参数。导致建文件失败。

export TMPDIR="$TMPDIR"
export EXECUTE_DATE=`date +%Y-%m-%d_%H-%M-%S`
export ORACLE_SID=`./getcfg.sh oracle_sid`
export ORACLE_DG_SID=`./getcfg.sh oracle_dg_sid`
export ORACLE_HOME=`./getcfg.sh oracle_home_pr`
export ORACLE_HOME_DG=`./getcfg.sh oracle_home_dg`
export ORACLE_BASE=`./getcfg.sh oracle_base_pr`
export ORACLE_BASE_DG=`./getcfg.sh oracle_base_dg`
export STAGEPR=`./getcfg.sh stagepr`
export DG_UNIQUE_NAME=`./getcfg.sh dg_unique_name`

export AUTOSETARCH=`./getcfg.sh autosetarch`
export DG_UNIQUE_NAME=`./getcfg.sh dg_unique_name`

export DG_LOG_ARCHIVE_DEST="log_archive_dest_"`./getcfg.sh  dg_log_archive_dest` #备库向主库传归档日志
export PRI_LOG_ARCHIVE_DEST="log_archive_dest_"`./getcfg.sh  pri_log_archive_dest` #主库向备库传归档日志
export PRI_LOG_ARCHIVE_DEST_STATE="log_archive_dest_state_"`./getcfg.sh  pri_log_archive_dest` #主库向备库传归档日志
export EXIST_DG_UNIQUE_NAME_LIST=`./getcfg.sh exist_dg_unique_name_list`
export SET_CASCADE=`./getcfg.sh set_cascade`

export DGPATH=`./getcfg.sh dgpath`
export DGARCH=`./getcfg.sh dgarch`
export DGOMF=`./getcfg.sh dgomf`
export IPPR=`./getcfg.sh ippr`
export IPDG=`./getcfg.sh ipdg`
export FIX_DATAFILE_SAME_NAME=`./getcfg.sh fix_datafile_same_name`
export DUPLICATE_ACTIVE=`./getcfg.sh duplicate_active`
export RMAN_BACKUP_DIR=`./getcfg.sh rman_backup_dir`
export INFO='\033[0;34mINFO: \033[0m'


export PRILOGPATH=`cat $TMPDIR/addlogpath.txt`
export DB_NAME=`cat $TMPDIR/dbname.txt`
export DB_UNIQUE_NAME=`cat $TMPDIR/db_unique_name.txt`
export CLUSTER=`cat $TMPDIR/cluster.txt`
export CLUSTER_DATABASE_INSTANCES=`cat $TMPDIR/cluster_database_instances.txt`
export INITORA="$TMPDIR/init$ORACLE_DG_SID.ora"
export TNSNAMES="$TMPDIR/tnsnames.ora"
export DG_LISTENER="$TMPDIR/listener.ora"
export DUPCMD="$TMPDIR/dup.cmd"
export PRI_MODIFY_SQL="$TMPDIR/pri_modify.sql"
msg_info "cascade: $SET_CASCADE"
if [ $SET_CASCADE == "no" ]; then
  # not cascade data guard
  export PRI_MODIFY_MODEL="pri_modify.model"
else
  # cascade data guard
  export PRI_MODIFY_MODEL="pri_cascade_modify.model"
fi
msg_info "pri_modify_model: $PRI_MODIFY_MODEL"
export LOG_CNT_FILE="$TMPDIR/log_cnt.txt"
export LOG_MAX_FILE="$TMPDIR/log_max.txt"
export LOG_SIZE_FILE="$TMPDIR/log_size.txt"
export AUDITDG=$ORACLE_BASE_DG/admin/$DB_NAME/adump
export DG_CRT_SBYLOG="$TMPDIR/dg_crt_standbylog.sql"
export PRI_CRT_SBYLOG="$TMPDIR/pri_crt_standbylog.sql"

create_init_file() {
  msg_info "dg  name convert :$DG_NAMECONVERT"
  msg_info "dg log name convert :$DG_LOGCONVERT"
  msg_info "dg create init.ora"
  #create INITORA.ora
  echo "db_name='"$DB_NAME"'" > $INITORA
  echo "db_unique_name='"$DG_UNIQUE_NAME"'">>$INITORA
  echo "db_domain='"$DB_DOMAIN"'">>$INITORA
  echo "compatible="`cat $TMPDIR/version.txt`>>$INITORA
  echo "control_files='"$DGPATH\/control01.ctl\',\'$DGPATH\/control02.ctl\',\'$DGPATH\/control03.ctl\'>>$INITORA
  echo "audit_file_dest='"$AUDITDG\' >>$INITORA
  echo "audit_trail='none'">>$INITORA
  echo "db_file_name_convert="$DG_NAMECONVERT>>$INITORA
  echo "log_file_name_convert="$DG_LOGCONVERT>>$INITORA
  echo "fal_client='"$DG_UNIQUE_NAME"'">>$INITORA
  echo "fal_server='"$DB_UNIQUE_NAME"'">>$INITORA
  if [ ${EXIST_DG_UNIQUE_NAME_LIST} == "no" ] ; then
    echo "log_archive_config='dg_config=("$DG_UNIQUE_NAME,$DB_UNIQUE_NAME\)\' >>$INITORA
  else
    echo "log_archive_config='dg_config=(${EXIST_DG_UNIQUE_NAME_LIST},"$DG_UNIQUE_NAME,$DB_UNIQUE_NAME\)\' >>$INITORA
    if [ ${SET_CASCADE} == "no" ]; then
      echo "${DG_LOG_ARCHIVE_DEST}='service="$DB_UNIQUE_NAME" lgwr async valid_for=(online_logfiles,primary_role) db_unique_name="$DB_UNIQUE_NAME"'">>$INITORA
    else
      echo "${DG_LOG_ARCHIVE_DEST}='service="$DB_UNIQUE_NAME" lgwr async valid_for=(standby_logfiles,standby_role) db_unique_name="$DB_UNIQUE_NAME"'">>$INITORA
    fi
  fi
  echo "log_archive_dest_1='location="$DGARCH"'" >>$INITORA
  echo "standby_file_management='auto'">>$INITORA

}

#create tnsnames.ora 
create_tnsnames_file() {

  # if exists data guard, append new tnsnames content, otherwise create new tnsnames.ora file
  if [ ${EXIST_DG_UNIQUE_NAME_LIST} == "no" ] ; then
		> $TNSNAMES
	fi 

  if [ -z "$DB_DOMAIN" ]; then
    echo $DB_UNIQUE_NAME" = (DESCRIPTION = (ADDRESS_LIST = (ADDRESS = (PROTOCOL = TCP)(HOST = "$IPPR")(PORT = 1521))) (CONNECT_DATA = (SERVICE_NAME = "$DB_UNIQUE_NAME")))" >>$TNSNAMES
    echo $DG_UNIQUE_NAME" = (DESCRIPTION = (ADDRESS_LIST = (ADDRESS = (PROTOCOL = TCP)(HOST = "$IPDG")(PORT = 1521))) (CONNECT_DATA = (SERVICE_NAME = "$DG_UNIQUE_NAME")))" >>$TNSNAMES
    echo "dup = (DESCRIPTION = (ADDRESS_LIST = (ADDRESS = (PROTOCOL = TCP)(HOST = "$IPDG")(PORT = 1525))) (CONNECT_DATA = (SERVICE_NAME = "$DG_UNIQUE_NAME")))" >>$TNSNAMES
  else
    echo $DB_UNIQUE_NAME" = (DESCRIPTION = (ADDRESS_LIST = (ADDRESS = (PROTOCOL = TCP)(HOST = "$IPPR")(PORT = 1521))) (CONNECT_DATA = (SERVICE_NAME = "$DB_UNIQUE_NAME.$DB_DOMAIN")))" >>$TNSNAMES
    echo $DG_UNIQUE_NAME" = (DESCRIPTION = (ADDRESS_LIST = (ADDRESS = (PROTOCOL = TCP)(HOST = "$IPDG")(PORT = 1521))) (CONNECT_DATA = (SERVICE_NAME = "$DG_UNIQUE_NAME.$DB_DOMAIN")))" >>$TNSNAMES
    echo "dup = (DESCRIPTION = (ADDRESS_LIST = (ADDRESS = (PROTOCOL = TCP)(HOST = "$IPDG")(PORT = 1525))) (CONNECT_DATA = (SERVICE_NAME = "$DG_UNIQUE_NAME")))" >>$TNSNAMES
  fi

}


create_listener_file() {
#create listener.ora
  echo "LISTENER_duplicate =">$DG_LISTENER
  echo " (ADDRESS_LIST=">>$DG_LISTENER
  echo "      (ADDRESS=(PROTOCOL=tcp)(HOST="$IPDG")(PORT=1525))">>$DG_LISTENER
  echo " )">>$DG_LISTENER
  echo "SID_LIST_LISTENER_duplicate=">>$DG_LISTENER
  echo "  (SID_LIST=">>$DG_LISTENER
  echo "      (SID_DESC=">>$DG_LISTENER
  if [ -z "$DB_DOMAIN" ]; then
    echo "         (GLOBAL_DBNAME="$DG_UNIQUE_NAME")">>$DG_LISTENER
  else
    echo "         (GLOBAL_DBNAME="$DG_UNIQUE_NAME"."$DB_DOMAIN")">>$DG_LISTENER
  fi
  echo "         (SID_NAME="$ORACLE_DG_SID")">>$DG_LISTENER
  echo "         (ORACLE_HOME="$ORACLE_HOME_DG")">>$DG_LISTENER
  echo "       )">>$DG_LISTENER
  echo "   )">>$DG_LISTENER
}

create_dup_cmd() {

  #create dup.cmd
  if [ -f dup.cmd ];then
    rm dup.cmd
  fi
  echo "run { "> $DUPCMD
  if [ "$DUPLICATE_ACTIVE" == "yes" ]; then
    echo "allocate channel ch00 device type disk;">>$DUPCMD
    echo "allocate channel ch01 device type disk;">>$DUPCMD
    echo "allocate channel ch02 device type disk;">>$DUPCMD
    echo "allocate channel ch03 device type disk;">>$DUPCMD
    echo "allocate auxiliary channel ch04 device type disk;">>$DUPCMD
    echo "allocate auxiliary channel ch05 device type disk;">>$DUPCMD
    echo "allocate auxiliary channel ch06 device type disk;">>$DUPCMD
    echo "allocate auxiliary channel ch07 device type disk;">>$DUPCMD
  else
    echo "allocate auxiliary channel ch04 device type disk;">>$DUPCMD
    echo "allocate auxiliary channel ch05 device type disk;">>$DUPCMD
    echo "allocate auxiliary channel ch06 device type disk;">>$DUPCMD
    echo "allocate auxiliary channel ch07 device type disk;">>$DUPCMD
  fi
  if [ $FIX_DATAFILE_SAME_NAME == "yes" ]; then
    echo "SET NEWNAME FOR DATABASE TO '"$DGPATH"/%U';" >>$DUPCMD
  fi
  echo "duplicate target database" >>$DUPCMD
  echo "for standby" >> $DUPCMD
  if [ "$DUPLICATE_ACTIVE" = "yes" ]; then
    echo "from active database" >>$DUPCMD
    echo "dorecover" >>$DUPCMD
  fi

  echo "spfile" >>$DUPCMD
  echo "  set control_files='"$DGPATH\/control01.ctl\',\'$DGPATH\/control02.ctl\',\'$DGPATH\/control03.ctl\'>>$DUPCMD
  echo "  set db_unique_name='"$DG_UNIQUE_NAME"'">>$DUPCMD
  echo "  set audit_trail='none'">>$DUPCMD
  echo "  set fal_client='"$DG_UNIQUE_NAME"'">>$DUPCMD
  echo "  set fal_server='"$DB_UNIQUE_NAME"'">>$DUPCMD

  if [ ${EXIST_DG_UNIQUE_NAME_LIST} == "no" ]; then
    echo "set log_archive_config='dg_config=("$DG_UNIQUE_NAME,$DB_UNIQUE_NAME\)\' >>$DUPCMD
  else
    echo "set log_archive_config='dg_config=(${EXIST_DG_UNIQUE_NAME_LIST},"$DG_UNIQUE_NAME,$DB_UNIQUE_NAME\)\' >>$DUPCMD
  fi
  #echo "  set log_archive_config='dg_config=("$DB_UNIQUE_NAME","$DG_UNIQUE_NAME")'">>$DUPCMD
  echo "  set db_file_name_convert="$DG_NAMECONVERT>>$DUPCMD
  echo "  set log_file_name_convert="$DG_LOGCONVERT>>$DUPCMD
  echo "  set standby_file_management='auto'">>$DUPCMD
  echo "  set cluster_database='false'">>$DUPCMD
  echo "  set local_listener=''">>$DUPCMD
  echo "  set remote_listener=''">>$DUPCMD
  echo "  set db_recovery_file_dest=''">>$DUPCMD
  if [ $DGOMF == "yes" ]; then
    echo "  set db_create_file_dest='"$DGPATH"'">>$DUPCMD
    echo "  set db_create_online_log_dest_1='"$DGPATH"'" >>$DUPCMD
  else
    echo "  set db_create_file_dest='""'">>$DUPCMD
    echo "  set db_create_online_log_dest_1='""'" >>$DUPCMD
  fi

  echo "  set log_archive_dest_1='location="$DGARCH"'" >>$DUPCMD
  echo "  set $DG_LOG_ARCHIVE_DEST='service="$DB_UNIQUE_NAME" lgwr async valid_for=(online_logfiles,primary_role) db_unique_name="$DB_UNIQUE_NAME"'">>$DUPCMD
  echo "  set log_archive_dest_1='location="$DGARCH"'" >>$DUPCMD
  echo "  set audit_file_dest='"$AUDITDG"'" >>$DUPCMD
  echo "  set diagnostic_dest='"$ORACLE_BASE_DG"'" >>$DUPCMD

  if [ "$DUPLICATE_ACTIVE" = "yes" ]; then
    echo "nofilenamecheck;">>$DUPCMD
  else
    echo "BACKUP LOCATION '"$RMAN_BACKUP_DIR"' nofilenamecheck;" >>$DUPCMD
  fi
  if [ "$DUPLICATE_ACTIVE" == "yes" ]; then
    echo "release channel ch00; " >> $DUPCMD
    echo "release channel ch01; " >> $DUPCMD
    echo "release channel ch02; " >> $DUPCMD
    echo "release channel ch03; " >> $DUPCMD
    echo "release channel ch04; " >> $DUPCMD
    echo "release channel ch05; " >> $DUPCMD
    echo "release channel ch06; " >> $DUPCMD
    echo "release channel ch07; " >> $DUPCMD
  else
    echo "release channel ch04; " >> $DUPCMD
    echo "release channel ch05; " >> $DUPCMD
    echo "release channel ch06; " >> $DUPCMD
    echo "release channel ch07; " >> $DUPCMD
  fi
  echo "}" >> $DUPCMD

}
create_pri_add_standbylog_sql() {
  # create sql script to create dg standby redo
  $ORACLE_HOME/bin/sqlplus -s / as sysdba<<EOF
  set heading off
  spool $LOG_CNT_FILE
  select count(*) from v\$log;
  spool off
  exit
EOF

  #对于RAC, 比如2个实例. 有4组日志时,其实每个实例只有2组.所以LOGCNT要除以2.
  if [ $CLUSTER_DATABASE_INSTANCES -gt 1 ];then
    LOGCNT=$((LOGCNT/CLUSTER_DATABASE_INSTANCES))
  fi

  $ORACLE_HOME/bin/sqlplus -s / as sysdba<<EOF
  set heading off
  spool $LOG_MAX_FILE
  select max(group#) from v\$log;
  spool off
  exit
EOF


  $ORACLE_HOME/bin/sqlplus -s / as sysdba<<EOF
  set heading off
  spool $LOG_SIZE_FILE
  select max(bytes/1024/1024)as M  from v\$log;
  spool off
  exit
EOF

  local LOGCNT=`cat $LOG_CNT_FILE |  sed '/^[  ]*$/d' | awk {'print $1'}`
  local LOGMAX=`cat $LOG_MAX_FILE |  sed '/^[  ]*$/d' | awk {'print $1'}`
  local LOGSIZE=`cat $LOG_SIZE_FILE |  sed '/^[  ]*$/d' | awk {'print $1'}`


  ((LOGMAX++))
  ((LOGCNT++))
  DG_LOGMAX=$LOGMAX
  echo $DG_LOGMAX
  echo $LOGMAX
  echo "" > $PRI_CRT_SBYLOG
  echo "" > $DG_CRT_SBYLOG
  while [ $LOGCNT -gt 0 ];do
    if ( echo $PRILOGPATH |grep '+' );then
      echo "alter database add standby logfile thread 1  group $LOGMAX size $LOGSIZE M;">>$PRI_CRT_SBYLOG
      ((LOGMAX++))
      if [ $CLUSTER = "TRUE" ]; then
        echo "alter database add standby logfile thread 2 group $LOGMAX  size $LOGSIZE M;">>$PRI_CRT_SBYLOG
        ((LOGMAX++))
      fi
    else
      echo "alter database add standby logfile thread 1  group $LOGMAX ('"$PRILOGPATH"/dg_redo_"$LOGMAX".log') size "$LOGSIZE"M;">>$PRI_CRT_SBYLOG
      ((LOGMAX++))
      if [ $CLUSTER = "TRUE" ]; then
        echo "alter database add standby logfile thread 2  group $LOGMAX ('"$PRILOGPATH"/dg_redo_"$LOGMAX".log') size "$LOGSIZE"M;">>$PRI_CRT_SBYLOG
        ((LOGMAX++))
      fi

    fi 
    if ( echo $DGPATH |grep '+' );then
      echo "alter database add standby logfile thread 1  group $DG_LOGMAX '"$DGPATH"' size $LOGSIZE M;">>$DG_CRT_SBYLOG
      ((DG_LOGMAX++))
      if [ $CLUSTER = "TRUE" ]; then
        echo "alter database add standby logfile thread 2 group $DG_LOGMAX '"$DGPATH"' size $LOGSIZE M;">>$DG_CRT_SBYLOG
        ((DG_LOGMAX++))
      fi
    else
      echo "alter database add standby logfile thread 1  group $DG_LOGMAX ('"$DGPATH"/dg_redo_"$DG_LOGMAX".log') size "$LOGSIZE"M;">>$DG_CRT_SBYLOG
      echo "alter database add standby logfile thread 1  group $DG_LOGMAX ('"$DGPATH"/dg_redo_"$DG_LOGMAX".log') size "$LOGSIZE"M;"
      ((DG_LOGMAX++))
      if [ $CLUSTER = "TRUE" ]; then
        echo "alter database add standby logfile thread 2  group $DG_LOGMAX ('"$DGPATH"/dg_redo_"$DG_LOGMAX".log') size "$LOGSIZE"M;">>$DG_CRT_SBYLOG
        ((DG_LOGMAX++))
      fi
    fi 

    ((LOGCNT--))
  done
  echo "exit;" >> $PRI_CRT_SBYLOG

}


backup_and_update_pri_tnsnames_file() {
  #backup old tnsnames.ora
  if  [ -f $ORACLE_HOME/network/admin/tnsnames.ora ];then
    cp $ORACLE_HOME/network/admin/tnsnames.ora  $ORACLE_HOME/network/admin/"$EXECUTE_DATE".tnsnames.ora
  fi

  # if cascade, remove dup item, and append to the old tnsnames.ora of $TMPDIR/tnsnames.ora
  if  [ $SET_CASCADE == "yes" ]; then
    sed -i '/^dup/d' $ORACLE_HOME/network/admin/tnsnames.ora
    cat $TNSNAMES >> $ORACLE_HOME/network/admin/tnsnames.ora
  else
  # otherwise just use new tnsnames.ora
    cp $TNSNAMES $ORACLE_HOME/network/admin
  fi
}

create_pri_modify_sql() {
  sed -e "s/primarydb/$DB_UNIQUE_NAME/g"  -e "s/dataguarddb/$DG_UNIQUE_NAME/g" -e "s/prilogarchivedeststate/$PRI_LOG_ARCHIVE_DEST_STATE/g" -e "s/prilogarchivedest/$PRI_LOG_ARCHIVE_DEST/g" $PRI_MODIFY_MODEL > $PRI_MODIFY_SQL

  #log_archive_config must be set before dest.cause it will check the db_unique_name to be in log_archive_config.
  if [ ${EXIST_DG_UNIQUE_NAME_LIST} != "no" ] ; then
    #remove the old line of log_archive_config
		msg_info "with existing dg_config, ${EXIST_DG_UNIQUE_NAME_LIST}"
		sed -i.bak "s/dg_config=\([^<]*\)/dg_config=\(${EXIST_DG_UNIQUE_NAME_LIST},$DG_UNIQUE_NAME,$DB_UNIQUE_NAME\)';/" $PRI_MODIFY_SQL
  fi

  #for cascade config, NO change the fal_server and fal_client.
  if [ ${SET_CASCADE} == "yes" ]; then
    sed -i.bak2 -e "/fal_server/d" -e "/fal_client/d" $PRI_MODIFY_SQL
  fi


  #主库设置name convert
  SETDBPATH="alter system set db_file_name_convert= $PRI_NAMECONVERT sid='*' scope=spfile;" 
  SETLOGPATH="alter system set log_file_name_convert= $PRI_LOGCONVERT sid='*' scope=spfile;" 
  echo $SETDBPATH >> $PRI_MODIFY_SQL
  echo $SETLOGPATH >> $PRI_MODIFY_SQL

}

#data file
export PRI_CONVERT_FILE="$TMPDIR/pri_convert.txt" 
export PRI_CONVERT_ONELINE_FILE="$TMPDIR/pri_convert_oneline.txt"
export DG_CONVERT_FILE="$TMPDIR/dg_convert.txt" 
export DG_CONVERT_ONELINE_FILE="$TMPDIR/dg_convert_oneline.txt"
#log file
export PRI_LOG_CONVERT_FILE="$TMPDIR/pri_log_convert.txt" 
export PRI_LOG_CONVERT_ONELINE_FILE="$TMPDIR/pri_log_convert_oneline.txt"
export DG_LOG_CONVERT_FILE="$TMPDIR/dg_log_convert.txt" 
export DG_LOG_CONVERT_ONELINE_FILE="$TMPDIR/dg_log_convert_oneline.txt"

makeup_file_convert "$TMPDIR/dbpath.txt" $DGPATH $PRI_CONVERT_FILE $DG_CONVERT_FILE 
makeup_file_convert "$TMPDIR/logpath.txt" $DGPATH $PRI_LOG_CONVERT_FILE  $DG_LOG_CONVERT_FILE

makeup_convert_oneline $PRI_CONVERT_FILE $PRI_CONVERT_ONELINE_FILE
makeup_convert_oneline $DG_CONVERT_FILE $DG_CONVERT_ONELINE_FILE
makeup_convert_oneline $PRI_LOG_CONVERT_FILE $PRI_LOG_CONVERT_ONELINE_FILE
makeup_convert_oneline $DG_LOG_CONVERT_FILE  $DG_LOG_CONVERT_ONELINE_FILE 

export PRI_NAMECONVERT=`cat $PRI_CONVERT_ONELINE_FILE`
export PRI_LOGCONVERT=`cat $PRI_LOG_CONVERT_ONELINE_FILE`
export DG_NAMECONVERT=`cat $DG_CONVERT_ONELINE_FILE`
export DG_LOGCONVERT=`cat $DG_LOG_CONVERT_ONELINE_FILE`
msg_info $PRI_NAMECONVERT
msg_info $PRI_LOGCONVERT
msg_info $DG_NAMECONVERT
msg_info $DG_LOGCONVERT


create_init_file
create_tnsnames_file
create_listener_file
create_dup_cmd
create_pri_add_standbylog_sql
backup_and_update_pri_tnsnames_file
create_pri_modify_sql

