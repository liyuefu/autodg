#!/usr/bin/env bats

setup() {
  load "$BATS_TEST_DIRNAME/../src/lib/bsfl.sh"
  load "$BATS_TEST_DIRNAME/../src/lib/ext_bsfl.sh"
}
#load ../lib/bsfl.sh

@test "test_directory_exist_fun_should_ok" {
  run directory_exists "$BATS_TEST_DIRNAME/.."
  [ "$output" == ''  ]

}

@test "test_/tmp_exists_ok" {
  [  -d '/tmp' ]
}

@test "test_/tmpa_not_exists_ok" {
  [ ! -d '/tmpa' ]
}
