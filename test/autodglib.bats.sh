#!/usr/bin/env bats
#setup first
setup() {
  load "$BATS_TEST_DIRNAME/test_helper/bats-support/load"
  load "$BATS_TEST_DIRNAME/test_helper/bats-assert/load"
  load "$BATS_TEST_DIRNAME/../src/lib/bsfl.sh"
  load "$BATS_TEST_DIRNAME/../src/lib/ext_bsfl.sh"
  load "$BATS_TEST_DIRNAME/../src/lib/autodglib.sh"

  REPO_TMP="$BATS_TEST_DIRNAME/../tmp"
  mkdir -p "$REPO_TMP"

  printf 'ctp\n' > "$BATS_TEST_TMPDIR/dbname.tmp"
  : > "$BATS_TEST_TMPDIR/empty.tmp"
  printf '/u02/oradata/ctp/system01.dbf\n/u02/oradata/ctp/sysaux01.dbf\n' > "$BATS_TEST_TMPDIR/dbpath.tmp"
  printf '+DATA/ctp/datafile/system01.dbf\n+DATA/ctp/datafile/data201.dbf\n+DATA/ctp/datafile/data2/users01.dbf\n+DATA/ctp/tempfile/temp01.dbf\n' > "$BATS_TEST_TMPDIR/dbpath-asm.tmp"
  printf 'oracle_base_pr=/u01/app/oracle/\n' > "$BATS_TEST_TMPDIR/para2.cfg"
  printf 'oracle_base_pr=/u01/app/oracle\n' > "$BATS_TEST_TMPDIR/para-ok.cfg"
  printf '"/a/","/b/",\n"/c/","/d/",\n' > "$BATS_TEST_TMPDIR/pri_convert.txt"

}

@test "check_path_ends_with_slash_ok" {
  run check_path_ends_with_slash "$BATS_TEST_TMPDIR/para-ok.cfg"
  assert_output ""
}

#  "oracle_base_pr=/u01/app/oracle/" should be returned.
@test "check_path_ends_with_slash_fail" {
  run check_path_ends_with_slash "$BATS_TEST_TMPDIR/para2.cfg"
#  refute_output ""
  assert_output -p "oracle_base_pr=/u01/app/oracle/"
}
#
@test "test_end_with_slash_ok" {

  run end_with "abc/" "/"
  [ "$status" -eq 0 ]
  [ "$output" == "" ]
}
@test "test_end_with_slash_fail" {
  run end_with "abc/c" "/"
  [ "$status" -eq 1 ]
  [ "$output" == "" ]
}

@test "test_get_one_row_data_ok" {
  run get_one_row_data  "$BATS_TEST_TMPDIR/dbname.tmp" "$BATS_TEST_TMPDIR/dbname.txt"
  assert_output ""
  [ "$(cat "$BATS_TEST_TMPDIR/dbname.txt")" = "ctp" ]
}

@test "test_get_one_row_data_fail_nofile" {
  run get_one_row_data "$BATS_TEST_TMPDIR/nofile.tmp" "$BATS_TEST_TMPDIR/nofile.txt"
  assert_output ""
  [ ! -f "$BATS_TEST_TMPDIR/nofile.txt" ]
}
@test "test_get_one_row_data_fail_nodata" {
  run get_one_row_data "$BATS_TEST_TMPDIR/empty.tmp" "$BATS_TEST_TMPDIR/empty.txt"
  assert_output ""
  [ ! -f "$BATS_TEST_TMPDIR/empty.txt" ]
}

@test "test_get_multiple_row_data_ok" {
  run get_multiple_row_data "$BATS_TEST_TMPDIR/dbpath.tmp" "$BATS_TEST_TMPDIR/dbpath.txt"
  assert_output ""
  grep -q "/u02/oradata/ctp" "$BATS_TEST_TMPDIR/dbpath.txt"
}
@test "test_get_multiple_row_+asm_ok" {
  run get_multiple_row_data "$BATS_TEST_TMPDIR/dbpath-asm.tmp" "$BATS_TEST_TMPDIR/dbpath-asm.txt"
  assert_output ""
  grep -q "+DATA/ctp/datafile/data2" "$BATS_TEST_TMPDIR/dbpath-asm.txt"
  grep -q "+DATA/ctp/datafile" "$BATS_TEST_TMPDIR/dbpath-asm.txt"
  grep -q "+DATA/ctp/tempfile" "$BATS_TEST_TMPDIR/dbpath-asm.txt"
}
@test "test_get_diskgroup_name_ok" {
  run get_diskgroup_name "$BATS_TEST_TMPDIR/dbpath-asm.tmp" "$BATS_TEST_TMPDIR/dg.txt"
  assert_output ""
  [ "$(cat "$BATS_TEST_TMPDIR/dg.txt")" = "+DATA" ]
}

@test "makeup_file_convert_fail" {
  run makeup_file_convert "$BATS_TEST_TMPDIR/nofile-dbpath.txt" '/u03/oradata/orcldg' "$BATS_TEST_TMPDIR/pri_convert.txt" "$BATS_TEST_TMPDIR/dg_convert.txt"
  assert_failure
  
}
@test "makeup_file_convert_ok" {
  run makeup_file_convert "$BATS_TEST_TMPDIR/dbpath.tmp" '/u03/oradata/orcldg' "$BATS_TEST_TMPDIR/pri_convert.out" "$BATS_TEST_TMPDIR/dg_convert.out"
  assert_success
  
}

@test "makeup_convert_oneline_fail" {
  run makeup_convert_oneline "$BATS_TEST_TMPDIR/pri_convert_no.txt" "$BATS_TEST_TMPDIR/pri_convert_oneline.txt"
  assert_failure
}

@test "makeup_convert_oneline_ok" {
  run makeup_convert_oneline "$BATS_TEST_TMPDIR/pri_convert.txt" "$BATS_TEST_TMPDIR/pri_convert_oneline.txt"
  assert_success
  [ -f "$BATS_TEST_TMPDIR/pri_convert_oneline.txt" ]
}
## teardown cleanup 
teardown() {
  echo ""
#  rm -f ../tmp/*.txt
#  echo "teardown"
}
