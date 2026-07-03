#!/bin/bash
#check rac 2 instance and dataguard sync status.
#deploy: crontab check every 3 minutes,warningnum=5 ,if dg lag more than 5 logs, warning is written in monitor.log
#*/3 * * * * /home/oracle/autodg/dgmonitor/dgmonitor.sh 192.168.56.5 >/dev/null 2>&1
# rundgcheck="n" ,change to y , to do dgcheck every time.
#check: /home/oracle/autodg/dgmonitor/monitor.log
#update: 2022.04.21


MONITOR_HOME=/home/oracle/autodg/src/dgmonitor
SSH_PORT=`cd $MONITOR_HOME/..;./getcfg.sh ssh_port`
ssh() { /usr/bin/ssh -o StrictHostKeyChecking=no -p $SSH_PORT "$@"; }
scp() { /usr/bin/scp -o StrictHostKeyChecking=no -P $SSH_PORT "$@"; }

if [ -z $1 ];then
	echo "USAGE:DG_hostname OR DG_IP"
	exit 0
fi

cat > checknoarch.sh <<EOF
#!/bin/sh
source /home/oracle/.bash_profile
sqlplus -s / as sysdba @checknoarch.sql
EOF
cat > checknoapplied.sh <<EOF
#!/bin/sh
source /home/oracle/.bash_profile
sqlplus -s / as sysdba @checknoapplied.sql
EOF

cat > check_max_applied.sh <<EOF
#!/bin/sh
source /home/oracle/.bash_profile
sqlplus -s / as sysdba @check_max_applied.sql
EOF

chmod +x checknoarch.sh
chmod +x checknoapplied.sh
chmod +x check_max_applied.sh

#chmod +x $MONITOR_HOME/../dgcheck/*.sh
chmod +x *.sh

primary=`hostname`
standby=$1
warningnum=5;

rundgcheck="n"

v_datetime="$MONITOR_HOME/$standby"_`date +"%Y-%m-%d"`_check_noapplied.log
monitorlog="$MONITOR_HOME/monitor.log"
touch $v_datetime

ssh oracle@$standby -t "if [ ! -d $MONITOR_HOME ]; then mkdir $MONITOR_HOME; fi"
scp $MONITOR_HOME/checknoapplied.s* oracle@$standby:$MONITOR_HOME
scp $MONITOR_HOME/checknoarch.s* oracle@$standby:$MONITOR_HOME
scp $MONITOR_HOME/check_max_applied.s* oracle@$standby:$MONITOR_HOME
ssh oracle@$standby -t "cd $MONITOR_HOME;./checknoapplied.sh;./checknoarch.sh;./check_max_applied.sh"

#get primary thread1,thread2 max sequence# archived log
$MONITOR_HOME/checknoarch.sh
mv checknoarch1.txt  "$primary"_arch1.txt
mv checknoarch2.txt  "$primary"_arch2.txt
#get max applied sequence 
#$MONITOR_HOME/check_max_applied.sh
#mv check_max_applied1.txt "$primary"_max_applied1.txt
#mv check_max_applied2.txt "$primary"_max_applied2.txt

scp $standby:$MONITOR_HOME/checknoapplied.txt $MONITOR_HOME/"$standby"_apply.txt
scp $standby:$MONITOR_HOME/checkapplystatus.txt $MONITOR_HOME/"$standby"_apply_status.txt
scp $standby:$MONITOR_HOME/checknoarch1.txt $MONITOR_HOME/"$standby"_arch1.txt
scp $standby:$MONITOR_HOME/checknoarch2.txt $MONITOR_HOME/"$standby"_arch2.txt
scp $standby:$MONITOR_HOME/check_max_applied1.txt $MONITOR_HOME/"$standby"_max_applied1.txt
scp $standby:$MONITOR_HOME/check_max_applied2.txt $MONITOR_HOME/"$standby"_max_applied2.txt
log=""


#check if oracle not startup.
if [ -f $MONITOR_HOME/"$standby"_apply.txt ] && (grep "ORACLE not available" $MONITOR_HOME/"$standby"_apply.txt);then
  log="!!!Please check if $standby is reachable and  database is running!!! ."
  echo `date ` $log>>$v_datetime
  echo `date +"%Y-%m-%d %H:%M:%S"`  $standby $log>>$monitorlog
  rm -rf $MONITOR_HOME/"$standby"_apply.txt
  exit
fi
#check if apply with readonly
if [ -f $MONITOR_HOME/"$standby"_apply_status.txt ] && (! grep "READ ONLY WITH APPLY" $MONITOR_HOME/"$standby"_apply_status.txt);then
  log="!!!Please check if $standby is in read only with apply status!! ."
  echo `date ` $log>>$v_datetime
  echo `date +"%Y-%m-%d %H:%M:%S"`  $standby $log>>$monitorlog
  rm -rf $MONITOR_HOME/"$standby"_apply_status.txt
  exit
fi

#check max applied sequence of each thread. if they match, then it's OK.
dg_max_applied1=`cat $MONITOR_HOME/"$standby"_max_applied1.txt | sed '/^[  ]*$/d'`
dg_max_applied2=`cat $MONITOR_HOME/"$standby"_max_applied2.txt | sed '/^[  ]*$/d'`
pri_max_arch1=`cat $MONITOR_HOME/"$primary"_arch1.txt | sed '/^[  ]*$/d'`
pri_max_arch2=`cat $MONITOR_HOME/"$primary"_arch2.txt | sed '/^[  ]*$/d'`
max_dg1=$((dg_max_applied1))
max_dg2=$((dg_max_applied2))
max_pri1=$((pri_max_arch1))
max_pri2=$((pri_max_arch2))
echo $max_dg1
echo $max_dg2
echo $max_pri1
echo $max_pri2

if [ $max_dg1 -ge  $max_pri1 ] && [ $max_dg2 -ge $max_pri2 ];then
  log="OK"
  echo `date ` $log>>$v_datetime
  echo `date +"%Y-%m-%d %H:%M:%S"`  $standby $log>>$monitorlog
  echo `date +"%Y-%m-%d %H:%M:%S"`  $standby $log>>$v_datetime
  rm $MONITOR_HOME/"$standby"_apply.txt
  exit;
fi
  
##check no transfer arch log
dg_arch1=`cat $MONITOR_HOME/"$standby"_arch1.txt | sed '/^[  ]*$/d'`
dg_arch2=`cat $MONITOR_HOME/"$standby"_arch2.txt | sed '/^[  ]*$/d'`
pri_arch1=`cat $MONITOR_HOME/"$primary"_arch1.txt | sed '/^[  ]*$/d'`
pri_arch2=`cat $MONITOR_HOME/"$primary"_arch2.txt | sed '/^[  ]*$/d'`
i=$((pri_arch1))
j=$((dg_arch1))
let thread1_arch_gap=i-j
i=$((pri_arch2))
j=$((dg_arch2))
let thread2_arch_gap=i-j
log="OK"
if [ "$thread1_arch_gap" -gt  $warningnum ]; then
echo $thread1_arch_gap
echo $warningnum
  log="NOT TRANSFERED LOGS thread1:$thread1_arch_gap ,is more than $warningnum, please check dg1.out,dg2.out."
  echo `date +"%Y-%m-%d %H:%M:%S"`  $standby $log>>$v_datetime
  echo `date +"%Y-%m-%d %H:%M:%S"`  $standby $log>>$monitorlog
  rundgcheck='y'
fi

if [ "$thread2_arch_gap" -gt  $warningnum ]; then
  log="NOT TRANSFERED LOGS thread2:$thread2_arch_gap,is more than $warningnum, please check dg1.out,dg2.out."
  echo `date +"%Y-%m-%d %H:%M:%S"`  $standby $log>>$v_datetime
  echo `date +"%Y-%m-%d %H:%M:%S"`  $standby $log>>$monitorlog
  rundgcheck='y'
fi

##check no applied
if [ -f $MONITOR_HOME/"$standby"_apply.txt ];then 
  str=`cat $MONITOR_HOME/"$standby"_apply.txt | sed '/^[  ]*$/d'`
else
  str=0
fi
if  [ "$str" -ge 0 ] 2>/dev/null;then
# is number
  noapplied=$(($str))
  echo $noapplied
  if [  $noapplied -gt $warningnum ];then
    rundgcheck='y'
    log="NOT APPLIED LOGS :$noapplied, is more than $warningnum, please run dgcheck.sh and check pri.out, dg.out." 
    echo `date +"%Y-%m-%d %H:%M:%S"`  $standby $log>>$v_datetime
    echo `date +"%Y-%m-%d %H:%M:%S"`  $standby $log>>$monitorlog
  fi
else
  rundgcheck='y'
  log="!!!Please check if $standby is reachable and  database is running!!! ."
  echo `date ` $log>>$v_datetime
  echo `date +"%Y-%m-%d %H:%M:%S"`  $standby $log>>$monitorlog
  echo `date +"%Y-%m-%d %H:%M:%S"`  $standby $log>>$v_datetime
fi


touch $monitorlog
echo `date +"%Y-%m-%d %H:%M:%S"`  $standby $log>>$v_datetime
echo `date +"%Y-%m-%d %H:%M:%S"`  $standby $log>>$monitorlog
echo $rundgcheck
if [ $rundgcheck == 'y' ];then
  echo "now run dgcheck.sh ######"
  #$MONITOR_HOME/../dgcheck/dgcheck.sh $standby
  $MONITOR_HOME/dgcheck.sh $standby
fi
rm -rf $MONITOR_HOME/"$standby"_apply.txt
