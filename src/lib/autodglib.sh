#!/usr/bin/env bash

declare -r DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$DIR/lib/bsfl.sh"
source "$DIR/lib/ext_bsfl.sh"


declare -x LOG_ENABLED="yes"
declare -x DEBUG="yes"
declare -x TMPDIR="$DIR/../tmp"
declare -r TRUE=0
declare -r FALSE=1

cd "$DIR"
export SSH_PORT=$(./getcfg.sh ssh_port)
cd - > /dev/null

ssh() {
    /usr/bin/ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "$@"
}

scp() {
    /usr/bin/scp -o StrictHostKeyChecking=no -P "$SSH_PORT" "$@"
}

#mkdir for temporary files used by autodg.
if [ ! -d "$TMPDIR" ]; then
  mkdir "$TMPDIR"
fi

####if not ends with / , output == ""
#### else  output != ""
check_path_ends_with_slash() {
  local parafile=$1

  #use sed to check if line end with / . / must be removed.
  slashline=$(sed -n '/\/$/p' "$parafile")
  echo "$slashline"
}

#### input a tmp file name $1, remove empty line and space, output text to a new text file $2.
get_one_row_data() {
  local tmpfile=$1
  local newfile=$2
  if file_exists_and_not_empty "$tmpfile"; then
    grep -v ^$ "$tmpfile" |awk '{print $(NF)}' > "$newfile"
#    cat $newfile
  else
    echo ""
  fi
}

#### from all the datafile, get the data path ,unique them and save to newfile.
#### there maybe multiple rows
get_multiple_row_data() {
  local tmpfile=$1
  local newfile=$2
  if file_exists_and_not_empty "$tmpfile"; then
    sed 's/\(.*\)\/.*/\1/' "$tmpfile" | sed '/^$/d' |sort -r|uniq > "$newfile"
    #取最后一个\前的所有字符, 最后一个\后的字符舍弃.然后去掉空行, 排序, 去重, 保存到newfile.
#    cat $newfile
  else
    echo ""
  fi
}

#### get diskgroup name from diskgroup filename. such as +data/asp/datafile/system01.dbf. return +data
get_diskgroup_name() {
  local tmpfile=$1
  local newfile=$2
  awk -F'/' '{print $1}' "$tmpfile" | sort -r| uniq |grep -v ^$ > "$newfile"
#  cat $newfile
}
#convert information from dbinfo to formatted txt file.
#
format_dbinfo(){
  get_one_row_data  $TMPDIR/dbname.tmp $TMPDIR/dbname.txt
  get_one_row_data  $TMPDIR/db_unique_name.tmp $TMPDIR/db_unique_name.txt
  get_one_row_data  $TMPDIR/cluster.tmp $TMPDIR/cluster.txt
  get_one_row_data  $TMPDIR/cluster_database_instances.tmp $TMPDIR/cluster_database_instances.txt
  get_one_row_data  $TMPDIR/domain.tmp $TMPDIR/domain.txt
  get_one_row_data  $TMPDIR/dbid.tmp $TMPDIR/dbid.txt
  get_one_row_data  $TMPDIR/version.tmp $TMPDIR/version.txt
  get_one_row_data  $TMPDIR/logsize.tmp $TMPDIR/logsize.txt
  get_multiple_row_data $TMPDIR/dbpath.tmp $TMPDIR/dbpath.txt
  get_multiple_row_data $TMPDIR/logpath.tmp $TMPDIR/logpath.txt
  cp $TMPDIR/logpath.txt $TMPDIR/addlogpath.txt

}

## can be used to : from primary datafile, makeup datafile convert string for primary and standby.
## can also be used to logfile 
#$1  pri_filename,contains all datafile/tempfile(/u02/oradata/orcl/system01.dbf).such as dbpath.tmp
#$2  string. dataguard datafile path, such as  '/u03/ordata/orcldg'
#$3  filename, contains primary's convert  string. '/u03/oradata/orcldg','/u02/oradata/orcl'
#$4  filename, contains dataguard's convert string. '/u02/oradata/orcl','/u03/orddata/orcldg'
makeup_file_convert() {
  local pri_filename=$1
  local dg_filepath=$2
  local pri_convert_path_file=$3
  local dg_convert_path_file=$4

  file_exists_and_not_empty "$pri_filename"  || return $FALSE
#  cmd file_exists $pri_filename
  
  >"$pri_convert_path_file"
  >"$dg_convert_path_file"
  
  #remove duplicate line

  begin_str='"'
  middle_str='/","'
  end_str='/",'
  while read -r pri_filepath
  do
    dg_add_path=${begin_str}${pri_filepath}${middle_str}${dg_filepath}${end_str}
    echo "$dg_add_path" >> "$dg_convert_path_file"
    pri_add_path=${begin_str}${dg_filepath}${middle_str}${pri_filepath}${end_str}
    echo "$pri_add_path" >> "$pri_convert_path_file"
  done < "$pri_filename"
  return $TRUE
}

# convert from multiple line file into one line file
# can not put file_exists_and_not_empty in if [] . only call in this way:  file... &&, or  || . 
makeup_convert_oneline() {
  file_exists_and_not_empty  "$1"  || return $FALSE
  sed -n -e 'H;${x;s/\n//g;p;}' "$1" > "$2"
  #this sed line put all the convert path into oneline. remove the newline characters.
  sed -i 's/,$//' "$2"
  #remove the last comma ,
  return $TRUE
}
