/*
 * Darwin (macOS) Platform Monitor Header
 * 
 * Defines structures and functions for macOS-specific system monitoring
 * using Cocoa, ApplicationServices, and CoreGraphics frameworks.
 */

#ifndef DARWIN_MONITOR_H
#define DARWIN_MONITOR_H

#include <stdint.h>
#include <stdbool.h>

// Maximum string lengths
#define MAX_TITLE_LENGTH 512
#define MAX_PROCESS_NAME_LENGTH 256
#define MAX_BUNDLE_ID_LENGTH 256
#define MAX_LAYOUT_LENGTH 64
#define MAX_INPUT_SOURCE_LENGTH 128
#define MAX_PLATFORM_LENGTH 32
#define MAX_OS_VERSION_LENGTH 64
#define MAX_ARCHITECTURE_LENGTH 16
#define MAX_SCREENS 8

// Rectangle structure for bounds
typedef struct {
    int x;
    int y;
    int width;
    int height;
} rect_t;

// Window information structure
typedef struct {
    char title[MAX_TITLE_LENGTH];
    char process_name[MAX_PROCESS_NAME_LENGTH];
    int process_id;
    char bundle_id[MAX_BUNDLE_ID_LENGTH];
    uint64_t window_id;
    rect_t bounds;
    bool is_focused;
    int workspace;
} window_info_t;

// Keyboard modifier state
typedef struct {
    bool shift;
    bool control;
    bool alt;
    bool command;
    bool caps_lock;
} modifier_state_t;

// Keyboard state structure
typedef struct {
    modifier_state_t modifiers;
    char layout[MAX_LAYOUT_LENGTH];
    char input_source[MAX_INPUT_SOURCE_LENGTH];
    double repeat_rate;
    double repeat_delay;
} keyboard_state_t;

// Mouse button state
typedef struct {
    bool left;
    bool right;
    bool middle;
} button_state_t;

// Mouse state structure
typedef struct {
    int x;
    int y;
    int screen;
    double pressure;
    button_state_t button_state;
} mouse_state_t;

// Screen information
typedef struct {
    int id;
    rect_t bounds;
    double scale;
    bool is_primary;
} screen_info_t;

// System information structure
typedef struct {
    char platform[MAX_PLATFORM_LENGTH];
    char os_version[MAX_OS_VERSION_LENGTH];
    char architecture[MAX_ARCHITECTURE_LENGTH];
    int cpu_count;
    uint64_t memory_total;
    uint64_t memory_available;
    int screen_count;
    screen_info_t screens[MAX_SCREENS];
    bool accessibility_enabled;
    bool screen_recording_enabled;
} system_info_t;

// Permission status structure
typedef struct {
    bool accessibility;
    bool screen_recording;
    bool input_monitoring;
} permission_status_t;

// Function declarations

/**
 * Get information about the currently active window
 * Returns 0 on success, -1 on error
 */
int platform_get_active_window(window_info_t* window_info);

/**
 * Get current keyboard state including modifiers and layout
 * Returns 0 on success, -1 on error
 */
int platform_get_keyboard_state(keyboard_state_t* keyboard_state);

/**
 * Get current mouse position and button state
 * Returns 0 on success, -1 on error
 */
int platform_get_mouse_state(mouse_state_t* mouse_state);

/**
 * Get comprehensive system information
 * Returns 0 on success, -1 on error
 */
int platform_get_system_info(system_info_t* system_info);

/**
 * Check current permission status for monitoring features
 * Returns 0 on success, -1 on error
 */
int platform_check_permissions(permission_status_t* permissions);

/**
 * Request accessibility permissions (opens System Preferences)
 * Returns 0 on success, -1 on error
 */
int platform_request_accessibility_permission(void);

/**
 * Request screen recording permissions
 * Returns 0 on success, -1 on error
 */
int platform_request_screen_recording_permission(void);

/**
 * Initialize the Darwin monitoring subsystem
 * Returns 0 on success, -1 on error
 */
int platform_init(void);

/**
 * Cleanup Darwin monitoring resources
 */
void platform_cleanup(void);

/**
 * Start low-level event monitoring (keyboard/mouse hooks)
 * Returns monitoring handle on success, -1 on error
 */
int platform_start_event_monitoring(void);

/**
 * Stop low-level event monitoring
 * Returns 0 on success, -1 on error
 */
int platform_stop_event_monitoring(int handle);

/**
 * Register a global hotkey combination
 * Returns hotkey ID on success, -1 on error
 */
int platform_register_hotkey(int modifiers, int keycode);

/**
 * Unregister a global hotkey
 * Returns 0 on success, -1 on error
 */
int platform_unregister_hotkey(int hotkey_id);

#endif // DARWIN_MONITOR_H