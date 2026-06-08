# Testing & CI/CD Guide

This guide explains the testing framework, integration tests, and GitHub Actions CI/CD pipeline for your OS kernel project.

---

## Overview

Your project now includes three levels of automated testing:

1. **Unit Tests** - Test individual components in isolation
2. **Integration Tests** - Test kernel boot and behavior in QEMU
3. **CI/CD Pipeline** - Automated testing on every push and pull request

---

## 1. Unit Testing Framework

### Architecture

The unit test framework (`test_framework.h` and `test_framework.c`) provides:
- Test registration via decorators
- Assertion macros for validation
- Pass/fail result tracking
- Colored output for easy reading

### Key Files

```
tests/
├── test_framework.h      # Test framework header
├── test_framework.c      # Test framework implementation
├── test_print.c          # Example unit tests for print module
└── Makefile              # Test build configuration
```

### Writing Unit Tests

#### Basic Test Structure

```c
#include "test_framework.h"

/* Define a test */
TEST(my_test_name) {
    /* Arrange - set up test conditions */
    int result = calculate_something();

    /* Act - already done above

    /* Assert - verify results */
    ASSERT_EQUAL(result, expected_value);
}

int main() {
    RUN_TESTS();
    return get_tests_failed() == 0 ? 0 : 1;
}
```

#### Available Assertions

```c
/* Basic assertion */
ASSERT(condition, "Error message if fails");

/* Value comparisons */
ASSERT_EQUAL(actual, expected);        /* Assert equal */
ASSERT_NOT_EQUAL(value1, value2);      /* Assert not equal */

/* Pointer checks */
ASSERT_NULL(ptr);                      /* Assert pointer is NULL */
ASSERT_NOT_NULL(ptr);                  /* Assert pointer is not NULL */

/* Memory comparison */
ASSERT_MEM_EQUAL(actual, expected, size);  /* Compare memory regions */
```

### Building and Running Tests

#### Option 1: Individual Test File

```bash
# Build test
gcc -o test_print test_framework.c test_print.c -Wall -Wextra

# Run test
./test_print
```

#### Option 2: Using Make (recommended)

```bash
# Build all tests
make -C tests/

# Run tests
make -C tests/ test

# Clean test artifacts
make -C tests/ clean
```

### Example Output

```
================================================================================
Running 12 tests...
================================================================================

✓ PASS: color_encoding
✓ PASS: color_with_background
✓ PASS: buffer_offset_calculation
✓ PASS: cursor_boundaries
✓ PASS: newline_character_detection
✓ PASS: string_null_termination
✓ PASS: char_to_byte_conversion
✓ PASS: extended_ascii_characters
✓ PASS: row_scrolling_calculation
✓ PASS: loop_iteration_count
✓ PASS: struct_write_simulation
✓ PASS: multiple_color_combinations

================================================================================
Test Results: 12 passed, 0 failed out of 12 total
================================================================================
```

### Creating Tests for Your Code

Follow this pattern for testing kernel components:

```c
// test_memory.c - Test memory allocator
#include "test_framework.h"
#include "memory.h"

TEST(allocate_memory) {
    void *ptr = malloc(64);
    ASSERT_NOT_NULL(ptr);
    free(ptr);
}

TEST(allocate_zero_bytes) {
    void *ptr = malloc(0);
    ASSERT_NULL(ptr);
}

TEST(allocate_and_deallocate) {
    void *ptrs[10];
    for (int i = 0; i < 10; i++) {
        ptrs[i] = malloc(256);
        ASSERT_NOT_NULL(ptrs[i]);
    }
    for (int i = 0; i < 10; i++) {
        free(ptrs[i]);
    }
}

int main() {
    RUN_TESTS();
    return get_tests_failed() == 0 ? 0 : 1;
}
```

---

## 2. Integration Tests with QEMU

### Overview

Integration tests verify that the entire kernel boots and functions correctly in QEMU emulation. The `integration_test.sh` script:

1. Builds the kernel
2. Runs it in QEMU
3. Captures output
4. Validates boot messages
5. Reports results

### Running Integration Tests

#### Option 1: Direct Execution

```bash
# Make script executable (first time only)
chmod +x scripts/integration_test.sh

# Run with default settings (10 second timeout)
./scripts/integration_test.sh

# Run with verbose output
./scripts/integration_test.sh --verbose

# Set custom timeout (20 seconds)
./scripts/integration_test.sh --timeout 20

# Only build, don't test
./scripts/integration_test.sh --build-only

# Only run tests (don't rebuild)
./scripts/integration_test.sh --run-only
```

#### Option 2: Using Make

```bash
# Run integration tests
make integration-test

# Run with verbose output
make integration-test VERBOSE=1
```

### Understanding Test Output

```
Test: Boot in QEMU
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Running QEMU with 10 second timeout...
✓ PASS: Kernel boot message detected
✓ PASS: No error messages detected

Test: QEMU Termination
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ PASS: QEMU exited without crashing

Integration Test Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Boot Test
✓ Error Detection Test
✓ QEMU Exit Test
Result: 3/3 tests passed
```

### Troubleshooting Integration Tests

#### QEMU Not Found

```bash
# Install QEMU
sudo apt-get install qemu-system-x86
```

#### Timeout

If tests timeout, increase the timeout:
```bash
./scripts/integration_test.sh --timeout 30
```

#### No Boot Message

Check QEMU output:
```bash
# Manually run kernel in QEMU
qemu-system-x86_64 -cdrom dist/x86_64/kernel.iso -serial stdio
```

---

## 3. GitHub Actions CI/CD Pipeline

### Overview

The GitHub Actions workflow (`.github/workflows/build_and_test.yml`) automatically:
- **Builds** the kernel on every push and pull request
- **Runs unit tests** to verify component functionality
- **Runs integration tests** with QEMU to verify full system boot
- **Uploads artifacts** for debugging
- **Reports results** with pass/fail status

### Setting Up CI/CD

#### Step 1: Create Workflow Directory

```bash
mkdir -p .github/workflows
```

#### Step 2: Add Workflow File

Copy `build_and_test.yml` to `.github/workflows/build_and_test.yml`

#### Step 3: Commit and Push

```bash
git add .github/workflows/build_and_test.yml
git commit -m "Add GitHub Actions CI/CD pipeline"
git push
```

#### Step 4: Verify in GitHub

1. Go to your GitHub repository
2. Click **Actions** tab
3. You should see "Build & Test" workflow running
4. Click the workflow to see details

### Workflow Structure

The workflow has 4 jobs that run in sequence:

```
┌─────────────────────┐
│  build              │ (Compile kernel)
└──────────┬──────────┘
           │
      ┌────┴────┐
      │         │
      ▼         ▼
┌──────────┐ ┌──────────────┐
│ test-    │ │ test-        │
│ unit     │ │ integration  │
└──────────┘ └──────────────┘
      │          │
      └────┬─────┘
           │
      ┌────▼──────────┐
      │ quality       │ (Code quality checks)
      └───────────────┘
```

### GitHub UI Features

**Actions Tab:**
- View all workflow runs
- See build status (✓ passed or ✗ failed)
- Review logs for each job
- Download artifacts

**Pull Requests:**
- See CI status check before merge
- Prevent merge if tests fail

**Commits:**
- View CI status in commit history
- Click status badge for details

### Example Workflow Run

```
✓ build (successful)
  - Install dependencies: 30s
  - Build kernel: 45s
  - Upload artifacts: 10s

✓ test-unit (successful)
  - Download artifacts: 5s
  - Build unit tests: 15s
  - Run unit tests: 8s

✓ test-integration (successful)
  - Download artifacts: 5s
  - Run QEMU boot test: 12s

✓ quality (successful)
  - Code formatting check: 10s
  - Static analysis: 20s

Total: ~150 seconds (2.5 minutes)
```

### Customizing the Workflow

#### Change Trigger Branches

Edit `.github/workflows/build_and_test.yml`:

```yaml
on:
  push:
    branches: [ main, develop, feature/* ]  # Add branches
  pull_request:
    branches: [ main ]
```

#### Add More Jobs

Add a new job for additional testing:

```yaml
test-memory:
  name: Memory Tests
  runs-on: ubuntu-latest
  needs: build
  steps:
    - run: ./scripts/test_memory.sh
```

#### Add Status Badges

Add to your README.md:

```markdown
![Build Status](https://github.com/username/repo/workflows/Build%20%26%20Test/badge.svg)
```

#### Notifications

Configure email or Slack notifications (see commented section in workflow file).

---

## 4. Local Testing Workflow

### Complete Local Test Suite

```bash
# 1. Build kernel
make build-x86_64

# 2. Run unit tests
make -C tests/ test

# 3. Run integration tests
./scripts/integration_test.sh --verbose

# 4. Clean up
make clean
```

### Makefile Integration

Add these targets to your Makefile:

```makefile
.PHONY: test test-unit test-integration

test: test-unit test-integration
	@echo "All tests completed"

test-unit:
	@cd tests && make test

test-integration: build-x86_64
	@./scripts/integration_test.sh
```

### Continuous Testing During Development

```bash
# Watch for changes and re-run tests
watch -n 5 'make test'

# Or use entr (install with: apt-get install entr)
find src/ -name "*.c" -o -name "*.h" | entr -c make test
```

---

## 5. Best Practices

### Unit Test Guidelines

✅ **DO:**
- Test one thing per test
- Use descriptive test names
- Test edge cases and boundaries
- Test error conditions
- Keep tests independent

❌ **DON'T:**
- Test implementation details
- Create dependencies between tests
- Use hardcoded values
- Ignore test failures

### Integration Test Guidelines

✅ **DO:**
- Test complete features
- Verify expected output
- Check error handling
- Test on different hardware (in CI)
- Document test expectations

❌ **DON'T:**
- Overlap with unit tests
- Test third-party code
- Have flaky tests (timing-dependent)
- Require manual intervention

### CI/CD Best Practices

✅ **DO:**
- Run tests on every push
- Require passing tests before merge
- Keep test suite fast (<5 minutes)
- Archive artifacts for debugging
- Use semantic commit messages

❌ **DON'T:**
- Commit failing tests
- Disable failing tests without fixing
- Ignore CI failures
- Skip tests for small changes

---

## 6. Troubleshooting

### Unit Tests Won't Compile

```bash
# Check for missing includes
gcc -I. -c test_framework.c

# Check for missing dependencies
pkg-config --cflags --libs check
```

### Integration Tests Fail

```bash
# Check QEMU is installed
which qemu-system-x86_64

# Run QEMU manually to debug
qemu-system-x86_64 -cdrom dist/x86_64/kernel.iso -serial stdio

# Check kernel.iso exists
ls -lh dist/x86_64/kernel.iso
```

### GitHub Actions Failures

1. Check workflow logs in GitHub Actions tab
2. Download artifact logs for details
3. Re-run job with debug enabled
4. Check environment variables and paths

---

## 7. Next Steps

### Immediate

- [ ] Copy test files to your project
- [ ] Run `make -C tests/ test` to verify setup
- [ ] Run `./scripts/integration_test.sh` to test boot
- [ ] Commit files to git

### Short Term

- [ ] Add tests for your memory manager
- [ ] Add tests for interrupt handlers
- [ ] Expand integration tests
- [ ] Set up GitHub Actions

### Long Term

- [ ] Increase test coverage to >80%
- [ ] Add performance benchmarks
- [ ] Set up test coverage tracking
- [ ] Add code quality gates

---

## Reference

### Test Framework API

```c
TEST(name)                              // Define test
ASSERT(cond, msg)                      // Assert condition
ASSERT_EQUAL(actual, expected)         // Assert equality
ASSERT_NOT_EQUAL(val1, val2)           // Assert inequality
ASSERT_NULL(ptr)                       // Assert NULL
ASSERT_NOT_NULL(ptr)                   // Assert not NULL
ASSERT_MEM_EQUAL(a, e, size)           // Assert memory equal
RUN_TESTS()                            // Execute all tests
print_test_report()                    // Print detailed report
get_tests_passed()                     // Get pass count
get_tests_failed()                     // Get fail count
```

### Integration Test Script Usage

```bash
./integration_test.sh [OPTIONS]

Options:
  -h, --help       Show help
  -v, --verbose    Verbose output
  -t, --timeout N  Set timeout to N seconds
  -b, --build-only Build without testing
  -r, --run-only   Test without building
```

### GitHub Actions Variables

```yaml
github.sha              # Current commit hash
github.ref              # Branch or tag
github.event_name       # Trigger event type
runner.os               # Operating system
```

