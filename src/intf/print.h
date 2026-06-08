/**
 * @file print.h
 * @brief Video mode text output interface for 80x25 text mode display
 *
 * This header provides functions for printing text to the VGA text mode buffer
 * located at physical address 0xb8000. Supports color codes and basic text control.
 *
 * Memory Layout:
 *   - Base Address: 0xb8000 (physical)
 *   - Rows: 25 (0-24)
 *   - Columns: 80 (0-79)
 *   - Entry Size: 2 bytes (character + attribute)
 *   - Total Size: 4000 bytes
 *
 * Color Encoding:
 *   - Low 4 bits:  Foreground color (0-15)
 *   - High 4 bits: Background color (0-7)
 *
 * @note All coordinates are 0-indexed from top-left
 */

#pragma once

#include <stdint.h>
#include <stddef.h>

/**
 * @enum Color Values
 * @brief VGA 16-color palette
 */
enum {
	PRINT_COLOR_BLACK = 0,           /**< Black (0x0) */
	PRINT_COLOR_BLUE = 1,            /**< Blue (0x1) */
	PRINT_COLOR_GREEN = 2,           /**< Green (0x2) */
	PRINT_COLOR_CYAN = 3,            /**< Cyan (0x3) */
	PRINT_COLOR_RED = 4,             /**< Red (0x4) */
	PRINT_COLOR_MAGENTA = 5,         /**< Magenta (0x5) */
	PRINT_COLOR_BROWN = 6,           /**< Brown (0x6) */
	PRINT_COLOR_LIGHT_GRAY = 7,      /**< Light Gray (0x7) */
	PRINT_COLOR_DARK_GRAY = 8,       /**< Dark Gray (0x8) */
	PRINT_COLOR_LIGHT_BLUE = 9,      /**< Light Blue (0x9) */
	PRINT_COLOR_LIGHT_GREEN = 10,    /**< Light Green (0xA) */
	PRINT_COLOR_LIGHT_CYAN = 11,     /**< Light Cyan (0xB) */
	PRINT_COLOR_LIGHT_RED = 12,      /**< Light Red (0xC) */
	PRINT_COLOR_PINK = 13,           /**< Pink (0xD) */
	PRINT_COLOR_YELLOW = 14,         /**< Yellow (0xE) */
	PRINT_COLOR_WHITE = 15,          /**< White (0xF) */
};

/**
 * @brief Clear the entire screen and reset cursor position
 *
 * Fills all 80x25 cells with space characters using the current color.
 * Resets the cursor position to (0, 0) - top-left corner.
 *
 * @return void
 */
void print_clear(void);

/**
 * @brief Print a single character at current cursor position
 *
 * Prints a single ASCII character at the current cursor position using
 * the active color setting. Handles special characters like newline ('\n').
 * Automatically scrolls the display if the cursor exceeds the bottom row.
 *
 * @param character  The ASCII character to print (0-255)
 * @return void
 *
 * @note Newline wraps cursor to next line, may trigger scroll
 * @note Carriage return resets cursor to column 0 of current row
 */
void print_char(char character);

/**
 * @brief Print a null-terminated string
 *
 * Prints a complete string to the display, starting from the current
 * cursor position. String must be null-terminated ('\0').
 * Respects all special character handling (newlines, etc).
 *
 * @param string  Pointer to null-terminated character array
 * @return void
 *
 * @note The string MUST be null-terminated
 * @note Current position and color are preserved after call
 */
void print_str(char* string);

/**
 * @brief Set text display colors for subsequent output
 *
 * Sets the foreground and background colors used for all subsequent
 * print operations. Colors persist until explicitly changed.
 *
 * @param foreground  Foreground color (0-15, see PRINT_COLOR_* enum)
 * @param background  Background color (0-7)
 * @return void
 *
 * @note Background color values should be 0-7 for compatibility
 * @note Color encoding: color_byte = foreground | (background << 4)
 *
 * @example
 *   print_set_color(PRINT_COLOR_GREEN, PRINT_COLOR_BLACK);
 *   print_str("Hello World"); // Prints green text on black background
 */
void print_set_color(uint8_t foreground, uint8_t background);
