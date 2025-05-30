# JUnit Annotate Buildkite Plugin [![Build status](https://badge.buildkite.com/e57701b1037f2c77d0b3f2e4901559ed2e8f131119cd7806ad.svg?branch=master)](https://buildkite.com/buildkite/plugins-junit-annotate)

A [Buildkite plugin](https://buildkite.com/docs/agent/v3/plugins) that parses junit.xml artifacts (generated across any number of parallel steps) and creates a [build annotation](https://buildkite.com/docs/agent/v3/cli-annotate) listing the individual tests that failed.

## Example

The following pipeline will run `test.sh` jobs in parallel, and then process all the resulting JUnit XML files to create a summary build annotation.

```yml
steps:
  - command: test.sh
    parallelism: 50
    artifact_paths: tmp/junit-*.xml
  - wait: ~
    continue_on_failure: true
  - plugins:
      - junit-annotate#v2.7.0:
          artifacts: tmp/junit-*.xml
```

For scenarios where you have different artifact paths that you want to add as annotation then call the plugin multiple times in the pipeline with different contexts as shown below:

```yml
steps:
  - command: test.sh
    parallelism: 50
    artifact_paths: tmp/junit-*.xml
  - command: anothertest.sh
    artifact_paths: artifacts/junit-*.xml
  - wait: ~
    continue_on_failure: true
  - plugins:
      - junit-annotate#v2.7.0:
          artifacts: tmp/junit-*.xml
  - plugins:
      - junit-annotate#v2.7.0:
          artifacts: artifacts/junit-*.xml
          context: junit-artifacts
```

## Configuration

### `artifacts` (required)

The artifact glob path to find the JUnit XML files.

Example: `tmp/junit-*.xml`

### `always-annotate` (optional, boolean)

Forces the creation of the annotation even when no failures or errors are found

### `context` (optional)

Default: `junit`

The buildkite annotation context to use. Useful to differentiate multiple runs of this plugin in a single pipeline.

### `job-uuid-file-pattern` (optional)

Default: `-(.*).xml`

The regular expression (with capture group) that matches the job UUID in the junit file names. This is used to create the job links in the annotation.

To use this, configure your test reporter to embed the `$BUILDKITE_JOB_ID` environment variable into your junit file names. For example `"junit-buildkite-job-$BUILDKITE_JOB_ID.xml"`.

### `failure-format` (optional)

This setting controls the format of your failed test in the main annotation summary.

There are two options for this:
* `classname` (the default)
  * displays: `MyClass::UnderTest text of the failed expectation in path.to.my_class.under_test`
* `file`
  * displays: `MyClass::UnderTest text of the failed expectation in path/to/my_class/under_test.file_ext`

### `fail-build-on-error` (optional)

Default: `false`

If this setting is true and any errors are found in the JUnit XML files during parsing, the annotation step will exit with a non-zero value, which should cause the build to fail.

### `failed-download-exit-code` (optional, integer)

Default: `2`

Exit code of the plugin if the call to `buildkite-agent artifact download` fails.

### `min-tests` (optional, integer)

Minimum amount of run tests that need to be analyzed or a failure will be reported. It is useful to ensure that tests are actually run and report files to analyze do contain information.

### `report-skipped` (optional, boolean)

Default: `false`

Will add a list of skipped tests at the end of the annotation. Note that even if there are skipped tests, the annotation may not be added unless other options or results of the processing forces it to.

### `report-slowest` (optional)

Default: `0`

Include the specified number of slowest tests in the annotation. The annotation will always be shown.

### `ruby-image` (optional)

The docker image to use for running the analysis code. Must be a valid image reference that can run the corresponding ruby code and the agent running the step must be able to pull it if not already present.

Default: `ruby:3.1-alpine@sha256:a39e26d0598837f08c75a42c8b0886d9ed5cc862c4b535662922ee1d05272fca`

### `run-in-docker` (optional, boolean)

Default: `true`

Controls whether the JUnit processing should run inside a Docker container. When set to `false`, the processing will run directly on the host using the system's Ruby installation.

## Compatibility

| Elastic Stack | Agent Stack K8s | Hosted (Mac) | Hosted (Linux) | Notes |
| :-----------: | :-------------: | :----: | :----: |:---- |
| ✅ | ⚠️ | ⚠️ | ✅ | **K8s** - Out of the box, requires `run-in-docker: false` and a container image with `ruby` installed<br>Likely requires some complex podSpec (pending investigation)<br>**Hosted (Mac)** - instances do not ship with the Docker daemon, but can use a `ruby` binary on the agent |

- ✅ Fully supported (all combinations of attributes have been tested to pass)
- ⚠️ Partially supported (some combinations cause errors/issues)
- ❌ Not supported


## Developing

To run testing, shellchecks and plugin linting use use `bk run` with the [Buildkite CLI](https://github.com/buildkite/cli).

```bash
bk run
```

Or if you want to run just the plugin tests, you can use the docker [Plugin Tester](https://github.com/buildkite-plugins/buildkite-plugin-tester):

```bash
docker run --rm -ti -v "${PWD}":/plugin buildkite/plugin-tester:latest
```

To test the Ruby code with `rake` in docker:

```bash
docker-compose run --rm ruby
```

To test your plugin in your builds prior to opening a pull request, you can refer to your fork and SHA from a branch in your `pipeline.yml`.

```
steps:
  - label: Annotate
    plugins:
      - YourGithubHandle/junit-annotate#v2.7.0:
          ...
```

## License

MIT (see [LICENSE](LICENSE))
