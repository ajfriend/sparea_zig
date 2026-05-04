default:
    @just --list

# Build, run tests under kcov, fail if line coverage isn't 100%.
test:
    zig build install-test
    rm -rf coverage
    kcov --include-pattern=src/ coverage zig-out/bin/sparea-test
    @jq -r '"sparea coverage: \(.percent_covered)%"' coverage/sparea-test.*/coverage.json
    @jq -e '.percent_covered == "100.00"' coverage/sparea-test.*/coverage.json > /dev/null

# Build the library.
build:
    zig build

# Run `just test` and print where the HTML coverage report landed.
coverage: test
    @echo "open coverage/sparea-test/index.html"

# Remove build artifacts.
clean:
    rm -rf zig-out .zig-cache coverage
