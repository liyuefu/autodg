#!/bin/sh
#delete arch log on dg
#rman delete sysdate-1
#find delete ctime + 7
#update: 2023.07.18
#update: 2025.09.17. 去掉force,否则没有apply的也强制删除。

source ~/.bash_profile

#export ORACLE_HOME=/u01/app/oracle/product/11.2.0.4
#export ORACLE_SID=orcl
export ARCHDIR=/u02/arch


export DATE=`date +%Y-%m-%d`
export LOGFILE=$ARCHDIR/logs/rm_arch_`date +%Y-%m-%d-%H%M`.log
export CMDFILE=/tmp/fullbak.rcv
if [ ! -d $ARCHDIR/logs ]; then
    mkdir -p $ARCHDIR/logs
fi
cat > $CMDFILE <<EOF
connect target /
run{
CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON STANDBY;

allocate channel ch00 device type disk;
allocate channel ch01 device type disk;
allocate channel ch02 device type disk;
allocate channel ch03 device type disk;


crosscheck archivelog all;
delete noprompt  archivelog all completed before 'sysdate-1' ;
release channel ch00;
release channel ch01;
release channel ch02;
release channel ch03;
}
EOF

########################################################################

echo "started  at : "`date +%Y%m%d-%H%M` >> $LOGFILE
echo "---------------------------------------------------">>$LOGFILE
$ORACLE_HOME/bin/rman  @$CMDFILE log $LOGFILE append
echo "---------------------------------------------------">>$LOGFILE
echo "finished  at: "`date +%Y%m%d-%H%M` >> $LOGFILE

find $ARCHDIR  -ctime +7  | xargs rm -f



