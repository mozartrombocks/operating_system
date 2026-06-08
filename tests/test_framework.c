/**
 * @file test_framework.c
 * @brief Implementation of minimal unit testing framework
 *
 * Provides test registration, execution, and reporting functionality
 * for kernel component testing.
 */

#include "test_framework.h"
#include <stdio.h>
#include <string.h>

/* ============================================================================
 * GLOBAL TEST STATE
 * ============================================================================ */

/** Array of registered test cases */
test_case_t test_registry[MAX_TESTS] = {0};

/** Total number of registered tests */
uint32_t test_count = 0;

/** Number of tests that passed */
uint32_t test_passed = 0;

/** Number of tests that failed */
uint32_t test_failed = 0;

/** Current test being executed (for error reporting) */
const char *current_test_name = NULL;

/** Message from last failed assertion */
const char *last_failure_message = NULL;

/* ============================================================================
 * TEST EXECUTION
 * ============================================================================ */

/**
 * @brief Execute all registered tests
 *
 * Iterates through all registered test cases, executes each one,
 * and tracks pass/fail results.
 *
 * @return 0 if all tests passed, 1 if any test failed
 */
int run_all_tests(void) {
    test_passed = 0;
    test_failed = 0;

    printf("\n");
    printf("================================================================================\n");
    printf("Running %u tests...\n", test_count);
    printf("================================================================================\n\n");

    for (uint32_t i = 0; i < test_count; i++) {
        test_case_t *test = &test_registry[i];
        current_test_name = test->name;

        /* Initialize test result to passed */
        test->result = TEST_PASSED;
        test->message = NULL;

        /* Execute the test function */
        /* The test function will call ASSERT macros which may modify test->result */
        test->func();

        /* Report result */
        if (test->result == TEST_PASSED) i   {
            printf("✓ PASS: %s\n", test->name);
            test_passed++;
        } else {
            printf("✗ FAIL: %s\n", test->name);
            if (test->message) {
                printf("         %s\n", test->message);
            }
            test_failed++;     
        }
    }

    printf("\n");
    printf("================================================================================\n");
    printf("Test Results: %u passed, %u failed out of %u total\n",
           test_passed, test_failed, test_count);
    printf("================================================================================\n\n");

    return (test_failed == 0) ? 0 : 1;
}

/**
 * @brief Print detailed test report
 *
 * Displays comprehensive results for all tests including pass/fail status,
 * error messages, and summary statistics.
 */
void print_test_report(void) {
    printf("\n");
    printf("================================================================================\n");
    printf("DETAILED TEST REPORT\n");
    printf("================================================================================\n\n");

    for (uint32_t i = 0; i < test_count; i++) {
        test_case_t *test = &test_registry[i];

        const char *status = "UNKNOWN";
        const char *symbol = "?";

        switch (test->result) {
            case TEST_PASSED:
                status = "PASSED";
                symbol = "✓";
                break;
            case TEST_FAILED:
                status = "FAILED";
                symbol = "✗";
                break;
            case TEST_ERROR:
                status = "ERROR";
                symbol = "⚠";
                break;
        }

        printf("%s [%s] %s\n", symbol, status, test->name);

        if (test->message) {
            printf("  Message: %s\n", test->message);
        }

        printf("\n");
    }

    printf("================================================================================\n");
    printf("Summary:\n");
    printf("  Total:    %u\n", test_count);
    printf("  Passed:   %u (%.1f%%)\n", test_passed,
           test_count > 0 ? (100.0 * test_passed / test_count) : 0.0);
    printf("  Failed:   %u\n", test_failed);
    printf("================================================================================\n\n");
}

/**
 * @brief Get number of tests that passed
 */
uint32_t get_tests_passed(void) {
    return test_passed;
}

/**
 * @brief Get number of tests that failed
 */
uint32_t get_tests_failed(void) {
    return test_failed;
}
