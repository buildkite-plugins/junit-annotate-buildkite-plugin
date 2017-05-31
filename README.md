# JUnit Annotate Buildkite Plugin

A [Buildkite](https://buildkite.com/) plugin for annotating your builds with the test failures.

## Example

The following pipeline will run 50 `test.sh` jobs in parallel, and then process all the resulting JUnit XML files to create a summary build annotation.

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