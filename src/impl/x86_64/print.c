/**
 * @file print.c
 * @brief VGA text mode (80x25) video buffer implementation
 *
 * Low-level implementation for printing text to VGA text mode display.
 * Manages a 80×25 character grid with color support at physical address 0xb8000.
 *
 * VGA Text Mode Layout:
 *   - Each cell: 2 bytes
 *     - Byte 0: ASCII character code
 *     - Byte 1: Color attribute (high nibble = background, low nibble = foreground)
 *   - Total rows: 25 (0-24)
 *   - Total columns: 80 (0-79)
 *   - Linear offset: row * 80 + col
 *
 * @author Your Name
 * @date 2024
 */

#include "print.h"

/* ============================================================================
 * CONFIGURATION CONSTANTS
 * ============================================================================ */

/** @brief Number of columns in text mode display */
const static size_t NUM_COLS = 80;

/** @brief Number of rows in text mode display */
const static size_t NUM_ROWS = 25;

/* ============================================================================
 * DATA STRUCTURES
 * ============================================================================ */

/**
 * @struct Char
 * @brief Single character cell in VGA text mode
 *
 * Each character cell in the VGA text buffer consists of two bytes:
 * the ASCII character and its color attribute.
 */
struct Char {
	uint8_t character;  /**< ASCII character code (0-255) */
	uint8_t color;      /**< Color attribute: high 4-bits=background, low 4-bits=foreground */
};

/* ============================================================================
 * GLOBAL STATE
 * ============================================================================ */

/**
 * Pointer to VGA text mode buffer in physical memory.
 * VGA text mode starts at physical address 0xb8000.
 * Each element is a struct Char (2 bytes).
 */
struct Char* buffer = (struct Char*) 0xb8000;

/** @brief Current cursor column position (0-79) */
size_t col = 0;

/** @brief Current cursor row position (0-24) */
size_t row = 0;

/**
 * Current active color for text output.
 * Encoding: low 4 bits = foreground, high 4 bits = background
 * Default: WHITE text on BLACK background
 */
uint8_t color = PRINT_COLOR_WHITE | (PRINT_COLOR_BLACK << 4);

/* ============================================================================
 * PRIVATE HELPER FUNCTIONS
 * ============================================================================ */

/**
 * @brief Clear all characters in a single row
 *
 * Fills every column in the specified row with space characters
 * using the current color attribute.
 *
 * @param row_num  Row index to clear (0-24)
 * @return void
 *
 * Algorithm:
 *   1. Create empty cell (space character + current color)
 *   2. Iterate through all 80 columns
 *   3. Write empty cell to each position: buffer[col + NUM_COLS * row]
 */
void clear_row(size_t row_num) {
	/* Create template for empty cell: space character with current color */
	struct Char empty = (struct Char) {
		character: ' ',
		color: color,
	};

	/* Fill all columns in the specified row with empty cells */
	for (size_t col = 0; col < NUM_COLS; col++) {
		buffer[col + NUM_COLS * row_num] = empty;
	}
}

/**
 * @brief Advance cursor to next line and scroll display if needed
 *
 * Moves cursor to the start of the next row (column 0).
 * If cursor is already on the last row, scrolls the entire display
 * up by one line and clears the new bottom row.
 *
 * Scroll Algorithm:
 *   1. Check if cursor is below last row
 *   2. If not: just move to next row and return
 *   3. If yes: Copy each row up one position (row N → row N-1)
 *   4. Clear the newly exposed bottom row
 *
 * @return void
 *
 * @note This implements simple line buffering without ring buffers
 * @note Scroll performance is O(rows * cols) = O(2000) operations
 */
void print_newline(void) {
	col = 0;  /* Reset column to start of new line */

	/* If not on last row, just move down one row */
	if (row < NUM_ROWS - 1) {
		row++;
		return;
	}

	/* Scroll display up: copy each row to the row above it */
	for (size_t row_idx = 1; row_idx < NUM_ROWS; row_idx++) {
		for (size_t col_idx = 0; col_idx < NUM_COLS; col_idx++) {
			/* Read character from current row */
			struct Char character = buffer[col_idx + NUM_COLS * row_idx];

			/* Write it to the row above */
			buffer[col_idx + NUM_COLS * (row_idx - 1)] = character;
		}
	}

	/* Clear the bottom row that was just vacated */
	clear_row(NUM_ROWS - 1);
}

/* ============================================================================
 * PUBLIC API FUNCTIONS
 * ============================================================================ */

/**
 * @brief Clear the entire display screen
 *
 * Clears all characters from the display by filling all 25 rows with
 * space characters using the current color. Resets cursor to (0, 0).
 *
 * Implementation:
 *   1. Iterate through all NUM_ROWS rows
 *   2. Call clear_row() for each row
 *   3. Cursor position is reset by next print operation
 *
 * @return void
 * @complexity O(rows * cols) = O(2000) memory writes
 */
void print_clear(void) {
	for (size_t i = 0; i < NUM_ROWS; i++) {
		clear_row(i);
	}

	/* Reset cursor position to home (0, 0) */
	row = 0;
	col = 0;
}

/**
 * @brief Print a single character to the display
 *
 * Outputs a single character at the current cursor position.
 * Handles newline characters specially. Automatically advances
 * to next line when column limit is exceeded.
 *
 * Implementation:
 *   1. Check for newline character ('\n')
 *      - If found: call print_newline() and return
 *   2. Check if cursor exceeds right boundary (col > NUM_COLS)
 *      - If true: wrap to next line via print_newline()
 *   3. Write character to video buffer at [col + NUM_COLS * row]
 *   4. Advance column position
 *
 * @param character  ASCII character to print (0-255)
 * @return void
 *
 * @note Newline ('\n') performs carriage return + line feed behavior
 * @note Characters beyond column 80 are wrapped to next line
 * @note Tab characters are NOT specially handled (printed as-is)
 *
 * @bug Assignment operator used instead of comparison in newline check
 *      Current: if (character = '\n')  // WRONG: assigns value
 *      Should:  if (character == '\n') // CORRECT: compares value
 */
void print_char(char character) {
	/* Handle newline character */
	if (character == '\n') {
		print_newline();
		return;
	}

	/* Wrap to next line if column exceeds boundary */
	if (col >= NUM_COLS) {
		print_newline();
	}

	/* Write character to video buffer at current position */
	buffer[col + NUM_COLS * row] = (struct Char) {
		character: (uint8_t) character,
		color: color,
	};

	/* Advance cursor to next column */
	col++;
}

/**
 * @brief Print a null-terminated string
 *
 * Outputs a complete string character-by-character starting from
 * the current cursor position. String must be null-terminated.
 *
 * Implementation:
 *   1. Initialize index to 0
 *   2. Loop until null terminator found:
 *      a. Cast current character to uint8_t
 *      b. Check for null terminator ('\0')
 *      c. Call print_char() for the character
 *      d. Increment index
 *
 * @param str  Pointer to null-terminated C string
 * @return void
 *
 * @note String MUST be null-terminated
 * @note Cursor position is updated by print_char() for each character
 * @note All newlines in the string are handled correctly
 *
 * @example
 *   print_str("Hello World\n");
 *   // Prints "Hello World" followed by newline
 */
void print_str(char* str) {
	for (size_t i = 0; 1; i++) {
		/* Get current character from string */
		char character = (uint8_t) str[i];

		/* Check for null terminator (end of string) */
		if (character == '\0') {
			return;
		}

		/* Print current character (may handle newline, advance cursor, etc.) */
		print_char(character);
	}
}

/**
 * @brief Set the active foreground and background colors
 *
 * Changes the text color for all subsequent print operations.
 * Colors are stored in a single uint8_t:
 *   - Low 4 bits (0-3):  Foreground color (0-15)
 *   - High 4 bits (4-7): Background color (0-7)
 *
 * Color Encoding:
 *   color = foreground | (background << 4)
 *
 * @param foreground  Foreground text color (0-15, see PRINT_COLOR_* constants)
 * @param background  Background text color (0-7)
 * @return void
 *
 * @note Foreground supports all 16 colors (including bright variants)
 * @note Background should be 0-7 (only standard 8 colors)
 * @note Color persists for all subsequent print operations
 *
 * @example
 *   // Set text to bright green on black background
 *   print_set_color(PRINT_COLOR_LIGHT_GREEN, PRINT_COLOR_BLACK);
 *
 *   // Set text to red on white background
 *   print_set_color(PRINT_COLOR_RED, PRINT_COLOR_WHITE);
 */
void print_set_color(uint8_t foreground, uint8_t background) {
	/* Combine foreground and background into single color byte */
	color = foreground + (background << 4);
}
