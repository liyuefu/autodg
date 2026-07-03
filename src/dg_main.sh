#!/bin/bash
source ./lib/autodglib.sh
export IPPR=`./getcfg.sh ippr`
export IPDG=`./getcfg.sh ipdg`
export STAGEDG=`./getcfg.sh stagedg`
export DGPATH=`./getcfg.sh dgpath`
export DGARCH=`./getcfg.sh dgarch`
export ORACLE_BASE=`./getcfg.sh oracle_base_dg`
export ORACLE_HOME=`./getcfg.sh oracle_home_dg`
export DG_UNIQUE_NAME=`./getcfg.sh dg_unique_name`
export DB_NAME=`cat $TMPDIR/dbname.txt`
export AUDITDG=$ORACLE_BASE/admin/$DB_NAME/adump
export ORACLE_DG_SID=`./getcfg.sh oracle_dg_sid`
export LOG_FILE="/home/oracle/autodg/tmp/autodg_dg.log"
export DUPLICATE_ACTIVE=`./getcfg.sh duplicate_active`
export RMAN_BACKUP_DIR=`./getcfg.sh rman_backup_dir`
export SSH_PORT=`./getcfg.sh ssh_port`


#log file put into tmp directory.
SCP_LOGFILE="scp $LOG_FILE $IPPR:/home/oracle/autodg/tmp"


if [ -f "$LOG_FILE" ];then
  rm  "$LOG_FILE"
fi

#如果使用临时做rman备份,用rman备份做dg,需要检查备机有没有stage目录
if [ ! -d "$STAGEDG" ] && [ "$DUPLICATE_ACTIVE" = "rman" ] ;then
  msg_error "Standby  ERROR !!!!! $IPDG:$STAGEDG DOES NOT exist,please create it." 
  exit;
fi

if [ ! -d /home/oracle/autodg/src ];then
    mkdir -p /home/oracle/autodg/src
fi
#检查备机有没有创建指定的数据文件目录
if echo "${DGPATH}" | grep -q '^+'
#是磁盘组
then
  msg_info "dg datafile Using diskgroup: ${DGPATH}"
else
  if [ ! -d "$DGPATH" ]; then
    msg_error "Standby ERROR !!!!! $IPDG:$DGPATH DGPATH DOES NOT exist,please create it." 
    if [ -f "$LOG_FILE" ];then
      $SCP_LOGFILE
#      scp  -p $SSH_PORT $LOG_FILE $IPPR:/home/oracle/autodg/src
    fi
    exit;
  fi
fi

#检查备机有没有创建指定的归档目录
if echo "${DGARCH}" | grep -q '^+'
then
#存放在磁盘组
  msg_info "dg arch Using diskgroup: ${DGARCH}"
else
#检查目录是否存在
  if [ ! -d "$DGARCH" ]; then
    msg_error "Standby ERROR !!!!! $IPDG:$DGARCH DGARCH DOES NOT exist,please create it." 
    if [ -f "$LOG_FILE" ];then
      $SCP_LOGFILE
#      scp $LOG_FILE $IPPR:/home/oracle/autodg/src
    fi
    exit
  fi
fi

#用已经存在的rman备份进行duplicate 复制备库. 这个备份需要手动提前复制到备库.
#检查备库是否已经有这个备份,通过目录占用空间大小判断是否已经复制过来.
if [ "$DUPLICATE_ACTIVE" = 'no' ]; then
  if [ ! -d "$RMAN_BACKUP_DIR" ]; then
    msg_error "Standby ERROR !!!!! $IPDG:$RMAN_BACKUP_DIR rman backup dir  DOES NOT exist,please create it and copy the rman backup files to it." 
    if [ -f "$LOG_FILE" ];then
      $SCP_LOGFILE
#      scp $LOG_FILE $IPPR:/home/oracle/autodg/src
    fi
    exit
  else
    y=$(du -s "$RMAN_BACKUP_DIR" | awk '{print $1}')
    if [ "$y" -lt 100 ]; then
      msg_error "Standby ERROR !!!!! $IPDG:$RMAN_BACKUP_DIR rman backup files  too small,please copy the backup from primary to $RMAN_BACKUP_DIR." 
      if [ -f "$LOG_FILE" ];then
        $SCP_LOGFILE
#        scp $LOG_FILE $IPPR:/home/oracle/autodg/src
      fi
      exit
    fi
  fi
fi

msg_info "Standby delete spfile if it exists..."
#delete spfile if it exists
if [ -f "$ORACLE_HOME/dbs/spfile$ORACLE_DG_SID.ora" ];then
  rm "$ORACLE_HOME/dbs/spfile$ORACLE_DG_SID.ora"
fi

msg_info "Standby create adump directory...  "
mkdir -p "$AUDITDG"

#if [ ! -d $ORACLE_BASE/admin/$ORACLE_DG_SID/adump ]; then
#    mkdir -p $ORACLE_BASE/admin/$ORACLE_DG_SID/adump
#fi
