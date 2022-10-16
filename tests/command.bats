#!/usr/bin/env bats

load "${BATS_PLUGIN_PATH}/load.bash"

# Uncomment to get debug output from each stub
# export MKTEMP_STUB_DEBUG=/dev/tty
# export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty
# export DOCKER_STUB_DEBUG=/dev/tty
# export DU_STUB_DEBUG=/dev/tty

export artifacts_tmp="tests/tmp/junit-artifacts"
export annotation_tmp="tests/tmp/junit-annotation"
export annotation_input="tests/tmp/annotation.input"

@test "runs the annotator and creates the annotation" {
  export BUILDKITE_PLUGIN_JUNIT_ANNOTATE_ARTIFACTS="junits/*.xml"
  export BUILDKITE_PLUGIN_JUNIT_ANNOTATE_FAIL_BUILD_ON_ERROR=false

  stub mktemp \
    "-d \* : mkdir -p '$artifacts_tmp'; echo '$artifacts_tmp'" \
    "-d \* : mkdir -p '$annotation_tmp'; echo '$annotation_tmp'"

  stub buildkite-agent \
    "artifact download \* \* : echo Downloaded artifact \$3 to \$4" \
    "annotate --context \* --style \* : cat >'${annotation_input}'; echo Annotation added with context \$3 and style \$5, content saved"

  stub docker \
    "--log-level error run --rm --volume \* --volume \* --env \* --env \* --env \* ruby:2.7-alpine ruby /src/bin/annotate /junits : echo '<details>Failure</details>' && exit 64"

  run "$PWD/hooks/command"

  assert_success

  assert_output --partial "Annotation added with context junit and style error"
  assert_equal "$(cat "${annotation_input}")" '<details>Failure</details>'

  unstub mktemp
  unstub buildkite-agent
  unstub docker
  rm "${annotation_input}"
}


@test "can define a special context" {
  export BUILDKITE_PLUGIN_JUNIT_ANNOTATE_ARTIFACTS="junits/*.xml"
  export BUILDKITE_PLUGIN_JUNIT_ANNOTATE_CONTEXT="junit_custom_context"

  stub mktemp \
    "-d \* : mkdir -p '$artifacts_tmp'; echo '$artifacts_tmp'" \
    "-d \* : mkdir -p '$annotation_tmp'; echo '$annotation_tmp'"

  stub buildkite-agent \
    "artifact download \* \* : echo Downloaded artifact \$3 to \$4" \
    "annotate --context \* --style \* : cat >'${annotation_input}'; echo Annotation added with context \$3 and style \$5, content saved"

  stub docker \
    "--log-level error run --rm --volume \* --volume \* --env \* --env \* --env \* ruby:2.7-alpine ruby /src/bin/annotate /junits : echo '<details>Failure</details>' && exit 64"

  run "$PWD/hooks/command"

  assert_success

  assert_output --partial "Annotation added with context junit_custom_context"
  
  unstub mktemp
  unstub buildkite-agent
  unstub docker
  rm "${annotation_input}"
}
@test "can pass through optional job uuid file pattern" {
  export BUILDKITE_PLUGIN_JUNIT_ANNOTATE_ARTIFACTS="junits/*.xml"
  export BUILDKITE_PLUGIN_JUNIT_ANNOTATE_JOB_UUID_FILE_PATTERN="custom_(*)_pattern.xml"

  stub mktemp \
    "-d \* : mkdir -p '$artifacts_tmp'; echo '$artifacts_tmp'" \
    "-d \* : mkdir -p '$annotation_tmp'; echo '$annotation_tmp'"

  stub buildkite-agent \
    "artifact download \* \* : echo Downloaded artifact \$3 to \$4" \
    "annotate --context \* --style \* : cat >'${annotation_input}'; echo Annotation added with context \$3 and style \$5, content saved"

  stub docker \
    "--log-level error run --rm --volume \* --volume \* --env BUILDKITE_PLUGIN_JUNIT_ANNOTATE_JOB_UUID_FILE_PATTERN='custom_(*)_pattern.xml' --env \* --env \* ruby:2.7-alpine ruby /src/bin/annotate /junits : echo '<details>Failure</details>' && exit 64"

  run "$PWD/hooks/command"

  assert_success

  assert_output --partial "Annotation added"

  unstub mktemp
  unstub buildkite-agent
  unstub docker
  rm "${annotation_input}"
}

@test "can pass through optional failure format" {
  export BUILDKITE_PLUGIN_JUNIT_ANNOTATE_ARTIFACTS="junits/*.xml"
  export BUILDKITE_PLUGIN_JUNIT_ANNOTATE_FAILURE_FORMAT="file"

  stub mktemp \
    "-d \* : mkdir -p '$artifacts_tmp'; echo '$artifacts_tmp'" \
    "-d \* : mkdir -p '$annotation_tmp'; echo '$annotation_tmp'"

  stub buildkite-agent \
    "artifact download \* \* : echo Downloaded artifact \$3 to \$4" \
    "annotate --context \* --style \* : cat >'${annotation_input}'; echo Annotation added with context \$3 and style \$5, content saved"

  stub docker \
    "--log-level error run --rm --volume \* --volume \* --env \* --env BUILDKITE_PLUGIN_JUNIT_ANNOTATE_FAILURE_FORMAT='file' --env \* ruby:2.7-alpine ruby /src/bin/annotate /junits : echo '<details>Failure</details>' && exit 64"

  run "$PWD/hooks/command"

  assert_success

  assert_output --partial "Annotation added"

  unstub mktemp
  unstub buildkite-agent
  unstub docker
  rm "${annotation_input}"
}

@test "doesn't create annotation unless there's failures" {
  export BUILDKITE_PLUGIN_JUNIT_ANNOTATE_ARTIFACTS="junits/*.xml"

  stub mktemp \
    "-d \* : mkdir -p '$artifacts_tmp'; echo '$artifacts_tmp'" \
    "-d \* : mkdir -p '$annotation_tmp'; echo '$annotation_tmp'"

  stub buildkite-agent \
    "artifact download \* \* : echo Downloaded artifact \$3 to \$4"

  stub docker \
    "--log-level error run --rm --volume \* --volume \* --env \* --env \* --env \* ruby:2.7-alpine ruby /src/bin/annotate /junits : echo No test errors"

  run "$PWD/hooks/command"

  assert_success

  unstub mktemp
  unstub buildkite-agent
  unstub docker
}

@test "errors without the 'artifacts' property set" {
  run "$PWD/hooks/command"

  assert_failure

  assert_output --partial "Missing artifacts configuration for the plugin"
  refute_output --partial ":junit:"
}

@test "fails if the annotation is larger than 1MB" {
  export BUILDKITE_PLUGIN_JUNIT_ANNOTATE_ARTIFACTS="junits/*.xml"

  stub mktemp \
    "-d \* : mkdir -p '$artifacts_tmp'; echo '$artifacts_tmp'" \
    "-d \* : mkdir -p '$annotation_tmp'; echo '$annotation_tmp'"

  # 1KB over the 1MB size limit of annotations
  stub du \
    "-k \* : echo 1025 \$2"

  stub buildkite-agent \
    "artifact download \* \* : echo Downloaded artifact \$3 to \$4"

  stub docker \
    "--log-level error run --rm --volume \* --volume \* --env \* --env \* --env \* ruby:2.7-alpine ruby /src/bin/annotate /junits : echo '<details>Failure</details>' && exit 64"

  run "$PWD/hooks/command"

  assert_success

  assert_output --partial "Failures too large to annotate"

  unstub docker
  unstub du
  unstub buildkite-agent
  unstub mktemp
}


@test "returns an error if fail-build-on-error is true" {
  export BUILDKITE_PLUGIN_JUNIT_ANNOTATE_ARTIFACTS="junits/*.xml"
  export BUILDKITE_PLUGIN_JUNIT_ANNOTATE_FAIL_BUILD_ON_ERROR=true

  stub mktemp \
    "-d \* : mkdir -p '$artifacts_tmp'; echo '$artifacts_tmp'" \
    "-d \* : mkdir -p '$annotation_tmp'; echo '$annotation_tmp'"

  stub buildkite-agent \
    "artifact download \* \* : echo Downloaded artifact \$3 to \$4" \
    "annotate --context \* --style \* : cat >'${annotation_input}'; echo Annotation added with context \$3 and style \$5, content saved"

  stub docker \
    "--log-level error run --rm --volume \* --volume \* --env \* --env \* --env \* ruby:2.7-alpine ruby /src/bin/annotate /junits : echo '<details>Failure</details>' && exit 64"

  run "$PWD/hooks/command"

  assert_failure

  unstub mktemp
  unstub buildkite-agent
  unstub docker
  rm "${annotation_input}"
}

@test "returns an error if fail-build-on-error is true and annotation is too large" {
  export BUILDKITE_PLUGIN_JUNIT_ANNOTATE_ARTIFACTS="junits/*.xml"
  export BUILDKITE_PLUGIN_JUNIT_ANNOTATE_FAIL_BUILD_ON_ERROR=true

  stub mktemp \
    "-d \* : mkdir -p '$artifacts_tmp'; echo '$artifacts_tmp'" \
    "-d \* : mkdir -p '$annotation_tmp'; echo '$annotation_tmp'"

  # 1KB over the 1MB size limit of annotations
  stub du \
    "-k \* : echo 1025 \$2"
  
  stub buildkite-agent \
    "artifact download \* \* : echo Downloaded artifact \$3 to \$4"

  stub docker \
    "--log-level error run --rm --volume \* --volume \* --env \* --env \* --env \* ruby:2.7-alpine ruby /src/bin/annotate /junits : echo '<details>Failure</details>' && exit 64"

  run "$PWD/hooks/command"

  assert_failure

  assert_output --partial "Failures too large to annotate"

  unstub mktemp
  unstub du
  unstub buildkite-agent
  unstub docker
}

@test "error bubbles up when ruby code fails with anything but 64" {
  export BUILDKITE_PLUGIN_JUNIT_ANNOTATE_ARTIFACTS="junits/*.xml"
  export BUILDKITE_PLUGIN_JUNIT_ANNOTATE_FAIL_BUILD_ON_ERROR=false

  stub mktemp \
    "-d \* : mkdir -p '$artifacts_tmp'; echo '$artifacts_tmp'" \
    "-d \* : mkdir -p '$annotation_tmp'; echo '$annotation_tmp'"

  stub buildkite-agent \
    "artifact download \* \* : echo Downloaded artifact \$3 to \$4"

  stub docker \
    "--log-level error run --rm --volume \* --volume \* --env \* --env \* --env \* ruby:2.7-alpine ruby /src/bin/annotate /junits : echo '<details>Failure</details>' && exit 147"

  run "$PWD/hooks/command"

  assert_failure 147

  assert_output --partial "Error when processing JUnit tests"

  unstub mktemp
  unstub buildkite-agent
  unstub docker
}



@test "error bubbles up when agent download fails" {
  export BUILDKITE_PLUGIN_JUNIT_ANNOTATE_ARTIFACTS="junits/*.xml"
  export BUILDKITE_PLUGIN_JUNIT_ANNOTATE_FAIL_BUILD_ON_ERROR=false

  stub mktemp \
    "-d \* : mkdir -p '$artifacts_tmp'; echo '$artifacts_tmp'" \
    "-d \* : mkdir -p '$annotation_tmp'; echo '$annotation_tmp'"

  stub buildkite-agent \
    "artifact download \* \* : exit 1"

  run "$PWD/hooks/command"

  assert_failure 2

  assert_output --partial "Could not download artifacts"

  unstub mktemp
  unstub buildkite-agent
}