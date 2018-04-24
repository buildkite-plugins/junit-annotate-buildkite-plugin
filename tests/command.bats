#!/usr/bin/env bats

load "$BATS_PATH/load.bash"

# Uncomment to get debug output from each stub
# export MKTEMP_STUB_DEBUG=/dev/tty
# export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty
# export DOCKER_STUB_DEBUG=/dev/tty

@test "runs the annotator and creates the annotation" {
  export BUILDKITE_PLUGIN_JUNIT_ANNOTATE_ARTIFACTS="junits/*.xml"

  artifacts_tmp="tests/tmp/$PWD/junit-artifacts"
  annotation_tmp="tests/tmp/$PWD/junit-annotation"

  stub mktemp \
    "-d junit-annotate-plugin-artifacts-tmp.XXXXXXXXXX : mkdir -p $artifacts_tmp; echo $artifacts_tmp" \
    "-d junit-annotate-plugin-annotation-tmp.XXXXXXXXXX : mkdir -p $annotation_tmp; echo $annotation_tmp"

  stub buildkite-agent "artifact download junits/*.xml /plugin/tests/tmp//plugin/junit-artifacts : echo Downloaded artifacts" \
                       "annotate --context junit --style error : echo Annotation added"

  stub docker "--log-level error run --rm --volume /plugin/tests/tmp//plugin/junit-artifacts:/junits --volume /plugin/hooks/../ruby:/src --env BUILDKITE_PLUGIN_JUNIT_ANNOTATE_JOB_UUID_FILE_PATTERN= ruby:2.5-alpine /src/bin/annotate /junits : echo ANNOTATION"

  run "$PWD/hooks/command"

  assert_success

  assert_output --partial "Annotation added"
  
  unstub mktemp
  unstub buildkite-agent
  unstub docker
}