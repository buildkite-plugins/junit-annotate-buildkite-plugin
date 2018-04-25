# JUnit Annotate Buildkite Plugin

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
      junit-annotate#v1.0.1:
        artifacts: tmp/junit-*.xml
```

## Configuration

### `artifacts` (required)

The artifact glob path to find the JUnit XML files.

Example: `tmp/junit-*.xml`

### `job-uuid-file-pattern` (optional)

The regular expression (with capture group) that matches the job UUID in the junit file names. This is used to create the job links in the annotation.

To use this, configure your test reporter to embed the `$BUILDKITE_JOB_UUID` environment variable into your junit file names. For example `"junit-buildkite-job-$BUILDKITE_JOB_UUID.xml"`.

Default: `-(.*).xml`

## Developing

To test the junit parser (in Ruby) and plugin hooks (in Bash):

```bash
docker-compose run --rm plugin &&
docker-compose run --rm ruby
```

To test the Ruby parser locally:

```bash
cd ruby
rake
```

## License

MIT (see [LICENSE](LICENSE))