#!/usr/bin/env bash

#run rman duplicate to do standby
#duplicate_active = yes, 从主库直接复制,连接主库,从主库传文件到备库.
#no, 从rman备份(已经存在)duplicate主库.  不需要连接主库,rman备份需要已经复制到备库上,与主库rman备份相同的目录.

#export IPPR=`./getcfg.sh ippr`
export IPDG=`./getcfg.sh ipdg`
export ORACLE_HOME=`./getcfg.sh oracle_home_pr`
export ORACLE_HOME_DG=`./getcfg.sh oracle_home_dg`
export ORACLE_SID=`./getcfg.sh oracle_sid`
export ORACLE_DG_SID=`./getcfg.sh oracle_dg_sid`
#export STAGEPR=`./getcfg.sh stagepr`
#export STAGEDG=`./getcfg.sh stagedg`
#export DGPATH=`./getcfg.sh dgpath`
#export DGARCH=`./getcfg.sh dgarch`
export DUPLICATE_ACTIVE=`./getcfg.sh duplicate_active`
#export SETUPSSH=`./getcfg.sh setupssh`
export TODAY=`date +%Y-%m-%d_%H-%M-%S`

export SYSPWD=`./getcfg.sh syspwd`
#export DG_UNIQUE_NAME=`./getcfg.sh dg_unique_name`
export SSH_PORT=`./getcfg.sh ssh_port`


BAK_NET_CONF_FILE=$TMPDIR/back_net_conf.sh
source ./lib/autodglib.sh

backup_net_config() {
  # bakup the default tnsnames.ora, listener.ora ,delete spfile if exists on dataguard
  echo "#!/bin/bash" >$BAK_NET_CONF_FILE
  echo "if [ -f $ORACLE_HOME_DG/network/admin/tnsnames.ora ];then" >>$BAK_NET_CONF_FILE
  echo "  mv $ORACLE_HOME_DG/network/admin/tnsnames.ora $ORACLE_HOME_DG/network/admin/$TODAY.tnsnames.ora" >>$BAK_NET_CONF_FILE
  echo "fi" >>$BAK_NET_CONF_FILE
  echo "if [ -f $ORACLE_HOME_DG/network/admin/listener.ora ];then" >>$BAK_NET_CONF_FILE
  echo "  mv $ORACLE_HOME_DG/network/admin/listener.ora $ORACLE_HOME_DG/network/admin/$TODAY.listener.ora" >>$BAK_NET_CONF_FILE
  echo "fi" >>$BAK_NET_CONF_FILE
  echo "if [ -f $ORACLE_HOME_DG/dbs/spfile"$ORACLE_SID".ora ];then" >>$BAK_NET_CONF_FILE
  echo "  rm $ORACLE_HOME_DG/dbs/spfile"$ORACLE_SID".ora " >>$BAK_NET_CONF_FILE
  echo "fi" >>$BAK_NET_CONF_FILE
  chmod +x $BAK_NET_CONF_FILE
  msg_info "Create back_net_conf.sh and scp to $IPDG and run it."
  scp "$BAK_NET_CONF_FILE" "$IPDG:/home/oracle/autodg/tmp"
  ssh "$IPDG" -t "cd /home/oracle/autodg/tmp;./back_net_conf.sh;mv ./back_net_conf.sh ./back_net_conf_${TODAY}.sh"
}

copy_init_net_config() {
  msg_info "Primary copy  init.ora orapw ,tnsnames.ora, listener.ora to $IPDG" 

  scp "$TMPDIR/init$ORACLE_DG_SID.ora" "$IPDG:$ORACLE_HOME_DG/dbs/init$ORACLE_DG_SID.ora"
  scp "$ORACLE_HOME/dbs/orapw$ORACLE_SID" "$IPDG:$ORACLE_HOME_DG/dbs/orapw$ORACLE_DG_SID"
  #把连接符文件,侦听文件复制到备库
  scp "$TMPDIR/tnsnames.ora" "$IPDG:$ORACLE_HOME_DG/network/admin/tnsnames.ora"
  scp "$TMPDIR/listener.ora" "$IPDG:$ORACLE_HOME_DG/network/admin/listener.ora"
  scp "$TMPDIR/dg_crt_standbylog.sql" "$IPDG:/home/oracle/autodg/src"
}
startup_nomount_dg() {
  #startup database nomount
  msg_info  "Standby startup database nomount"
  #备库启动到nomount
  ssh "oracle@$IPDG" -t "cd /home/oracle/autodg/src;./dg_nomount.sh" >/dev/null 2>&1

}

run_duplicate() {
  #用duplicate命令搭建dg库
  if [ "$DUPLICATE_ACTIVE" = "yes" ]; then
  #从主库直接复制.需要连接主库.会耗用主库的资源,包括IO,网络.
    msg_info "Primary start rman duplicate from activate database, tailf dup.log for details"
    "$ORACLE_HOME/bin/rman" target  sys/"$SYSPWD" auxiliary sys/"$SYSPWD"@dup cmdfile="$TMPDIR/dup.cmd" log="$TMPDIR/dup.log"
  else
  #从主库已经做好的rman备份做duplicate. 不连接主库,不消耗主库的任何资源.需要在备库已经有rman备份,而且目录和主库相同.
    msg_info "Primary start rman duplicate from rman backup, tailf dup.log for details"
    "$ORACLE_HOME/bin/rman" auxiliary sys/"$SYSPWD"@dup cmdfile="$TMPDIR/dup.cmd" log="$TMPDIR/dup.log"
  fi

  if [ $? -ne 0 ]
  then
    msg_error "Primary duplicate failed ."
    exit -1;
  else
    msg_info "Primary duplicate finish."
    exit 0;
  fi
}

backup_net_config
copy_init_net_config
startup_nomount_dg
run_duplicate
