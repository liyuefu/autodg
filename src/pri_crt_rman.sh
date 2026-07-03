#!/bin/bash

source ./lib/autodglib.sh
#read stage path
export STAGEPR=`./getcfg.sh stagepr`
export STAGEDG=`./getcfg.sh stagedg`
export DBID=`cat dbid.txt`
export ORACLE_DG_SID=`./getcfg.sh oracle_dg_sid`
export ORACLE_SID=`./getcfg.sh oracle_sid`
export ORACLE_HOME=`./getcfg.sh oracle_home_pr`

export INFO='\033[0;34mINFO: \033[0m'

msg_info "Now create rman backup scripts ..."

msg_info "Now create rman backup.rcv, restore.rcv"

#mkdir -p $STAGEPR
rm $STAGEPR/*
echo "connect target /" >backup.rcv
echo "run{" >>backup.rcv
echo "allocate channel ch00 device type disk;">>backup.rcv
echo "allocate channel ch01 device type disk;">>backup.rcv
echo "backup as compressed backupset format '"$STAGEPR"/full_%U' database;" >>backup.rcv
echo "backup format '"$STAGEPR"/control.ctl' current controlfile for standby;" >>backup.rcv
echo "release channel ch00;">>backup.rcv
echo "release channel ch01;">>backup.rcv
echo } >>backup.rcv


echo "connect target / ">restore.rcv
echo "run{" >>restore.rcv
echo "set dbid= "$DBID";" >>restore.rcv
echo "allocate channel ch00 device type disk;">>restore.rcv
echo "allocate channel ch01 device type disk;">>restore.rcv
echo "restore controlfile from '"$STAGEDG"/control.ctl';">>restore.rcv
echo "alter database mount;">>restore.rcv
echo "catalog start with '"$STAGEDG/"';" >>restore.rcv
echo "restore database;">>restore.rcv
echo "release channel ch00;">>restore.rcv
echo "release channel ch01;">>restore.rcv
echo "}">>restore.rcv

msg_info "Now copy tnsnames.ora ,restore.rcv, init.ora orapw to $STAGEPR" 
cp tnsnames.ora  restore.rcv  init$ORACLE_DG_SID.ora $STAGEPR
cp $ORACLE_HOME/dbs/orapw$ORACLE_SID $STAGEPR/orapw$ORACLE_DG_SID

