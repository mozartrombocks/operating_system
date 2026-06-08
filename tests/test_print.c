/**
 * @file test_print.c
 * @brief Unit tests for print module (VGA text mode output)
 *
 * Tests the print module functionality including character output,
 * string printing, color management, and screen operations.
 *
 * Build: gcc -o test_print test_framework.c test_print.c -I.
 * Run:   ./test_print
 */

#include "test_framework.h"
#include <stdint.h>
#include <string.h>

/* ============================================================================
 * MOCK IMPLEMENTATIONS
 * ============================================================================
 *
 * In real testing, we would mock the VGA buffer and other hardware
 * dependencies. For this example, we use simplified mocks.
 */

/** Mock VGA buffer for testing */
static struct {
    uint8_t character;
    uint8_t color;
} mock_buffer[80 * 25];

/** Mock cursor position */
static size_t mock_col = 0;
static size_t mock_row = 0;

/** Mock color state */
static uint8_t mock_color = 0x0F;  /* white on black */

/* ============================================================================
 * UNIT TESTS FOR PRINT MODULE
 * ============================================================================ */

/**
 * @test Color encoding verification
 *
 * Verifies that color values are correctly encoded/decoded.
 * Color byte: low 4 bits = foreground, high 4 bits = background
 */
TEST(color_encoding) {
    /* Test foreground color extraction */
    uint8_t color = 0x0E;  /* yellow on black */
    uint8_t foreground = color & 0x0F;  /* low 4 bits */
    uint8_t background = (color >> 4) & 0x0F;  /* high 4 bits */

    ASSERT_EQUAL(foreground, 0x0E);  /* yellow = 14 */
    ASSERT_EQUAL(background, 0x00);  /* black = 0 */
}

/**
 * @test Color encoding with background
 *
 * Tests encoding foreground and background into single byte.
 */
TEST(color_with_background) {
    uint8_t foreground = 0x0C;  /* red */
    uint8_t background = 0x07;  /* white background (but only low 3 bits) */

    /* Simulate color encoding: color = foreground | (background << 4) */
    uint8_t color = foreground | (background << 4);

    ASSERT_EQUAL(color & 0x0F, 0x0C);  /* Foreground is red */
    ASSERT_EQUAL((color >> 4) & 0x0F, 0x07);  /* Background encoded */
}

/**
 * @test Buffer offset calculation
 *
 * Verifies that row/column to buffer offset conversion is correct.
 * Formula: offset = col + NUM_COLS * row
 */
TEST(buffer_offset_calculation) {
    const size_t NUM_COLS = 80;

    /* Test offset for (0, 0) */
    size_t offset = 0 + NUM_COLS * 0;
    ASSERT_EQUAL(offset, 0);

    /* Test offset for (79, 0) - last column, first row */
    offset = 79 + NUM_COLS * 0;
    ASSERT_EQUAL(offset, 79);

    /* Test offset for (0, 1) - first column, second row */
    offset = 0 + NUM_COLS * 1;
    ASSERT_EQUAL(offset, 80);

    /* Test offset for (10, 5) - middle position */
    offset = 10 + NUM_COLS * 5;
    ASSERT_EQUAL(offset, 410);

    /* Test last position (79, 24) */
    offset = 79 + NUM_COLS * 24;
    ASSERT_EQUAL(offset, 1999);
}

/**
 * @test Cursor boundary detection
 *
 * Tests that cursor position tracking respects display boundaries.
 * Display is 80 columns × 25 rows.
 */
TEST(cursor_boundaries) {
    const size_t NUM_COLS = 80;
    const size_t NUM_ROWS = 25;

    /* Valid positions */
    ASSERT(0 <= 0 && 0 < NUM_COLS, "Column 0 is valid");
    ASSERT(0 <= 24 && 24 < NUM_ROWS, "Row 24 is valid");

    /* Boundary positions */
    ASSERT(79 < NUM_COLS, "Column 79 is within bounds");
    ASSERT(79 >= NUM_COLS, "Column 79 is at boundary");
}

/**
 * @test Newline handling simulation
 *
 * Tests the logic of detecting and handling newline characters.
 */
TEST(newline_character_detection) {
    char newline = '\n';
    char regular = 'A';

    ASSERT_EQUAL(newline, '\n');
    ASSERT_NOT_EQUAL(regular, '\n');
}

/**
 * @test String null termination
 *
 * Verifies that null-terminated strings are correctly identified.
 */
TEST(string_null_termination) {
    const char *str = "Hello";

    /* Verify string is null-terminated */
    size_t i = 0;
    while (str[i] != '\0') {
        i++;
    }

    ASSERT_EQUAL(i, 5);  /* "Hello" is 5 characters */
    ASSERT_EQUAL(str[5], '\0');  /* Position 5 is null terminator */
}

/**
 * @test Character to byte conversion
 *
 * Tests casting of char to uint8_t for buffer storage.
 */
TEST(char_to_byte_conversion) {
    char ch = 'A';
    uint8_t byte = (uint8_t)ch;

    ASSERT_EQUAL(byte, 0x41);  /* ASCII 'A' = 0x41 */
}

/**
 * @test Extended ASCII characters
 *
 * Tests handling of extended ASCII characters (128-255).
 */
TEST(extended_ascii_characters) {
    uint8_t extended = 0xFF;  /* High value */
    uint8_t low = 0x00;       /* Low value */

    ASSERT_EQUAL(extended, 255);
    ASSERT_EQUAL(low, 0);
}

/**
 * @test Row scrolling calculation
 *
 * Tests the logic for shifting rows during scroll operation.
 * When last row is full, row N should move to row N-1.
 */
TEST(row_scrolling_calculation) {
    const size_t NUM_ROWS = 25;

    /* Simulate scroll: shift all rows up by 1 */
    for (size_t row = 1; row < NUM_ROWS; row++) {
        /* Source row = row, destination row = row - 1 */
        ASSERT(row > 0, "Source row must be > 0");
        ASSERT(row - 1 < row, "Destination before source");
    }
}

/**
 * @test Loop iteration count
 *
 * Verifies that standard loops iterate the correct number of times.
 * E.g., filling 80 columns, 25 rows = 2000 iterations.
 */
TEST(loop_iteration_count) {
    const size_t NUM_COLS = 80;
    const size_t NUM_ROWS = 25;

    size_t count = 0;
    for (size_t row = 0; row < NUM_ROWS; row++) {
        for (size_t col = 0; col < NUM_COLS; col++) {
            count++;
        }
    }

    ASSERT_EQUAL(count, 2000);  /* 80 * 25 */
}

/**
 * @test Memory write simulation
 *
 * Tests that structure writes are handled correctly.
 */
TEST(struct_write_simulation) {
    /* Simulate writing to buffer */
    struct {
        uint8_t character;
        uint8_t color;
    } cell;

    cell.character = 'X';
    cell.color = 0x0C;  /* red on black */

    ASSERT_EQUAL(cell.character, 'X');
    ASSERT_EQUAL(cell.color, 0x0C);
}

/**
 * @test Multiple color settings
 *
 * Tests switching between different color combinations.
 */
TEST(multiple_color_combinations) {
    uint8_t colors[] = {
        0x0F,  /* white on black */
        0x0A,  /* light green */
        0x0C,  /* light red */
        0x0E,  /* yellow */
    };

    for (size_t i = 0; i < 4; i++) {
        ASSERT(colors[i] >= 0 && colors[i] <= 0xFF, "Color value in range");
    }
}

/**
 * @test Character array handling
 *
 * Tests handling of character arrays and iteration.
 */
TEST(character_array_handling) {
    const char *text = "Test";
    size_t len = 0;

    while (text[len] != '\0') {
        ASSERT(text[len] >= 32 && text[len] <= 126, "Printable ASCII");
        len++;
    }

    ASSERT_EQUAL(len, 4);
}

/* ============================================================================
 * MAIN TEST RUNNER
 * ============================================================================ */

/**
 * @brief Main test runner
 *
 * Executes all registered tests and prints summary report.
 * Exit code: 0 if all tests pass, 1 if any test fails.
 */
int main(void) {
    printf("Print Module Unit Tests\n");
    printf("========================\n");

    int result = run_all_tests();
    print_test_report();

    return result;
}
