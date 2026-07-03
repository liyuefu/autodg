###################################################
#update: 2021.11.18. logsize get from primary db. not 100M.
#update: 2022.08.21.  fix bug . pri_convert_logpathnew not cleaned before start.
#update: 2022.11.02. change duplicate_active.  yes: from active , no: from rman backup.
#update: 2024.04.24 pri and dg can assign the dest number.
#update: 2024.05.11 rewrite with function. add bats test system.
#update: 2026.05.31. support ssh_port
#####################################################
#!/bin/bash

source ./lib/autodglib.sh
export IPPR=$(./getcfg.sh ippr)
export IPDG=$(./getcfg.sh ipdg)
export ORACLE_HOME=$(./getcfg.sh oracle_home_pr)
export ORACLE_BASE=$(./getcfg.sh oracle_base_pr)
export ORACLE_BASE_DG=$(./getcfg.sh oracle_base_dg)
export ORACLE_SID=$(./getcfg.sh oracle_sid)
export ORACLE_DG_SID=$(./getcfg.sh oracle_dg_sid)
export DG_UNIQUE_NAME=$(./getcfg.sh dg_unique_name)

export DG_LOG_ARCHIVE_DEST="log_archive_dest_$(./getcfg.sh dg_log_archive_dest)" #备库向主库传归档日志
export PRI_LOG_ARCHIVE_DEST="log_archive_dest_$(./getcfg.sh pri_log_archive_dest)" #主库向备库传归档日志
export PRI_LOG_ARCHIVE_DEST_STATE="log_archive_dest_state_$(./getcfg.sh pri_log_archive_dest)"

export STAGEPR=$(./getcfg.sh stagepr)
export STAGEDG=$(./getcfg.sh stagedg)
export DGPATH=$(./getcfg.sh dgpath)
export DGARCH=$(./getcfg.sh dgarch)
export LOG_FILE="./autodg.log"
export DUPLICATE_ACTIVE=$(./getcfg.sh duplicate_active)
export SETUPSSH=$(./getcfg.sh setupssh)
export INFO='\033[0;34mINFO: \033[0m'
export SSH_PORT=$(./getcfg.sh ssh_port)


set -eo pipefail

./clean.sh

check_logsize_same() {
  export DB_NAME=$(cat "$TMPDIR/dbname.txt")
  #check if logfile same size
  LOGSIZE_CNT=$(wc -l < "$TMPDIR/logsize.txt")
  LOGSIZE_M=$(awk '{ print $1 }' "$TMPDIR/logsize.txt")

  if  [ "$LOGSIZE_CNT" = "1" ]; then
    LOGSIZE_M=$(sed -e 's/[ ]*//g' "$TMPDIR/logsize.txt")
  else
    msg_error "Primary ERROR !!!! There are more than 1 size of logfile. please check with sql: 'select group#,bytes from v\$log'"
    exit 1;
  fi
}
 
check_parafile_path_format() {
  #check  if path ends with /.  
  result=$(check_path_ends_with_slash "./para.cfg")
  if [ -z "$result" ]; then
  #  log_ok "para.cfg is ok"
    msg_ok "para.cfg is ok"
  else
    msg_error "check para.cfg this line: $result"
    exit 1;
  fi
}

check_pri_path() {
#check oracle_home
  if [ ! -d "$ORACLE_HOME" ];then
    msg_error "Primary ERROR !!!! $IPPR: $ORACLE_HOME DOES NOT exist,please check it."
    exit 1
  fi

  #check if path exists
  if [ ! -d "$STAGEPR" ] && [ "$DUPLICATE_ACTIVE" = "rman" ];then #如果用rman临时备份搭建,而不用duplicate,需要检查stage目录是否存在
    msg_error "Primary ERROR !!!! $IPPR: $STAGEPR DOES NOT exist,please create it."
    exit 1
  fi
}

create_rman_autobackup_path() {
#如果用rman duplicate, 则rman定义的自动备份控制文件目录必须存在.
#在RAC下,如果在节点2做rman备份到/u02/rman. 节点1没有这个目录. 在节点1执行autodg时没有这个目录而失败.
#所以先检查并建立这个目录
  autobackup_path=$(echo "show all;exit;" | rman target /  | grep "AUTOBACKUP FORMAT" | awk -F\' '{print $2}')
  autobackup_path2=$(dirname "$autobackup_path")
  if [ ! -d "$autobackup_path2" ]; then
    mkdir "$autobackup_path2"
  fi
}

check_setup_ssh() {
  if [ "$SETUPSSH" = "yes" ]; then
    msg_info "setup SSH between primay and standby host..."
    msg_info "Please input password when prompt..."
    ./sshUserSetup.sh -user oracle  -hosts "$IPPR $IPDG" -advanced -noPromptPassphrase
  fi
}

copy_src_tmp_to_dg() {
  #create /home/oracle/autodg/src,tmp on standby host 
  SHFILE="$TMPDIR/dg_create_dir.sh"
  echo "#!/bin/bash" > "$SHFILE"
  echo "if [ ! -d /home/oracle/autodg/src ];then" >> "$SHFILE"
  echo "mkdir -p  /home/oracle/autodg/src" >> "$SHFILE"
  echo "fi " >> "$SHFILE"
  echo "if [ ! -d /home/oracle/autodg/tmp ];then" >> "$SHFILE"
  echo "mkdir -p  /home/oracle/autodg/tmp" >> "$SHFILE"
  echo "fi " >> "$SHFILE"
  chmod +x "$SHFILE"
  scp "$SHFILE" "$IPDG:/home/oracle/dg_create_dir.sh"
  ssh "$IPDG" -t "cd /home/oracle;./dg_create_dir.sh;rm ./dg_create_dir.sh"
  #rm SHFILE

  #copy autodg directory to standby
  scp -r ./* "$IPDG:/home/oracle/autodg/src" > "$TMPDIR/scp.log"
  scp -r ../tmp/* "$IPDG:/home/oracle/autodg/tmp" > "$TMPDIR/scp.log"
}

check_dg_restore_recovery_directory() {
#check standby directories for recovery
if [ -f "$TMPDIR/autodg_dg.log" ];then
  rm autodg_dg.log
fi

msg_info "Standby create  directory "
ssh "oracle@$IPDG" -t "cd /home/oracle/autodg/src;./dg_main.sh"

if [ -f "$TMPDIR/autodg_dg.log" ];then
  #error on standby host. exit.
  cat $TMPDIR/autodg_dg.log
  exit 1
fi

}

pri_add_sby_log_set_force_logging() {
#add standby logfile
msg_info "Primary add standby logfile"
"$ORACLE_HOME/bin/sqlplus" -s / as sysdba @"$TMPDIR/pri_crt_standbylog.sql"  >/dev/null 2>&1
msg_info "Primary set force logging"
"$ORACLE_HOME/bin/sqlplus" -s / as sysdba <<EOF >/dev/null 2>&1
alter database force logging;
exit;
EOF
}

run_duplicate_cmd() {
if [ "$DUPLICATE_ACTIVE" != "rman" ]; then
#duplicate target for standby.yes:从active 数据库直接duplicate. 需要连接主库 no:从已经存在的rman备份duplicate 备库,不需要连接主库.
  ./pri_duplicate.sh

  if [ $? -ne 0 ]
  then
    tail -50 dup.log
    msg_error "duplicate failed."
    exit 1;
  fi
#elif [ $DUPLICATE_ACTIVE == "rman" ]; then
else
#create rman scripts,create rman backup, scp, restore to make standby
  ./pri_crt_rman.sh

  msg_info "primary  backup database with rman"
  "$ORACLE_HOME/bin/rman"  @backup.rcv
  msg_info "primary rman backup done."
  
  msg_info "primary  rcp  backup to standby "
  scp "$STAGEPR"/* "$IPDG:$STAGEDG" >> "$TMPDIR/scp.log"
  
  msg_info "prepare configuration file for restore."
  ssh "oracle@$IPDG" -t "cd /home/oracle/autodg/src;./dg_main.sh"
  
  msg_info "standby  start recovery"
  ssh "oracle@$IPDG" -t "cd /home/oracle/autodg/src;./dg_restore_recover.sh"
fi
}

check_parafile_path_format
#get database basic information
./pri_getdbinfo.sh
#check db is runing
if grep "ORACLE" "$TMPDIR/dbname.txt"; then
  msg_error "Primary ERROR !!!! Oracle is not started,start oracle_sid or start oracle first"
  exit 1
fi

check_pri_path
create_rman_autobackup_path
check_logsize_same
check_setup_ssh
copy_src_tmp_to_dg
check_dg_restore_recovery_directory

msg_info "Primary create init.ora, tnsnames.ora,  standby_log_create script..."
./pri_crt_init_tns.sh >/dev/null 2>&1
pri_add_sby_log_set_force_logging

run_duplicate_cmd

msg_info "Standby open database in read only mode"
ssh "oracle@$IPDG" -t "cd /home/oracle/autodg/src;./dg_open.sh"

msg_info "Primary enable transfer log  to standby"
./pri_enable_arch.sh

# msg_info "Primary check max sequence#"
# $ORACLE_HOME/bin/sqlplus -s / as sysdba  <<EOF
# set heading off
# alter system archive log current;
# alter system set ${PRI_LOG_ARCHIVE_DEST_STATE}='enable';
# select thread#,max(sequence#) as "PRIMARY Max Sequence" from v\$archived_log group by thread#;
# exit
# EOF

sleep 5
#if dest is RAC, create script to add database,instance to cluster

scp "oracle@$IPDG:$ORACLE_BASE/diag/rdbms/$DG_UNIQUE_NAME/$ORACLE_DG_SID/trace/alert*.log" "./alert_${ORACLE_DG_SID}.log"
msg_info "========================last 10 line of dataguard alert.log====================="
tail -n 10 "./alert_${ORACLE_DG_SID}.log"
