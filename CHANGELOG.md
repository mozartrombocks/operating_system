# Changelog

All notable changes to this OS kernel project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Versioning Scheme

- **MAJOR** (x.0.0) - Breaking changes or major features (bootloader changes, memory layout changes)
- **MINOR** (0.x.0) - New features added in backward-compatible manner (new drivers, new syscalls)
- **PATCH** (0.0.x) - Bug fixes and documentation updates

## [Unreleased]

### Planned Features
- [ ] Keyboard input (PS/2 driver)
- [ ] Disk I/O and filesystem support
- [ ] Process management and task switching
- [ ] Virtual memory improvements (full paging)
- [ ] System calls interface
- [ ] Memory profiling and leak detection
- [ ] Stack canaries for buffer overflow detection
- [ ] Serial port debugging enhancements
- [ ] ARM64 architecture support

### In Progress
- [ ] Testing framework (unit tests, integration tests)
- [ ] CI/CD pipeline (GitHub Actions)

## [0.1.0] - 2026-06-08

### Added
- Initial 64-bit OS kernel skeleton
- 32-bit bootloader stage with CPU capability detection
  - Multiboot2 specification compliance checking
  - CPUID support verification
  - Long mode (64-bit) support detection
- 64-bit kernel initialization
  - GDT (Global Descriptor Table) setup
  - Paging support (4-level page tables, 2MB huge pages)
  - PAE (Physical Address Extension) enable
- VGA text mode output (80x25)
  - Character and string printing
  - Color support (16 colors)
  - Screen clearing and scrolling
  - Cursor management
- Comprehensive documentation
  - Code inline comments and function documentation (Doxygen-compatible)
  - Architecture diagrams showing boot flow and memory layout
  - Before/after improvement examples
- Unit testing framework
  - Test registration and execution
  - Assertion macros (ASSERT_EQUAL, ASSERT_NOT_NULL, etc.)
  - Example tests for print module
- Integration testing with QEMU
  - Automated boot verification
  - Kernel output validation
  - Multi-test reporting
- GitHub Actions CI/CD pipeline
  - Automatic build on push/PR
  - Unit test execution
  - Integration test with QEMU
  - Build artifact storage
- Professional build system (Makefile)
  - 20+ targets (build, test, debug, clean, etc.)
  - Strict compiler flags (-Wall -Wextra -Werror)
  - Debug and verbose modes
  - Target help system
- Git configuration
  - Comprehensive .gitignore
  - 148 patterns for artifact exclusion
  - IDE and system file filtering
- Development documentation
  - DEVELOPMENT_WORKFLOW.md
  - TESTING_GUIDE.md
  - DOCUMENTATION_GUIDE.md
  - IMPROVEMENT_SUGGESTIONS.md
  - README.md with setup instructions

### Technical Details
- Architecture: x86-64
- Bootloader: GRUB multiboot2
- Memory: Identity-mapped paging (1GB virtual)
- Output: VGA text mode (0xb8000)
- Testing: Custom lightweight framework + QEMU automation

### Known Issues
- None documented yet

### Notes for Developers
- The bootloader currently uses identity mapping (virtual = physical)
- Kernel is compiled as 64-bit only (no 32-bit support)
- Paging uses 2MB huge pages (512 total = 1GB addressable)
- No interrupt handling yet (CPU interrupts disabled)
- No user mode separation yet (kernel mode only)

---

## How to Contribute

### Version Control
- Create feature branches: `git checkout -b feature/my-feature`
- Create bugfix branches: `git checkout -b bugfix/issue-123`
- Keep commits atomic and well-documented
- Follow conventional commits: `type(scope): description`

### Reporting Changes
When making changes, update this CHANGELOG.md:

1. Find the [Unreleased] section
2. Categorize your changes (Added, Changed, Fixed, etc.)
3. Add brief description with bullet points
4. For releases, create new [x.x.x] section with date

### Version Release Process
1. Update CHANGELOG.md with [x.x.x] release section
2. Verify all tests pass: `make test`
3. Tag release: `git tag -a vx.x.x -m "Release version x.x.x"`
4. Push tag: `git push origin vx.x.x`
5. Create GitHub release with changelog

---

## Release History

### v0.1.0 (Initial Release)
- Basic 64-bit kernel with bootloader
- VGA text output support
- Testing framework and CI/CD
- Professional documentation and build system

---

## Legend

- **Added** - New features
- **Changed** - Changes to existing functionality
- **Deprecated** - Features marked for removal
- **Removed** - Removed features
- **Fixed** - Bug fixes
- **Security** - Security-related fixes or improvements
- **Performance** - Performance improvements
- **Documentation** - Documentation improvements

---

## Future Versions

### v0.2.0 (Planning)
- Keyboard input driver (PS/2)
- Serial port debugging enhancements
- Kernel panic handler
- Memory profiling tools

### v0.3.0 (Planning)
- Disk I/O support
- Basic filesystem (FAT32)
- Process management
- Task switching

### v0.4.0 (Planning)
- Virtual memory improvements
- System calls interface
- User mode separation
- Permission levels

### v0.5.0 (Planning)
- Security features (stack canaries, bounds checking)
- ARM64 architecture support
- Performance optimizations
- Extended documentation

### v1.0.0 (Long-term Vision)
- Stable kernel API
- Multi-tasking fully implemented
- User space programs executable
- Network support
