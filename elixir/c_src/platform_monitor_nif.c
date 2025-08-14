/*
 * Platform Monitor NIF - Native Implementation
 * 
 * This file provides the main NIF interface for cross-platform
 * system monitoring capabilities in Selfspy Phoenix.
 * 
 * Supports: macOS, Linux, Windows with graceful fallbacks
 */

#include <erl_nif.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

// Platform-specific headers
#ifdef DARWIN
    #include "darwin_monitor.h"
#elif defined(LINUX)  
    #include "linux_monitor.h"
#elif defined(WIN32)
    #include "windows_monitor.h"
#else
    #include "fallback_monitor.h"
#endif

// NIF Function Declarations
static ERL_NIF_TERM get_active_window_info_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
static ERL_NIF_TERM get_keyboard_state_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
static ERL_NIF_TERM get_mouse_position_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
static ERL_NIF_TERM get_system_info_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
static ERL_NIF_TERM set_global_hotkey_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
static ERL_NIF_TERM remove_global_hotkey_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
static ERL_NIF_TERM check_permissions_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

// Utility functions for creating Erlang terms
static ERL_NIF_TERM make_atom(ErlNifEnv* env, const char* atom_name) {
    return enif_make_atom(env, atom_name);
}

static ERL_NIF_TERM make_ok_tuple(ErlNifEnv* env, ERL_NIF_TERM value) {
    return enif_make_tuple2(env, make_atom(env, "ok"), value);
}

static ERL_NIF_TERM make_error_tuple(ErlNifEnv* env, const char* reason) {
    return enif_make_tuple2(env, make_atom(env, "error"), make_atom(env, reason));
}

// Implementation of NIF functions

static ERL_NIF_TERM get_active_window_info_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    if (argc != 0) {
        return enif_make_badarg(env);
    }
    
    window_info_t window_info;
    
    if (platform_get_active_window(&window_info) == 0) {
        // Create Elixir map with window information
        ERL_NIF_TERM keys[] = {
            make_atom(env, "title"),
            make_atom(env, "process_name"), 
            make_atom(env, "process_id"),
            make_atom(env, "bundle_id"),
            make_atom(env, "window_id"),
            make_atom(env, "bounds"),
            make_atom(env, "is_focused"),
            make_atom(env, "workspace")
        };
        
        // Create bounds map
        ERL_NIF_TERM bound_keys[] = {
            make_atom(env, "x"),
            make_atom(env, "y"),
            make_atom(env, "width"),
            make_atom(env, "height")
        };
        
        ERL_NIF_TERM bound_values[] = {
            enif_make_int(env, window_info.bounds.x),
            enif_make_int(env, window_info.bounds.y),
            enif_make_int(env, window_info.bounds.width),
            enif_make_int(env, window_info.bounds.height)
        };
        
        ERL_NIF_TERM bounds_map;
        enif_make_map_from_arrays(env, bound_keys, bound_values, 4, &bounds_map);
        
        ERL_NIF_TERM values[] = {
            enif_make_string(env, window_info.title, ERL_NIF_LATIN1),
            enif_make_string(env, window_info.process_name, ERL_NIF_LATIN1),
            enif_make_int(env, window_info.process_id),
            enif_make_string(env, window_info.bundle_id, ERL_NIF_LATIN1),
            enif_make_int64(env, window_info.window_id),
            bounds_map,
            window_info.is_focused ? make_atom(env, "true") : make_atom(env, "false"),
            enif_make_int(env, window_info.workspace)
        };
        
        ERL_NIF_TERM result_map;
        enif_make_map_from_arrays(env, keys, values, 8, &result_map);
        
        return make_ok_tuple(env, result_map);
    } else {
        return make_error_tuple(env, "failed_to_get_window_info");
    }
}

static ERL_NIF_TERM get_keyboard_state_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    if (argc != 0) {
        return enif_make_badarg(env);
    }
    
    keyboard_state_t kbd_state;
    
    if (platform_get_keyboard_state(&kbd_state) == 0) {
        // Create modifier map
        ERL_NIF_TERM mod_keys[] = {
            make_atom(env, "shift"),
            make_atom(env, "control"),
            make_atom(env, "alt"),
            make_atom(env, "command"),
            make_atom(env, "caps_lock")
        };
        
        ERL_NIF_TERM mod_values[] = {
            kbd_state.modifiers.shift ? make_atom(env, "true") : make_atom(env, "false"),
            kbd_state.modifiers.control ? make_atom(env, "true") : make_atom(env, "false"),
            kbd_state.modifiers.alt ? make_atom(env, "true") : make_atom(env, "false"),
            kbd_state.modifiers.command ? make_atom(env, "true") : make_atom(env, "false"),
            kbd_state.modifiers.caps_lock ? make_atom(env, "true") : make_atom(env, "false")
        };
        
        ERL_NIF_TERM modifiers_map;
        enif_make_map_from_arrays(env, mod_keys, mod_values, 5, &modifiers_map);
        
        // Create main keyboard state map
        ERL_NIF_TERM keys[] = {
            make_atom(env, "modifiers"),
            make_atom(env, "layout"),
            make_atom(env, "input_source"),
            make_atom(env, "repeat_rate"),
            make_atom(env, "repeat_delay")
        };
        
        ERL_NIF_TERM values[] = {
            modifiers_map,
            enif_make_string(env, kbd_state.layout, ERL_NIF_LATIN1),
            enif_make_string(env, kbd_state.input_source, ERL_NIF_LATIN1),
            enif_make_double(env, kbd_state.repeat_rate),
            enif_make_double(env, kbd_state.repeat_delay)
        };
        
        ERL_NIF_TERM result_map;
        enif_make_map_from_arrays(env, keys, values, 5, &result_map);
        
        return make_ok_tuple(env, result_map);
    } else {
        return make_error_tuple(env, "failed_to_get_keyboard_state");
    }
}

static ERL_NIF_TERM get_mouse_position_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    if (argc != 0) {
        return enif_make_badarg(env);
    }
    
    mouse_state_t mouse_state;
    
    if (platform_get_mouse_state(&mouse_state) == 0) {
        // Create button state map
        ERL_NIF_TERM btn_keys[] = {
            make_atom(env, "left"),
            make_atom(env, "right"),
            make_atom(env, "middle")
        };
        
        ERL_NIF_TERM btn_values[] = {
            mouse_state.button_state.left ? make_atom(env, "true") : make_atom(env, "false"),
            mouse_state.button_state.right ? make_atom(env, "true") : make_atom(env, "false"),
            mouse_state.button_state.middle ? make_atom(env, "true") : make_atom(env, "false")
        };
        
        ERL_NIF_TERM button_map;
        enif_make_map_from_arrays(env, btn_keys, btn_values, 3, &button_map);
        
        // Create main mouse state map
        ERL_NIF_TERM keys[] = {
            make_atom(env, "x"),
            make_atom(env, "y"),
            make_atom(env, "screen"),
            make_atom(env, "pressure"),
            make_atom(env, "button_state")
        };
        
        ERL_NIF_TERM values[] = {
            enif_make_int(env, mouse_state.x),
            enif_make_int(env, mouse_state.y),
            enif_make_int(env, mouse_state.screen),
            enif_make_double(env, mouse_state.pressure),
            button_map
        };
        
        ERL_NIF_TERM result_map;
        enif_make_map_from_arrays(env, keys, values, 5, &result_map);
        
        return make_ok_tuple(env, result_map);
    } else {
        return make_error_tuple(env, "failed_to_get_mouse_position");
    }
}

static ERL_NIF_TERM get_system_info_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    if (argc != 0) {
        return enif_make_badarg(env);
    }
    
    system_info_t sys_info;
    
    if (platform_get_system_info(&sys_info) == 0) {
        // Create screens array
        ERL_NIF_TERM* screen_terms = malloc(sys_info.screen_count * sizeof(ERL_NIF_TERM));
        
        for (int i = 0; i < sys_info.screen_count; i++) {
            screen_info_t* screen = &sys_info.screens[i];
            
            ERL_NIF_TERM screen_keys[] = {
                make_atom(env, "id"),
                make_atom(env, "bounds"),
                make_atom(env, "scale"),
                make_atom(env, "is_primary")
            };
            
            // Create screen bounds
            ERL_NIF_TERM bound_keys[] = {
                make_atom(env, "x"),
                make_atom(env, "y"), 
                make_atom(env, "width"),
                make_atom(env, "height")
            };
            
            ERL_NIF_TERM bound_values[] = {
                enif_make_int(env, screen->bounds.x),
                enif_make_int(env, screen->bounds.y),
                enif_make_int(env, screen->bounds.width),
                enif_make_int(env, screen->bounds.height)
            };
            
            ERL_NIF_TERM bounds_map;
            enif_make_map_from_arrays(env, bound_keys, bound_values, 4, &bounds_map);
            
            ERL_NIF_TERM screen_values[] = {
                enif_make_int(env, screen->id),
                bounds_map,
                enif_make_double(env, screen->scale),
                screen->is_primary ? make_atom(env, "true") : make_atom(env, "false")
            };
            
            enif_make_map_from_arrays(env, screen_keys, screen_values, 4, &screen_terms[i]);
        }
        
        ERL_NIF_TERM screens_list = enif_make_list_from_array(env, screen_terms, sys_info.screen_count);
        free(screen_terms);
        
        // Create main system info map
        ERL_NIF_TERM keys[] = {
            make_atom(env, "platform"),
            make_atom(env, "os_version"),
            make_atom(env, "architecture"),
            make_atom(env, "cpu_count"),
            make_atom(env, "memory_total"),
            make_atom(env, "memory_available"),
            make_atom(env, "screen_count"),
            make_atom(env, "screens"),
            make_atom(env, "accessibility_enabled"),
            make_atom(env, "screen_recording_enabled")
        };
        
        ERL_NIF_TERM values[] = {
            enif_make_string(env, sys_info.platform, ERL_NIF_LATIN1),
            enif_make_string(env, sys_info.os_version, ERL_NIF_LATIN1),
            enif_make_string(env, sys_info.architecture, ERL_NIF_LATIN1),
            enif_make_int(env, sys_info.cpu_count),
            enif_make_int64(env, sys_info.memory_total),
            enif_make_int64(env, sys_info.memory_available),
            enif_make_int(env, sys_info.screen_count),
            screens_list,
            sys_info.accessibility_enabled ? make_atom(env, "true") : make_atom(env, "false"),
            sys_info.screen_recording_enabled ? make_atom(env, "true") : make_atom(env, "false")
        };
        
        ERL_NIF_TERM result_map;
        enif_make_map_from_arrays(env, keys, values, 10, &result_map);
        
        return make_ok_tuple(env, result_map);
    } else {
        return make_error_tuple(env, "failed_to_get_system_info");
    }
}

static ERL_NIF_TERM set_global_hotkey_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    // TODO: Implement global hotkey registration
    return make_error_tuple(env, "not_implemented");
}

static ERL_NIF_TERM remove_global_hotkey_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    // TODO: Implement global hotkey removal
    return make_error_tuple(env, "not_implemented");
}

static ERL_NIF_TERM check_permissions_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    if (argc != 0) {
        return enif_make_badarg(env);
    }
    
    permission_status_t permissions;
    
    if (platform_check_permissions(&permissions) == 0) {
        ERL_NIF_TERM keys[] = {
            make_atom(env, "accessibility"),
            make_atom(env, "screen_recording"),
            make_atom(env, "input_monitoring")
        };
        
        ERL_NIF_TERM values[] = {
            permissions.accessibility ? make_atom(env, "granted") : make_atom(env, "denied"),
            permissions.screen_recording ? make_atom(env, "granted") : make_atom(env, "denied"),
            permissions.input_monitoring ? make_atom(env, "granted") : make_atom(env, "denied")
        };
        
        ERL_NIF_TERM result_map;
        enif_make_map_from_arrays(env, keys, values, 3, &result_map);
        
        return make_ok_tuple(env, result_map);
    } else {
        return make_error_tuple(env, "failed_to_check_permissions");
    }
}

// NIF function table
static ErlNifFunc nif_funcs[] = {
    {"get_active_window_info", 0, get_active_window_info_nif},
    {"get_keyboard_state", 0, get_keyboard_state_nif},
    {"get_mouse_position", 0, get_mouse_position_nif},
    {"get_system_info", 0, get_system_info_nif},
    {"set_global_hotkey", 1, set_global_hotkey_nif},
    {"remove_global_hotkey", 1, remove_global_hotkey_nif},
    {"check_permissions", 0, check_permissions_nif}
};

// NIF module initialization
ERL_NIF_INIT(Elixir.SelfspyWeb.NIF.PlatformMonitor, nif_funcs, NULL, NULL, NULL, NULL)