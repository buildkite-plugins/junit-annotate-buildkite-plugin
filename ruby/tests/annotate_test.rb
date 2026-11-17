require 'minitest/autorun'
require 'open3'

describe "Junit annotate plugin parser" do
  it "excludes literal substrings from unsuccessful results without changing total tests" do
    stdout, stderr, status = Open3.capture3(
      {
        'BUILDKITE_PLUGIN_JUNIT_ANNOTATE_EXCLUDE_TESTS_0' => 'checkout [expired].card',
        'BUILDKITE_PLUGIN_JUNIT_ANNOTATE_EXCLUDE_TESTS_1' => 'refund during',
        'BUILDKITE_PLUGIN_JUNIT_ANNOTATE_REPORT_SKIPPED' => 'true'
      },
      "#{__dir__}/../bin/annotate", "#{__dir__}/excluded-tests/"
    )

    assert_equal 64, status.exitstatus, stderr
    assert_includes stdout, "Failures: 1\nErrors: 1\nSkipped: 1\nTotal tests: 7\nExcluded tests: 3\n"
    assert_includes stdout, 'Checkout [expired].card'
    assert_includes stdout, 'checkout expiredXcard'
    assert_includes stdout, 'keep skipped'
    refute_includes stdout, 'hidden failure'
    refute_includes stdout, 'hidden error'
    refute_includes stdout, 'hidden skip'
  end

  it "does not signal failure when all unsuccessful tests are excluded" do
    stdout, stderr, status = Open3.capture3(
      {
        'BUILDKITE_PLUGIN_JUNIT_ANNOTATE_EXCLUDE_TESTS_0' => 'checkout',
        'BUILDKITE_PLUGIN_JUNIT_ANNOTATE_EXCLUDE_TESTS_1' => 'refund',
        'BUILDKITE_PLUGIN_JUNIT_ANNOTATE_EXCLUDE_TESTS_2' => 'Checkout',
        'BUILDKITE_PLUGIN_JUNIT_ANNOTATE_EXCLUDE_TESTS_3' => 'keep'
      },
      "#{__dir__}/../bin/annotate", "#{__dir__}/excluded-tests/"
    )

    assert_equal 0, status.exitstatus, stderr
    assert_equal "Failures: 0\nErrors: 0\nSkipped: 0\nTotal tests: 7\nExcluded tests: 6\n", stdout
  end

  it "keeps excluded tests in slowest-test reporting" do
    stdout, stderr, status = Open3.capture3(
      {
        'BUILDKITE_PLUGIN_JUNIT_ANNOTATE_EXCLUDE_TESTS_0' => '[expired].card',
        'BUILDKITE_PLUGIN_JUNIT_ANNOTATE_REPORT_SLOWEST' => '1'
      },
      "#{__dir__}/../bin/annotate", "#{__dir__}/excluded-tests/"
    )

    assert_equal 64, status.exitstatus, stderr
    assert_includes stdout, '<td>checkout [expired].card</td><td>10.0</td>'
    refute_includes stdout, 'hidden failure'
  end

  it "rejects empty exclusion keywords" do
    stdout, stderr, status = Open3.capture3(
      { 'BUILDKITE_PLUGIN_JUNIT_ANNOTATE_EXCLUDE_TESTS_0' => '' },
      "#{__dir__}/../bin/annotate", "#{__dir__}/excluded-tests/"
    )

    assert_equal 1, status.exitstatus
    assert_empty stdout
    assert_includes stderr, 'exclude-tests entries must not be empty'
  end

  it "handles no failures" do
    stdout, stderr, status = Open3.capture3("#{__dir__}/../bin/annotate", "#{__dir__}/no-test-failures/")

    assert_equal stderr, <<~OUTPUT
      Parsing junit-1.xml
      Parsing junit-2.xml
      Parsing junit-3.xml
      --- ✍️ Preparing annotation
    OUTPUT

    assert_equal stdout, <<~OUTPUT
      Failures: 0
      Errors: 0
      Skipped: 0
      Total tests: 8
    OUTPUT

    assert_equal 0, status.exitstatus
  end

  it "handles failures across multiple files" do
    stdout, stderr, status = Open3.capture3("#{__dir__}/../bin/annotate", "#{__dir__}/two-test-failures/")

    assert_equal stderr, <<~OUTPUT
      Parsing junit-1.xml
      Parsing junit-2.xml
      Parsing junit-3.xml
      --- ✍️ Preparing annotation
    OUTPUT

    assert_equal stdout, <<~OUTPUT
      Failures: 4
      Errors: 0
      Skipped: 0
      Total tests: 6

      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 250 by default in spec.models.account_spec</code></summary>

      <p>expected: 250 got: 500 (compared using eql?)</p>

      <pre><code>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)

        expected: 250
             got: 500

        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/database.rb:16:in `block (2 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/log.rb:17:in `run&#39;
      ./spec/support/log.rb:66:in `block (2 levels) in &lt;top (required)&gt;&#39;</code></pre>

      in <a href="#1">Job #1</a>
      </details>

      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 700 if the account is XYZ in spec.models.account_spec</code></summary>

      <p>expected: 700 got: 500 (compared using eql?)</p>

      <pre><code>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)

        expected: 700
             got: 500

        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/database.rb:16:in `block (2 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/log.rb:17:in `run&#39;
      ./spec/support/log.rb:66:in `block (2 levels) in &lt;top (required)&gt;&#39;</code></pre>

      in <a href="#2">Job #2</a>
      </details>

      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 700 if the account is XYZ in spec.models.account_spec</code></summary>

      <p>expected: 700 got: 500 (compared using eql?)</p>

      <pre><code>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)

        expected: 700
             got: 500

        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/database.rb:16:in `block (2 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/log.rb:17:in `run&#39;
      ./spec/support/log.rb:66:in `block (2 levels) in &lt;top (required)&gt;&#39;</code></pre>

      in <a href="#3">Job #3</a>
      </details>

      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 250 by default in spec.models.account_spec</code></summary>

      <p>expected: 250 got: 500 (compared using eql?)</p>

      <pre><code>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)

        expected: 250
             got: 500

        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/database.rb:16:in `block (2 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/log.rb:17:in `run&#39;
      ./spec/support/log.rb:66:in `block (2 levels) in &lt;top (required)&gt;&#39;</code></pre>

      in <a href="#3">Job #3</a>
      </details>
    OUTPUT

    assert_equal 64, status.exitstatus
  end

  it "handles failures and errors across multiple files" do
    stdout, stderr, status = Open3.capture3("#{__dir__}/../bin/annotate", "#{__dir__}/test-failure-and-error/")

    assert_equal stderr, <<~OUTPUT
      Parsing junit-1.xml
      Parsing junit-2.xml
      Parsing junit-3.xml
      --- ✍️ Preparing annotation
    OUTPUT

    assert_equal stdout, <<~OUTPUT
      Failures: 2
      Errors: 2
      Skipped: 0
      Total tests: 6

      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 700 if the account is XYZ in spec.models.account_spec</code></summary>

      <p>expected: 700 got: 500 (compared using eql?)</p>

      <pre><code>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)

        expected: 700
             got: 500

        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/database.rb:16:in `block (2 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/log.rb:17:in `run&#39;
      ./spec/support/log.rb:66:in `block (2 levels) in &lt;top (required)&gt;&#39;</code></pre>

      in <a href="#2">Job #2</a>
      </details>

      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 700 if the account is XYZ in spec.models.account_spec</code></summary>

      <p>expected: 700 got: 500 (compared using eql?)</p>

      <pre><code>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)

        expected: 700
             got: 500

        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/database.rb:16:in `block (2 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/log.rb:17:in `run&#39;
      ./spec/support/log.rb:66:in `block (2 levels) in &lt;top (required)&gt;&#39;</code></pre>

      in <a href="#3">Job #3</a>
      </details>

      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 250 by default in spec.models.account_spec</code></summary>

      <p>expected: 250 got: 500 (compared using eql?)</p>

      <pre><code>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)

        expected: 250
             got: 500

        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/database.rb:16:in `block (2 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/log.rb:17:in `run&#39;
      ./spec/support/log.rb:66:in `block (2 levels) in &lt;top (required)&gt;&#39;</code></pre>

      in <a href="#1">Job #1</a>
      </details>

      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 250 by default in spec.models.account_spec</code></summary>

      <p>expected: 250 got: 500 (compared using eql?)</p>

      <pre><code>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)

        expected: 250
             got: 500

        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/database.rb:16:in `block (2 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/log.rb:17:in `run&#39;
      ./spec/support/log.rb:66:in `block (2 levels) in &lt;top (required)&gt;&#39;</code></pre>

      in <a href="#3">Job #3</a>
      </details>
    OUTPUT

    assert_equal 64, status.exitstatus
  end

  it "accepts custom regex filename patterns for job id" do
    stdout, stderr, status = Open3.capture3("env", "BUILDKITE_PLUGIN_JUNIT_ANNOTATE_JOB_UUID_FILE_PATTERN=junit-(.*)-custom-pattern.xml", "#{__dir__}/../bin/annotate", "#{__dir__}/custom-job-uuid-pattern/")

    assert_equal stderr, <<~OUTPUT
      Parsing junit-123-456-custom-pattern.xml
      --- ✍️ Preparing annotation
    OUTPUT

    assert_equal stdout, <<~OUTPUT
      Failures: 1
      Errors: 0
      Skipped: 0
      Total tests: 2

      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 250 by default in spec.models.account_spec</code></summary>

      <p>expected: 250 got: 500 (compared using eql?)</p>

      <pre><code>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)

        expected: 250
             got: 500

        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/database.rb:16:in `block (2 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/log.rb:17:in `run&#39;
      ./spec/support/log.rb:66:in `block (2 levels) in &lt;top (required)&gt;&#39;</code></pre>

      in <a href="#123-456">Job #123-456</a>
      </details>
    OUTPUT

    assert_equal 64, status.exitstatus
  end

  it "uses the file path instead of classname for annotation content when specified" do
    stdout, stderr, status = Open3.capture3("env", "BUILDKITE_PLUGIN_JUNIT_ANNOTATE_FAILURE_FORMAT=file", "#{__dir__}/../bin/annotate", "#{__dir__}/test-failure-and-error/")

    assert_equal stderr, <<~OUTPUT
      Parsing junit-1.xml
      Parsing junit-2.xml
      Parsing junit-3.xml
      --- ✍️ Preparing annotation
    OUTPUT

    assert_equal stdout, <<~OUTPUT
      Failures: 2
      Errors: 2
      Skipped: 0
      Total tests: 6

      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 700 if the account is XYZ in ./spec/models/account_spec.rb</code></summary>

      <p>expected: 700 got: 500 (compared using eql?)</p>

      <pre><code>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)

        expected: 700
             got: 500

        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/database.rb:16:in `block (2 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/log.rb:17:in `run&#39;
      ./spec/support/log.rb:66:in `block (2 levels) in &lt;top (required)&gt;&#39;</code></pre>

      in <a href="#2">Job #2</a>
      </details>

      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 700 if the account is XYZ in ./spec/models/account_spec.rb</code></summary>

      <p>expected: 700 got: 500 (compared using eql?)</p>

      <pre><code>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)

        expected: 700
             got: 500

        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/database.rb:16:in `block (2 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/log.rb:17:in `run&#39;
      ./spec/support/log.rb:66:in `block (2 levels) in &lt;top (required)&gt;&#39;</code></pre>

      in <a href="#3">Job #3</a>
      </details>

      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 250 by default in ./spec/models/account_spec.rb</code></summary>

      <p>expected: 250 got: 500 (compared using eql?)</p>

      <pre><code>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)

        expected: 250
             got: 500

        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/database.rb:16:in `block (2 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/log.rb:17:in `run&#39;
      ./spec/support/log.rb:66:in `block (2 levels) in &lt;top (required)&gt;&#39;</code></pre>

      in <a href="#1">Job #1</a>
      </details>

      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 250 by default in ./spec/models/account_spec.rb</code></summary>

      <p>expected: 250 got: 500 (compared using eql?)</p>

      <pre><code>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)

        expected: 250
             got: 500

        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/database.rb:16:in `block (2 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/log.rb:17:in `run&#39;
      ./spec/support/log.rb:66:in `block (2 levels) in &lt;top (required)&gt;&#39;</code></pre>

      in <a href="#3">Job #3</a>
      </details>
    OUTPUT

    assert_equal 64, status.exitstatus
  end

  it "handles failures across multiple files in sub dirs" do
    stdout, stderr, status = Open3.capture3("#{__dir__}/../bin/annotate", "#{__dir__}/tests-in-sub-dirs/")

    assert_equal stderr, <<~OUTPUT
      Parsing sub-dir/junit-1.xml
      Parsing sub-dir/junit-2.xml
      Parsing sub-dir/junit-3.xml
      --- ✍️ Preparing annotation
    OUTPUT

    assert_equal stdout, <<~OUTPUT
      Failures: 4
      Errors: 0
      Skipped: 0
      Total tests: 6

      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 250 by default in spec.models.account_spec</code></summary>

      <p>expected: 250 got: 500 (compared using eql?)</p>

      <pre><code>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)

        expected: 250
             got: 500

        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/database.rb:16:in `block (2 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/log.rb:17:in `run&#39;
      ./spec/support/log.rb:66:in `block (2 levels) in &lt;top (required)&gt;&#39;</code></pre>

      in <a href="#1">Job #1</a>
      </details>

      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 700 if the account is XYZ in spec.models.account_spec</code></summary>

      <p>expected: 700 got: 500 (compared using eql?)</p>

      <pre><code>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)

        expected: 700
             got: 500

        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/database.rb:16:in `block (2 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/log.rb:17:in `run&#39;
      ./spec/support/log.rb:66:in `block (2 levels) in &lt;top (required)&gt;&#39;</code></pre>

      in <a href="#2">Job #2</a>
      </details>

      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 700 if the account is XYZ in spec.models.account_spec</code></summary>

      <p>expected: 700 got: 500 (compared using eql?)</p>

      <pre><code>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)

        expected: 700
             got: 500

        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/database.rb:16:in `block (2 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/log.rb:17:in `run&#39;
      ./spec/support/log.rb:66:in `block (2 levels) in &lt;top (required)&gt;&#39;</code></pre>

      in <a href="#3">Job #3</a>
      </details>

      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 250 by default in spec.models.account_spec</code></summary>

      <p>expected: 250 got: 500 (compared using eql?)</p>

      <pre><code>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)

        expected: 250
             got: 500

        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/database.rb:16:in `block (2 levels) in &lt;top (required)&gt;&#39;
      ./spec/support/log.rb:17:in `run&#39;
      ./spec/support/log.rb:66:in `block (2 levels) in &lt;top (required)&gt;&#39;</code></pre>

      in <a href="#3">Job #3</a>
      </details>
    OUTPUT

    assert_equal 64, status.exitstatus
  end

  it "handles empty failure bodies" do
    stdout, stderr, status = Open3.capture3("#{__dir__}/../bin/annotate", "#{__dir__}/empty-failure-body/")

    assert_equal stderr, <<~OUTPUT
      Parsing junit.xml
      --- ✍️ Preparing annotation
    OUTPUT

    assert_equal stdout, <<~OUTPUT
      Failures: 1
      Errors: 0
      Skipped: 0
      Total tests: 2

      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 250 by default in spec.models.account_spec</code></summary>

      <p>expected: 250 got: 500 (compared using eql?)</p>

      </details>
    OUTPUT

    assert_equal 64, status.exitstatus
  end

  it "handles miss message attributes" do
    stdout, stderr, status = Open3.capture3("#{__dir__}/../bin/annotate", "#{__dir__}/missing-message-attribute/")

    assert_equal stderr, <<~OUTPUT
      Parsing junit.xml
      --- ✍️ Preparing annotation
    OUTPUT

    assert_equal stdout, <<~OUTPUT
      Failures: 1
      Errors: 2
      Skipped: 0
      Total tests: 4

      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 250 by default in spec.models.account_spec</code></summary>

      </details>

      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 100 by default in spec.models.account_spec</code></summary>

      </details>

      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 50 by default in spec.models.account_spec</code></summary>

      </details>
    OUTPUT

    assert_equal 64, status.exitstatus
  end

  it "handles cdata formatted XML files" do
    stdout, stderr, status = Open3.capture3("#{__dir__}/../bin/annotate", "#{__dir__}/failure-with-cdata/")

    assert_equal stderr, <<~OUTPUT
      Parsing junit.xml
      --- ✍️ Preparing annotation
    OUTPUT

    assert_equal stdout, <<~OUTPUT
      Failures: 0
      Errors: 1
      Skipped: 0
      Total tests: 2

      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 250 by default in spec.models.account_spec</code></summary>

      <p>expected: 250 got: 500 (compared using eql?)</p>

      <pre><code>First line of failure output
            Second line of failure output</code></pre>

      </details>
    OUTPUT

    assert_equal 64, status.exitstatus
  end

  it "reports specified amount of slowest tests" do
    stdout, stderr, status = Open3.capture3("env", "BUILDKITE_PLUGIN_JUNIT_ANNOTATE_REPORT_SLOWEST=5", "#{__dir__}/../bin/annotate", "#{__dir__}/no-test-failures/")

    assert_equal stderr, <<~OUTPUT
      Parsing junit-1.xml
      Parsing junit-2.xml
      Parsing junit-3.xml
      --- ✍️ Preparing annotation
      Reporting slowest tests ⏱
    OUTPUT

    assert_equal stdout, <<~OUTPUT
      Failures: 0
      Errors: 0
      Skipped: 0
      Total tests: 8

      <details>
      <summary>5 slowest tests</summary>

      <table>
      <thead><tr><th>Unit</th><th>Test</th><th>Time</th></tr></thead>
      <tbody>
      <tr><td>spec.models.account_spec</td><td>Account#maximum_jobs_added_by_pipeline_changer returns 250 by default</td><td>0.977127</td></tr>
      <tr><td>spec.models.account_spec</td><td>Account#maximum_jobs_added_by_pipeline_changer returns 250 by default</td><td>0.967127</td></tr>
      <tr><td>spec.models.account_spec</td><td>Account#maximum_jobs_added_by_pipeline_changer returns 500 if the account is ABC</td><td>0.620013</td></tr>
      <tr><td>spec.models.account_spec</td><td>Account#maximum_jobs_added_by_pipeline_changer returns 900 if the account is F00</td><td>0.520013</td></tr>
      <tr><td>spec.models.account_spec</td><td>Account#maximum_jobs_added_by_pipeline_changer returns 700 if the account is XYZ</td><td>0.420013</td></tr>
      </tbody>
      </table>
      </details>
    OUTPUT

    assert_equal 0, status.exitstatus
  end

  it "handles junit dir paths with hidden directories" do
    stdout, stderr, status = Open3.capture3("#{__dir__}/../bin/annotate", "#{__dir__}/.tests-in-hidden-dir/")

    assert_equal stderr, <<~OUTPUT
      Parsing junit-1.xml
      --- ✍️ Preparing annotation
    OUTPUT

    assert_equal stdout, <<~OUTPUT
      Failures: 0
      Errors: 0
      Skipped: 0
      Total tests: 2
    OUTPUT

    assert_equal 0, status.exitstatus
  end

  it "correctly parses skipped tests" do
    stdout, stderr, status = Open3.capture3("#{__dir__}/../bin/annotate", "#{__dir__}/skipped-test/")

    assert_equal stderr, <<~OUTPUT
      Parsing junit.xml
      --- ✍️ Preparing annotation
    OUTPUT

    assert_equal stdout, <<~OUTPUT
      Failures: 0
      Errors: 0
      Skipped: 1
      Total tests: 2
    OUTPUT

    assert_equal 0, status.exitstatus
  end

  it "can report skipped tests" do
    stdout, stderr, status = Open3.capture3("env", "BUILDKITE_PLUGIN_JUNIT_ANNOTATE_REPORT_SKIPPED=true", "#{__dir__}/../bin/annotate", "#{__dir__}/skipped-test/")

    assert_equal stderr, <<~OUTPUT
      Parsing junit.xml
      --- ✍️ Preparing annotation
      Reporting skipped tests
    OUTPUT

    assert_equal stdout, <<~OUTPUT
      Failures: 0
      Errors: 0
      Skipped: 1
      Total tests: 2

      <details>
      <summary>1 tests skipped</summary>

      <ol>
      <li>Account#maximum_jobs_added_by_pipeline_changer returns 250 by default in spec.models.account_spec (because of reasons)</li>
      </ol>
      </details>
    OUTPUT

    assert_equal 0, status.exitstatus
  end
end
