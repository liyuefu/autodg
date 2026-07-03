#!/usr/bin/env bats
# -*- tab-width: 4; encoding: utf-8 -*-

setup(){
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load '../src/lib/ext_bsfl.sh'

  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  PATH="$DIR/../src:$PATH"

}

#如果返回b,则success
@test "test_extract_should_ok " {
  run extract 'abcdef' 'a' 'c'
  assert_output 'b'
}

# 如果不返回 cd, 则sucess
@test "test_extract_should_fail" {
  run extract 'abcdef' 'b' 'f'
  refute_output 'cd'
}

@test "test_end_with_slash_ok" {
  run end_with "abc/" "/"
  assert_success
}
@test "test_end_with_slash_fail" {
  run end_with "abc/" "a"
  assert_failure
}

@test "test_dirname_should_ok" {
  run dirname '/u02/oradata/orcl/system.dbf'
  assert_output '/u02/oradata/orcl'
}

@test "test_file_exists_and_not_empty_ok" {
  run file_exists_and_not_empty "/etc/passwd"
  assert_success
}

@test "test_file_exists_and_not_empty_nofile" {
  run file_exists_and_not_empty "./tmp/dbno.tmp"
  assert_failure
}
@test "test_file_exists_and_empty" {
  run file_exists_and_not_empty "./tmp/dbempty.tmp"
  assert_failure
}

teardown() {
    rm -rf ./tmp/*.txt
}



