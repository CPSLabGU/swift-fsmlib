# Tests

The test targets `FSMTests` and `FSMEcoreTests` run with `swift test`. Most
tests need nothing beyond the Swift toolchain; the tests described below
also use external tools or environment variables.

## Command-Line Tool

`CLIIntegrationTests` builds `fsmconvert` with `swift build` and runs it.
By default it builds into a scratch directory of its own, which resolves
the package dependencies independently of the test run. To build the tool
against the same dependency checkouts as the tests, for example while
dependencies are in edit mode, name the scratch directory of the test run
in `FSMCONVERT_BUILD_PATH`:

```bash
FSMCONVERT_BUILD_PATH=.build swift test --scratch-path .build
```

The value must be the scratch directory of the test run itself: the tool is
then built there while the tests execute.

## Kernel Targets

The tests of the kernel template sets in `FSMEcoreTests/Kernel` compare the
generated files with the checked-in files under
`Tests/FSMEcoreTests/Resources/Kernel/expected/<target>`, compile and run
the generated programs, and check the generated verification models.

| tests | tools | skipped when |
|---|---|---|
| C programs | `cc` on the search path | `cc` is not found |
| C++ programs | `c++` | `c++` is not found |
| Swift programs | `swiftc` | `swiftc` is not found |
| Java programs | `javac` and `java` | either is not found |
| smv models | `nuXmv`, or else `NuSMV` | neither is found |
| tla specifications | `java` and `tla2tools.jar` | the archive is not named by `TLA2TOOLS_JAR` and is not on the search path |

Skipped tests say which tool is missing. The programs are compiled with
`-std=c11 -Wall -Wextra -Werror`, `-std=c++20 -Wall -Wextra -Werror
-pedantic`, `-swift-version 6 -parse-as-library -warnings-as-errors` and
`--release 17 -Xlint:all -Werror`, run for as many rounds as the expected
trace `Resources/Kernel/expected/<model>.trace` covers, with the inputs file
`Resources/Kernel/inputs/<model>.inputs` of an open model, and must print
that trace byte for byte. Each expected trace is derived by hand from the
kernel semantics; the derivation is in the `.trace.md` file next to it.

## WebAssembly

The tests also run on WebAssembly (WASI) with the Swift 6.4 toolchain, the
WebAssembly Swift SDK `swift-6.4.0-RELEASE_wasm` and a WASI runtime, such
as `wasmkit`, which the toolchain includes, or `wasmtime`. Only Swift
Testing runs there: the XCTest cases of `FSMTests` and `FSMEcoreTests` are
not run. Build the tests with the native build system:

```bash
swift build -c release --build-system native --build-tests --disable-xctest \
  --swift-sdk swift-6.4.0-RELEASE_wasm -Xswiftc -enable-testing \
  -Xlinker -z -Xlinker stack-size=8388608
```

Name the runner in a toolset file, for example `wasm-toolset.json`, and give
it access to the temporary directory and to the package directory, which
holds the build products, the test resources and the examples:

```json
{
  "schemaVersion": "1.0",
  "testRunner": {
    "path": "/path/to/wasmkit",
    "extraCLIOptions": ["run", "--stack-size", "67108864",
                        "--dir", "/tmp", "--dir", "/path/to/swift-fsmlib"]
  }
}
```

`wasmtime` passes only the file name of the test module, so it also needs the
directory of the build products as the root directory of the guest, where
the resource directories of the test targets are found:

```json
"extraCLIOptions": ["run", "-W", "max-wasm-stack=67108864",
                    "--dir", "/path/to/swift-fsmlib/.build/wasm32-unknown-wasip1/release::/",
                    "--dir", "/tmp", "--dir", "/path/to/swift-fsmlib"]
```

Then run the tests one after the other:

```bash
swift test -c release --build-system native --skip-build --disable-xctest \
  --no-parallel --toolset wasm-toolset.json \
  --swift-sdk swift-6.4.0-RELEASE_wasm
```

WASI cannot start other processes, so these tests do not run there:

| tests | on WASI |
|---|---|
| `CLIIntegrationTests` and `CLIPipelineTests`, which run `fsmconvert` | not compiled |
| C, C++, Swift and Java programs, smv models and tla specifications | skipped, as no tool is found |

The check that formats an integer beyond the precision of a `Double` is
left out on WASI as well, where `Int` holds 32 bits.

## Recording Expected Files

| variable | effect |
|---|---|
| `FSMECORE_RECORD_KERNEL_GOLDEN` | rewrites the expected files of the kernel template sets from the current templates |
| `FSMECORE_REGENERATE_FIXTURES` | rewrites the kernel, sectioned and host-language fixture documents from their builders |

Review the differences before committing recorded files, and record the
expected traces by hand, never from generated programs.
