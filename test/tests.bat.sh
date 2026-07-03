setup(){
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'

  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  PATH="$DIR/../src:$PATH"

}


@test "Show Welcome message on first invocation" {
  if [[ -e /tmp/bats-tutorial-project-ran ]]; then  
    skip " The FIRST_RUN_FILE already exists"
  fi

  run project.sh
  assert_output -p "Welcome to our project"

  run project.sh
  refute_output -p "Welcome to our project"

}

teardown() {
  rm -f /tmp/bats-tutorial-project-ran
#echo 
}
