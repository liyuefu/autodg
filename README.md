# 配置文件模板
## 搭建单实例-单实例 para.cfg.single.
## 搭建级联，在主库运行autodg，para.cfg.2nd
## 搭建级联， 在第一个dg库运行autodg,主库不动， para.cfg.cascade
## rac到单机， para.cfg.rac

# What's it for

It's for deploy Oracle dataguard with scripts.
just edit the config file para.cfg according to your env, the script will deply dataguard .

# How to use it 

## clone it 
git clone https://github.com/liyuefu/autodg.git
## edit para.cfg
cd src  
vi para.cfg  
### single instance to single instance
oracle_sid=ctp  
oracle_dg_sid=ctpdg  
#如果已经有配置了dg,比如配置了2个dg,把db_unique_name写这里,没有就保持no  
#exist_dg_unique_name_list=testdg1,testdg2  
exist_dg_unique_name_list=no  
#指定主库使用哪个dest  
pri_log_archive_dest=3  
#指定备库使用哪个dest  
dg_log_archive_dest=3  
dg_unique_name=ctpdg  
oracle_base_pr=/u01/app/oracle  
oracle_home_pr=/u01/app/oracle/product/11.2.0/dbhome_1  
oracle_base_dg=/u01/app/oracle  
oracle_home_dg=/u01/app/oracle/product/11.2.0/dbhome_1  
dgpath=/u02/oradata/ctpdg  
dgarch=/u02/arch  
#从rac到单机时,rac使用搭建使用节点的public ip.  
ippr=192.168.56.91  
ipdg=192.168.56.92  
stagepr=/stage  
stagedg=/stage  
duplicate_active=yes  
fix_datafile_same_name=no  
rman_backup_dir=/u02/rmanbackup  
syspwd=oracle  
setupssh=no  
#fix_datafile_same_name=yes, 用%U统一命名./u03/oradata/ctp/data_D-CTP_TS-SYSTEM_FNO-1; no: 用原来的名字  
#如果文件有重名的,设置为yes  
#duplicate_active: yes(直接用duplicate from active命令从主库duplicate), no(用现有的rman备份也用duplicate命令, rman必须已经复制到备库),  

### rac -> rac  

oracle_sid=ctp1  
oracle_dg_sid=ctp1  
#如果已经有配置了dg,比如配置了2个dg,把db_unique_name写这里,没有就保持no  
exist_dg_unique_name_list=ctpdg  
#exist_dg_unique_name_list=no  

#指定主库使用哪个dest  
pri_log_archive_dest=2  
#指定备库使用哪个dest  
dg_log_archive_dest=2  
dg_unique_name=ctpdgrac  
oracle_base_pr=/u01/app/oracle  
oracle_home_pr=/u01/app/oracle/product/11.2.0/dbhome_1  
oracle_base_dg=/u01/app/oracle  
oracle_home_dg=/u01/app/oracle/product/11.2.0/dbhome_1  
dgpath=+datadg  
dgarch=+datadg  
#源端和目标端都是rac时,搭建时使用vip ip. 绝对不要用scan ip,Doc ID 563801.1
ippr=192.168.56.191  
ipdg=192.168.56.201  
stagepr=/stage  
stagedg=/stage  
duplicate_active=yes  
fix_datafile_same_name=no  
rman_backup_dir=/u02/rmanbackup  
syspwd=oracle  
setupssh=no  
#fix_datafile_same_name=yes, 用%U统一命名./u03/oradata/ctp/data_D-CTP_TS-SYSTEM_FNO-1; no: 用原来的名字  
#如果文件有重名的,设置为yes  
#duplicate_active: yes(直接用duplicate from active命令从主库duplicate), no(用现有的rman备份也用duplicate命令, rman必须已经复制到备库),  
#rman(新建一个rman备份并复制到备库,用rman restore, recover命令)  

## run it
./autodg.sh

### check the log/process
cd ../tmp  
tailf dup.log  

# update
2024.09.17 support 1->2 (1->1(para.cfg.1st)->1(para.cfg.2nd)), support cascade 1->dg1(para.cfg.1st) -> dg2 (para.cfg.cascade,run on dg1)

# update 
2024.09.20 , support 19c. 19c cascade must manually  rename all redo /standby redo file and clear them. ref: Doc ID 2756315.1,Doc ID 2756315.1
alter database rename file '<ORACLE_HOME>/dbs/broken0' to '<PATH1>/<ORACLE_SID>/redo1/redo01.log';
alter database clear logfile group <REDO LOG group  number>;

# update 
2024.09.22. when cascade, the direct dg tnsnames.ora file will be appended instead of overwrite with new tnsnames.ora
# update
2024.09.25 for cascade , add a sql file to rename and clean the logfile.
# update 
2024.09.29 for cascade, when setup, no change the fal_client and fal_server of direct-standby.

# update 
2025.04.07. 细化了文档

# update
2025.05.08 fix了有的para.cfg 没有设置set_cascade=no这个参数，导致主库设置valid_for时值为standby, 不能实时同步。

# update

2025.07.19 getcfg.sh读取变量后，没有去掉前后的空格这个bug.比如ip地址有空格，导致后面scp失败。已经fix.

# update
2025.09.17. rmarch.sh ,delete去掉force选项。否则没有apply的也强制删除。
# update
2025.09.26, 配置tnsnanes.ora 的连接符时，对于RAC,主库和备库不要用SCAN IP. 改为VIP. Doc ID 563801.1,否则主库报错ORA-12514 
#update: 
2026.02.07. 文件pri_crt_init_tns.sh ,创建dup.cmd,当不使用OMF时，设置db_create_file_dest为空字符串''. 否则从RAC 搭建时缺省是'+data',而dg建数据>文件有限使用db_create_file_dest这个参数，而不是convert参数。导致建文件失败。
export TMPDIR="$TMPDIR"

# update
2026.03.28. 可以设置ssh的端口。默认22.
2026.05.30. 修改脚本，加入SSH_PORT. 增加脚本setupssh.sh, 可以简单设置互信。 当主备库不使用缺省22端口时，只能用这个setupssh.sh,分别在主库和dg库用oracle执行，执行时手动输入密码。

# update
2026.07.04. improve shell robustness and tests:
- src/lib/autodglib.sh now resolves its own source path correctly when loaded by Bats or other scripts, quotes file paths, and returns the bad para.cfg line when a path ends with `/`.
- src/autodg.sh, src/pri_duplicate.sh, src/dg_main.sh, and src/dg_open.sh quote important variables and avoid duplicate ssh/scp port flags because the shared ssh/scp wrappers already apply SSH_PORT.
- src/autodg.sh fixes the rman stage-directory condition so `duplicate_active=rman` is compared correctly instead of being treated like an assignment.
- src/dg_main.sh fixes `mkdir -P` to `mkdir -p` and makes ASM path detection safer.
- Bats tests now create their own fixtures and pass from the repository root.
