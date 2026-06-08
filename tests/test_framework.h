/**
 * @file test_framework.h
 * @brief Minimal unit testing framework for kernel components
 *
 * This header provides a lightweight test framework suitable for low-level
 * kernel code testing. It includes assertion macros, test registration,
 * and result reporting.
 *
 * Usage:
 *   #include "test_framework.h"
 *
 *   TEST(print_char_basic) {
 *       ASSERT_EQUAL(1, 1);
 *   }
 *
 *   int main() {
 *       RUN_TESTS();
 *       return 0;
 *   }
 *
 * @note This framework is designed to work in both hosted (x86-64 Linux)
 *       and freestanding (bare-metal) environments
 */

#pragma once

#include <stdint.h>
#include <stdio.h>
#include <string.h>

/* ============================================================================
 * TEST STRUCTURE AND REGISTRATION
 * ============================================================================ */

/** @brief Maximum number of tests that can be registered */
#define MAX_TESTS 256

/** @brief Test function pointer type */
typedef void (*test_fn_t)(void);

/** @brief Test result enumeration */
typedef enum {
    TEST_PASSED = 0,    /**< Test passed */
    TEST_FAILED = 1,    /**< Test failed (assertion failed) */
    TEST_ERROR = 2,     /**< Test error (exception, crash, etc) */
} test_result_t;

/** @brief Test case metadata */
typedef struct {
    const char *name;       /**< Test name for reporting */
    test_fn_t func;         /**< Test function to execute */
    test_result_t result;   /**< Result after execution */
    const char *message;    /**< Error message if failed */
} test_case_t;

/* ============================================================================
 * GLOBAL TEST STATE
 * ============================================================================ */

extern test_case_t test_registry[MAX_TESTS];
extern uint32_t test_count;
extern uint32_t test_passed;
extern uint32_t test_failed;

extern const char *current_test_name;
extern const char *last_failure_message;

/* ============================================================================
 * TEST REGISTRATION MACROS
 * ============================================================================ */

/**
 * @brief Register and define a test case
 *
 * This macro creates a test function and registers it with the test framework.
 * The test function is defined in the following block.
 *
 * @param name  Test name (must be valid C identifier)
 *
 * @example
 *   TEST(print_color_red) {
 *       print_set_color(PRINT_COLOR_RED, PRINT_COLOR_BLACK);
 *       ASSERT_EQUAL(color_value, 0x04);
 *   }
 */
#define TEST(name) \
    static void test_##name(void); \
    static void __attribute__((constructor)) register_##name(void) { \
        test_registry[test_count].name = #name; \
        test_registry[test_count].func = test_##name; \
        test_count++; \
    } \
    static void test_##name(void)

/* ============================================================================
 * ASSERTION MACROS
 * ============================================================================ */

/**
 * @brief Assert that condition is true
 *
 * If the condition is false, the test fails with the given message.
 *
 * @param cond      Boolean condition to check
 * @param message   Message to display on failure
 *
 * @example
 *   ASSERT(color >= 0 && color <= 15, "Invalid color value");
 */
#define ASSERT(cond, message) \
    do { \
        if (!(cond)) { \
            last_failure_message = message; \
            test_registry[test_count-1].result = TEST_FAILED; \
            test_registry[test_count-1].message = message; \
            return; \
        } \
    } while(0)

/**
 * @brief Assert that two values are equal
 *
 * Compares two integer values for equality. Fails if they are not equal.
 *
 * @param actual    Actual value (expression)
 * @param expected  Expected value (expression)
 *
 * @example
 *   ASSERT_EQUAL(calculate_color(RED, BLACK), 0x04);
 */
#define ASSERT_EQUAL(actual, expected) \
    do { \
        uint64_t _actual = (uint64_t)(actual); \
        uint64_t _expected = (uint64_t)(expected); \
        if (_actual != _expected) { \
            static char msg[256]; \
            snprintf(msg, sizeof(msg), "Expected %llu, got %llu", _expected, _actual); \
            last_failure_message = msg; \
            test_registry[test_count-1].result = TEST_FAILED; \
            test_registry[test_count-1].message = msg; \
            return; \
        } \
    } while(0)

/**
 * @brief Assert that two values are NOT equal
 *
 * @param val1  First value
 * @param val2  Second value
 */
#define ASSERT_NOT_EQUAL(val1, val2) \
    do { \
        if ((val1) == (val2)) { \
            static char msg[256]; \
            snprintf(msg, sizeof(msg), "Values should not be equal: %llu", (uint64_t)(val1)); \
            ASSERT(0, msg); \
        } \
    } while(0)

/**
 * @brief Assert that pointer is NULL
 *
 * @param ptr  Pointer to check
 */
#define ASSERT_NULL(ptr) \
    ASSERT((ptr) == NULL, "Expected NULL pointer")

/**
 * @brief Assert that pointer is NOT NULL
 *
 * @param ptr  Pointer to check
 */
#define ASSERT_NOT_NULL(ptr) \
    ASSERT((ptr) != NULL, "Expected non-NULL pointer")

/**
 * @brief Assert that memory regions are equal
 *
 * Compares two memory regions byte-by-byte.
 *
 * @param actual    Pointer to actual memory
 * @param expected  Pointer to expected memory
 * @param size      Number of bytes to compare
 */
#define ASSERT_MEM_EQUAL(actual, expected, size) \
    do { \
        if (memcmp((actual), (expected), (size)) != 0) { \
            ASSERT(0, "Memory regions differ"); \
        } \
    } while(0)

/* ============================================================================
 * TEST EXECUTION AND REPORTING
 * ============================================================================ */

/**
 * @brief Run all registered tests
 *
 * Executes all test cases in order and prints a summary report.
 * Returns 0 if all tests passed, 1 if any test failed.
 *
 * @return 0 if all tests pass, 1 if any test fails
 */
int run_all_tests(void);

/**
 * @brief Print detailed test report
 *
 * Displays results for all tests with pass/fail status and error messages.
 */
void print_test_report(void);

/**
 * @brief Get number of tests that passed
 */
uint32_t get_tests_passed(void);

/**
 * @brief Get number of tests that failed
 */
uint32_t get_tests_failed(void);
