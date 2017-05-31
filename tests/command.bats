#!/usr/bin/env bats

load "$BATS_PATH/load.bash"

@test "calls git log" {
  stub git "log : echo some-log"
  git log
  assert_success
  unstub git
}