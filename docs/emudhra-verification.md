# Ruby image trust verification

The default Ruby image is pinned to:

```text
ruby:4.0.9-alpine@sha256:d0c5befc0864d31c6219321c8d79de2941d1bc31c41505d9c9289c6192c36d60
```

On 28 October 2026, the Linux AMD64 and ARM64 images were tested against the
[eMudhra incident](https://emudhra.we-have-a-problem.com/) certificate chains.
Both contain Ruby 4.0.9, Alpine 3.24.3, OpenSSL 3.5.9, and
`ca-certificates-bundle-20261020-r0`. Ruby's default certificate file is
`/etc/ssl/cert.pem`.

## Results

Both tested architectures rejected all 14 chains from the incident site's
[`chains.zip`](https://emudhra.we-have-a-problem.com/chains.zip), including the
AAA Certificate Services cross-signs and both non-CT examples. Verification
used Ruby's `OpenSSL::X509::Store` with `set_default_paths`, with the supplied
intermediates passed as untrusted certificates. Every chain failed with error
20, `unable to get local issuer certificate`. The certificates were within
their validity periods, so expiry was not responsible for rejection.

Ruby `Net::HTTP` also rejected all 14 corresponding HTTPS endpoints with
`certificate verify failed (unable to get local issuer certificate)`. Control
requests to `https://emudhra.we-have-a-problem.com/` and
`https://buildkite.com/` succeeded with HTTP 200 and 302 respectively. The tests
used the unmodified images, without installing packages or changing trust
settings, and explicitly disabled HTTP proxy discovery.

The parser suite passed on both architectures with 13 tests and 39 assertions.
The shell plugin suite passed all 22 tests.

The tested platform manifests are:

| Platform | Manifest digest |
| --- | --- |
| Linux AMD64 | `sha256:5a78b7bf435783dd06cf017d467c1e09e67ab6f2d87ecafc23ffab7a762ebca4` |
| Linux ARM64 | `sha256:f4fb897c30ab255705cc298669e83123202683898eedf7e0cec039cc2d13ac11` |

Other architectures in the pinned index were not executed. The explicit
`4.0.9-alpine` index was selected instead of the floating `4.0-alpine` index,
which also contained an older RISC-V image when inspected.

## Reproducing the offline check

Download and extract the incident site's `chains.zip` into a temporary
directory. The archive tested had SHA-256
`7b949956955fc501a30f4d98d2f513d34c0bbbe92e29a968194c96e097ce2345`.
With that directory mounted at `/verification`, run this Ruby code inside the
pinned image:

```ruby
require 'openssl'

store = OpenSSL::X509::Store.new
store.set_default_paths
Dir['/verification/chains/*.pem'].sort.each do |path|
  certs = File.read(path).scan(
    /-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----/m
  ).map { |pem| OpenSSL::X509::Certificate.new(pem) }
  abort "Certificate outside validity period: #{path}" unless certs.all? {
    |cert| cert.not_before <= Time.now && Time.now <= cert.not_after
  }
  leaf, *chain = certs
  accepted = store.verify(leaf, chain)
  puts "#{File.basename(path)}: #{accepted}, #{store.error_string}"
  abort "Unexpected verification result: #{path}" if accepted || store.error != 20
end
```

## Scope

The parser currently reads local JUnit files and does not make TLS connections.
This pin provides defense in depth if future code uses Ruby's default TLS trust
store. It does not cover custom images, custom CA bundles, or independent TLS
libraries. Artifact transfers and annotation uploads use the host's Buildkite
agent, and image pulls use Docker's infrastructure. Operators must maintain
those clients and their effective trust stores separately.
