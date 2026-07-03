#!/usr/bin/env bats
#setup first
setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load '../src/lib/bsfl.sh'
  if [ ! -d ./tmp ]; then
    mkdir ./tmp
  else
    # rm -rf ./tmp/*
    echo ""
  fi

}
#test functions of autodg.
@test "has_value function ok" {
  str1="a"
  has_value str1
}

@test "has_value function fail" {
  str2=""
  ! has_value str2
}

@test "file_exists ok" {
  file='/etc/passwd'
  file_exists $file
}
