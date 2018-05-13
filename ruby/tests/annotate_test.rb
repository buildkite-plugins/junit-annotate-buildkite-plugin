require 'minitest/autorun'
require 'open3'

describe "Junit annotate plugin parser" do
  it "handles no failures" do
    output, status = Open3.capture2e("#{__dir__}/../bin/annotate", "#{__dir__}/no-test-failures/")

    assert_equal <<~OUTPUT, output
      Parsing junit-1.xml
      Parsing junit-3.xml
      Parsing junit-2.xml
      --- ❓ Checking failures
      There were no failures/errors 🙌
    OUTPUT

    assert_equal 0, status.exitstatus
  end

  it "handles failures across multiple files" do
    output, status = Open3.capture2e("#{__dir__}/../bin/annotate", "#{__dir__}/two-test-failures/")

    assert_equal <<~OUTPUT, output
      Parsing junit-1.xml
      Parsing junit-3.xml
      Parsing junit-2.xml
      --- ❓ Checking failures
      There are 4 failures/errors 😭
      --- ✍️ Preparing annotation
      4 failures:
      
      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 250 by default in spec.models.account_spec</code></summary>
      
      <code><pre>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)
      
        expected: 250
             got: 500
      
        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in <top (required)>'
      ./spec/support/database.rb:16:in `block (2 levels) in <top (required)>'
      ./spec/support/log.rb:17:in `run'
      ./spec/support/log.rb:66:in `block (2 levels) in <top (required)>'</pre></code>
      
      in <a href="#1">Job #1</a>
      </details>
      
      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 700 if the account is XYZ in spec.models.account_spec</code></summary>
      
      <code><pre>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)
      
        expected: 700
             got: 500
      
        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in <top (required)>'
      ./spec/support/database.rb:16:in `block (2 levels) in <top (required)>'
      ./spec/support/log.rb:17:in `run'
      ./spec/support/log.rb:66:in `block (2 levels) in <top (required)>'</pre></code>
      
      in <a href="#3">Job #3</a>
      </details>

      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 250 by default in spec.models.account_spec</code></summary>
      
      <code><pre>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)
      
        expected: 250
             got: 500
      
        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in <top (required)>'
      ./spec/support/database.rb:16:in `block (2 levels) in <top (required)>'
      ./spec/support/log.rb:17:in `run'
      ./spec/support/log.rb:66:in `block (2 levels) in <top (required)>'</pre></code>
      
      in <a href="#3">Job #3</a>
      </details>
      
      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 700 if the account is XYZ in spec.models.account_spec</code></summary>
      
      <code><pre>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)
      
        expected: 700
             got: 500
      
        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in <top (required)>'
      ./spec/support/database.rb:16:in `block (2 levels) in <top (required)>'
      ./spec/support/log.rb:17:in `run'
      ./spec/support/log.rb:66:in `block (2 levels) in <top (required)>'</pre></code>
      
      in <a href="#2">Job #2</a>
      </details>
    OUTPUT

    assert_equal 0, status.exitstatus
  end

  it "handles failures and errors across multiple files" do
    output, status = Open3.capture2e("#{__dir__}/../bin/annotate", "#{__dir__}/test-failure-and-error/")

    assert_equal <<~OUTPUT, output
      Parsing junit-1.xml
      Parsing junit-3.xml
      Parsing junit-2.xml
      --- ❓ Checking failures
      There are 4 failures/errors 😭
      --- ✍️ Preparing annotation
      2 failures and 2 errors:
      
      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 250 by default in spec.models.account_spec</code></summary>
      
      <code><pre>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)
      
        expected: 250
             got: 500
      
        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in <top (required)>'
      ./spec/support/database.rb:16:in `block (2 levels) in <top (required)>'
      ./spec/support/log.rb:17:in `run'
      ./spec/support/log.rb:66:in `block (2 levels) in <top (required)>'</pre></code>
      
      in <a href="#1">Job #1</a>
      </details>
      
      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 700 if the account is XYZ in spec.models.account_spec</code></summary>
      
      <code><pre>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)
      
        expected: 700
             got: 500
      
        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in <top (required)>'
      ./spec/support/database.rb:16:in `block (2 levels) in <top (required)>'
      ./spec/support/log.rb:17:in `run'
      ./spec/support/log.rb:66:in `block (2 levels) in <top (required)>'</pre></code>
      
      in <a href="#3">Job #3</a>
      </details>

      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 250 by default in spec.models.account_spec</code></summary>
      
      <code><pre>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)
      
        expected: 250
             got: 500
      
        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in <top (required)>'
      ./spec/support/database.rb:16:in `block (2 levels) in <top (required)>'
      ./spec/support/log.rb:17:in `run'
      ./spec/support/log.rb:66:in `block (2 levels) in <top (required)>'</pre></code>
      
      in <a href="#3">Job #3</a>
      </details>
      
      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 700 if the account is XYZ in spec.models.account_spec</code></summary>
      
      <code><pre>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)
      
        expected: 700
             got: 500
      
        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in <top (required)>'
      ./spec/support/database.rb:16:in `block (2 levels) in <top (required)>'
      ./spec/support/log.rb:17:in `run'
      ./spec/support/log.rb:66:in `block (2 levels) in <top (required)>'</pre></code>
      
      in <a href="#2">Job #2</a>
      </details>
    OUTPUT

    assert_equal 0, status.exitstatus
  end

  it "accepts custom regex filename patterns for job id" do
    output, status = Open3.capture2e("env", "BUILDKITE_PLUGIN_JUNIT_ANNOTATE_JOB_UUID_FILE_PATTERN=junit-(.*)-custom-pattern.xml", "#{__dir__}/../bin/annotate", "#{__dir__}/custom-job-uuid-pattern/")

    assert_equal <<~OUTPUT, output
      Parsing junit-123-456-custom-pattern.xml
      --- ❓ Checking failures
      There is 1 failure/error 😭
      --- ✍️ Preparing annotation
      1 failure:
      
      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 250 by default in spec.models.account_spec</code></summary>
      
      <code><pre>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)
      
        expected: 250
             got: 500
      
        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in <top (required)>'
      ./spec/support/database.rb:16:in `block (2 levels) in <top (required)>'
      ./spec/support/log.rb:17:in `run'
      ./spec/support/log.rb:66:in `block (2 levels) in <top (required)>'</pre></code>
      
      in <a href="#123-456">Job #123-456</a>
      </details>
    OUTPUT

    assert_equal 0, status.exitstatus
  end

  it "handles failures across multiple files in sub dirs" do
    output, status = Open3.capture2e("#{__dir__}/../bin/annotate", "#{__dir__}/tests-in-sub-dirs/")

    assert_equal <<~OUTPUT, output
      Parsing sub-dir/junit-1.xml
      Parsing sub-dir/junit-3.xml
      Parsing sub-dir/junit-2.xml
      --- ❓ Checking failures
      There are 4 failures/errors 😭
      --- ✍️ Preparing annotation
      4 failures:
      
      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 250 by default in spec.models.account_spec</code></summary>
      
      <code><pre>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)
      
        expected: 250
             got: 500
      
        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in <top (required)>'
      ./spec/support/database.rb:16:in `block (2 levels) in <top (required)>'
      ./spec/support/log.rb:17:in `run'
      ./spec/support/log.rb:66:in `block (2 levels) in <top (required)>'</pre></code>
      
      in <a href="#1">Job #1</a>
      </details>
      
      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 700 if the account is XYZ in spec.models.account_spec</code></summary>
      
      <code><pre>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)
      
        expected: 700
             got: 500
      
        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in <top (required)>'
      ./spec/support/database.rb:16:in `block (2 levels) in <top (required)>'
      ./spec/support/log.rb:17:in `run'
      ./spec/support/log.rb:66:in `block (2 levels) in <top (required)>'</pre></code>
      
      in <a href="#3">Job #3</a>
      </details>

      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 250 by default in spec.models.account_spec</code></summary>
      
      <code><pre>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)
      
        expected: 250
             got: 500
      
        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in <top (required)>'
      ./spec/support/database.rb:16:in `block (2 levels) in <top (required)>'
      ./spec/support/log.rb:17:in `run'
      ./spec/support/log.rb:66:in `block (2 levels) in <top (required)>'</pre></code>
      
      in <a href="#3">Job #3</a>
      </details>
      
      <details>
      <summary><code>Account#maximum_jobs_added_by_pipeline_changer returns 700 if the account is XYZ in spec.models.account_spec</code></summary>
      
      <code><pre>Failure/Error: expect(account.maximum_jobs_added_by_pipeline_changer).to eql(250)
      
        expected: 700
             got: 500
      
        (compared using eql?)
      ./spec/models/account_spec.rb:78:in `block (3 levels) in <top (required)>'
      ./spec/support/database.rb:16:in `block (2 levels) in <top (required)>'
      ./spec/support/log.rb:17:in `run'
      ./spec/support/log.rb:66:in `block (2 levels) in <top (required)>'</pre></code>
      
      in <a href="#2">Job #2</a>
      </details>
    OUTPUT

    assert_equal 0, status.exitstatus
  end
end
