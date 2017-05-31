# JUnit Annotate Buildkite Plugin

A [Buildkite](https://buildkite.com/) plugin that creates a summary of build failures as a build annotation, by parsing JUnit XML test report artifacts from previous jobs.

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
      junit-annotate#v0.0.1:
        artifacts: tmp/junit-*.xml
```

## Configuration

### `artifacts` (required)

The artifact glob path to find the JUnit XML files.

Example: `tmp/junit-*.xml`

## License

MIT (see [LICENSE](LICENSE))