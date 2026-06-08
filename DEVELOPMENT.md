# Development Guide

Welcome to the OS kernel development community! This guide explains how to contribute to the project.

---

## Getting Started

### Prerequisites

```bash
# Install required tools
make install-deps

# Verify installation
gcc --version
nasm -version
qemu-system-x86_64 --version
```

### First Build

```bash
# Clone the repository
git clone https://github.com/mozartrombocks/Writing-an-operating-system-kernel-from-scratch.git
cd Writing-an-operating-system-kernel-from-scratch

# Build the kernel
make build-x86_64

# Test it
make emulate

# Debug it
make debug
```

---

## Development Workflow

### 1. Choose What to Work On

**Options:**
1. Pick an open issue: Check GitHub Issues
2. Choose from FEATURES.md roadmap
3. Propose a new feature: Create an issue

### 2. Create a Feature Branch

```bash
# Update main
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/my-feature-name

# Or for bug fixes
git checkout -b bugfix/issue-number
```

**Branch Naming:**
- `feature/keyboard-driver` - New feature
- `bugfix/memory-leak` - Bug fix
- `docs/update-readme` - Documentation
- `test/add-heap-tests` - Testing

### 3. Make Changes

```bash
# Edit files
vim src/impl/kernel/main.c

# Compile frequently
make build-x86_64

# Test frequently
make test
make emulate

# View logs
make debug
```

**Code Standards:**

✅ **DO:**
- Follow existing code style
- Add comments for complex logic
- Include function documentation
- Keep functions focused (do one thing)
- Test your changes

❌ **DON'T:**
- Ignore compiler warnings
- Commit debug code (printfs, etc.)
- Leave TODO comments without issues
- Break existing functionality

### 4. Commit Changes

```bash
# Stage changes
git add src/impl/kernel/

# Commit with good message
git commit -m "Add keyboard driver implementation

- Implement PS/2 keyboard scan code handling
- Add key buffer for key event storage
- Support Shift modifier key
- Handle edge cases in scan codes
- Fixes #123"
```

**Commit Message Format:**
```
One-line summary (50 characters max)

Detailed explanation of changes:
- What was changed
- Why it was changed
- How it was tested
- Related issues: Fixes #123, Relates to #456
```

### 5. Update Documentation

```bash
# Update CHANGELOG.md
vim CHANGELOG.md
# Add your changes to [Unreleased] section

# Update FEATURES.md if adding/completing features
vim FEATURES.md

# Update code documentation
vim src/impl/kernel/main.c
# Add/update function comments
```

### 6. Test Thoroughly

```bash
# Unit tests
make test-unit

# Integration tests
make test-integration

# Manual testing
make emulate

# Debug testing
make debug

# All tests
make test
```

### 7. Push and Create Pull Request

```bash
# Push feature branch
git push origin feature/my-feature-name

# Create PR on GitHub
# - Add description
# - Link related issues
# - Request reviewers
# - Add labels (enhancement, bugfix, etc.)
```

### 8. Address Feedback

```bash
# Make requested changes
vim src/impl/kernel/main.c

# Commit changes
git commit -m "Address review feedback

- Simplify algorithm as suggested
- Add additional error handling
- Update documentation"

# Push updated changes
git push origin feature/my-feature-name
# (PR auto-updates)
```

### 9. Merge and Release

Once PR is approved:

```bash
# Merge is done on GitHub (maintainer)
# Then locally:

git checkout main
git pull origin main

# For release, update version:
vim CHANGELOG.md
# Add new [x.x.x] section

git tag -a vx.x.x -m "Release version x.x.x"
git push origin main
git push origin vx.x.x
```

---

## Code Style Guide

### Naming Conventions

**Variables:**
```c
// Snake case for variables
int page_table_size;
uint8_t color_value;
char *kernel_name;
```

**Functions:**
```c
// Snake case for functions
void print_clear(void);
int allocate_memory(size_t size);
uint64_t calculate_offset(size_t row, size_t col);
```

**Macros:**
```c
// Upper case for macros
#define MAX_PAGES 512
#define PAGE_SIZE 4096
#define COLOR_RED 0x04
```

**Types:**
```c
// Snake case with _t suffix
typedef struct {
    uint8_t character;
    uint8_t color;
} char_t;

typedef struct {
    uint32_t flags;
    uint64_t address;
} page_entry_t;
```

### File Organization

**Headers (.h):**
```c
/**
 * @file print.h
 * @brief Module description
 */

#pragma once

#include <stdint.h>

/* Public interface only */
void print_char(char c);
void print_str(const char *str);
```

**Implementation (.c):**
```c
/**
 * @file print.c
 * @brief Module implementation
 */

#include "print.h"

/* Private helper functions */
static void scroll_display(void) {
    // ...
}

/* Public functions */
void print_char(char c) {
    // ...
}
```

### Comments

**Function Documentation:**
```c
/**
 * @brief Brief description
 *
 * Longer description explaining what the function does,
 * why it exists, and how to use it.
 *
 * @param param1  Description of first parameter
 * @param param2  Description of second parameter
 * @return Description of return value
 *
 * @note Important notes or caveats
 * @warning Potential pitfalls
 */
void my_function(int param1, int param2) {
```

**Inline Comments:**
```c
// Explain WHY, not WHAT
for (size_t i = 0; i < 512; i++) {
    // Map each 2MB region in the page directory
    page_table[i] = (i * 0x200000) | PAGE_FLAGS;
}
```

### Formatting

**Line Length:** 80-100 characters max

**Indentation:** 4 spaces (use spaces, not tabs)

**Braces:**
```c
// Opening brace on same line
if (condition) {
    // body
}

// Exception: function definitions
void my_function(void)
{
    // body
}
```

**Spacing:**
```c
// Space after keywords
if (x > 0) {
}

// Space around operators
int result = a + b;

// No space in function calls
print_str("Hello");
```

---

## Testing Requirements

### Unit Tests

Every module should have unit tests:

```c
// tests/test_print.c
#include "test_framework.h"
#include "print.h"

TEST(print_char_basic) {
    // Arrange: Set up test conditions
    char input = 'A';
    
    // Act: Execute function
    print_char(input);
    
    // Assert: Verify results
    ASSERT_EQUAL(buffer[0].character, 'A');
}
```

### Integration Tests

Test complete features in QEMU:

```bash
# Run integration tests
./scripts/integration_test.sh

# Or via make
make test-integration
```

### Coverage Goals

- **Minimum:** 60% code coverage
- **Target:** 80%+ code coverage
- **Stretch:** 90%+ code coverage

Check coverage:
```bash
make coverage
# Open coverage/index.html in browser
```

---

## Documentation Requirements

### For Every Feature

1. **Code Comments** - Explain complex logic
2. **Function Documentation** - Doxygen format
3. **README section** - Quick usage guide
4. **FEATURES.md** - Mark as complete
5. **CHANGELOG.md** - Document changes

### For Every Module

1. **Module header** - Purpose and overview
2. **Data structures** - Field documentation
3. **Public API** - All public functions documented
4. **Examples** - Usage examples if applicable

---

## Performance Considerations

### When to Optimize

1. **Never** - Before it's needed
2. **Measure** - Use profiling tools
3. **Profile** - Find bottlenecks
4. **Improve** - Make targeted changes
5. **Verify** - Confirm improvement

### Optimization Tools

```bash
# GDB for profiling
make debug
(gdb) profile on
(gdb) profile off
(gdb) info profile

# QEMU for performance analysis
qemu-system-x86_64 -d trace:qemu_exec
```

---

## Common Tasks

### Adding a New Driver

```bash
# 1. Create driver file
touch src/impl/x86_64/drivers/keyboard.c
touch src/intf/keyboard.h

# 2. Implement driver
vim src/impl/x86_64/drivers/keyboard.c
vim src/intf/keyboard.h

# 3. Add to build system
# Edit Makefile to include driver

# 4. Write tests
vim tests/test_keyboard.c

# 5. Document
vim FEATURES.md
vim CHANGELOG.md

# 6. Commit
git add -A
git commit -m "Add keyboard driver"
```

### Fixing a Bug

```bash
# 1. Create issue if not exists
# GitHub: New Issue

# 2. Create branch
git checkout -b bugfix/issue-123

# 3. Reproduce bug
make debug
# Set breakpoint, debug

# 4. Fix bug
vim src/impl/kernel/main.c

# 5. Add regression test
vim tests/test_*.c

# 6. Verify fix
make test
make emulate

# 7. Commit
git commit -m "Fix bug: Description (fixes #123)"

# 8. Create PR
git push origin bugfix/issue-123
```

### Refactoring Code

```bash
# 1. Create branch
git checkout -b refactor/memory-manager

# 2. Refactor with tests passing
make test
# ... make changes ...
make test
# Ensure tests still pass!

# 3. Commit refactoring
git commit -m "Refactor: Improve memory manager readability

- Split large function into smaller ones
- Improve variable names
- Add more comprehensive comments
- All tests passing"
```

---

## Review Process

### What Reviewers Look For

✅ **Good:**
- Code follows style guide
- Tests included and passing
- Documentation updated
- Commits are atomic
- Message clearly explains changes
- No compiler warnings

❌ **Issues:**
- Ignoring existing code style
- No tests for new functionality
- Outdated documentation
- Breaking changes not noted
- Risky or unclear code

### Being a Good Reviewer

1. **Be constructive** - Offer suggestions, not criticism
2. **Be thorough** - Check logic, tests, docs
3. **Be timely** - Review within 24 hours
4. **Be clear** - Explain concerns well
5. **Approve** - Say "Approved" or "Approved with comments"

---

## Troubleshooting

### Build Fails

```bash
# Clean everything and rebuild
make distclean
make build-x86_64

# Check for warnings
VERBOSE=1 make build-x86_64

# Check configuration
make show-config
```

### Test Failures

```bash
# Run specific test
cd tests/
./test_print

# Debug test
gdb ./test_print
(gdb) run
(gdb) bt  # See backtrace

# Verbose output
./scripts/integration_test.sh --verbose
```

### Git Issues

```bash
# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# Fix commit message
git commit --amend

# Combine commits
git rebase -i HEAD~3
# Mark later commits as 'squash'

# See what changed
git diff
git diff --staged
```

---

## Resources

- [FEATURES.md](FEATURES.md) - Roadmap and planned features
- [CHANGELOG.md](CHANGELOG.md) - Version history
- [ARCHITECTURE.md](ARCHITECTURE.md) - Technical architecture
- [DEBUGGING.md](DEBUGGING.md) - Debugging guide
- [TESTING_GUIDE.md](TESTING_GUIDE.md) - Testing documentation
- [DEVELOPMENT_WORKFLOW.md](DEVELOPMENT_WORKFLOW.md) - Build and git workflow

---

## Code of Conduct

This project follows a simple code of conduct:

1. **Be respectful** - Treat others with courtesy
2. **Be helpful** - Help others learn and contribute
3. **Be honest** - Give and accept feedback openly
4. **Be inclusive** - Welcome all contributors
5. **Be professional** - Keep discussions on-topic

---

## Questions?

- Check existing documentation
- Search existing issues
- Ask in a new GitHub discussion
- Contact maintainers

Thank you for contributing! 🎉
