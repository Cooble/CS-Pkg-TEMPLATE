# Bootstrap to fetch the CircuitSim SDK based on the plugin.json
# 
# !! include it as the FIRST thing in your root CMakeLists.txt


include(FetchContent)
set(CMAKE_POLICY_VERSION_MINIMUM 3.5)

# ── Token / URL ───────────────────────────────────────────────────────────────
if(NOT DEFINED CIRCUITSIM_ACCESS_TOKEN OR CIRCUITSIM_ACCESS_TOKEN STREQUAL "")
    if(DEFINED ENV{CIRCUITSIM_ACCESS_TOKEN} AND NOT "$ENV{CIRCUITSIM_ACCESS_TOKEN}" STREQUAL "")
        set(CIRCUITSIM_ACCESS_TOKEN "$ENV{CIRCUITSIM_ACCESS_TOKEN}"
            CACHE STRING "GitHub token for CircuitSim repository" FORCE)
    else()
        set(CIRCUITSIM_ACCESS_TOKEN ""
            CACHE STRING "GitHub token for CircuitSim repository")
    endif()
endif()

if(NOT CIRCUITSIM_ACCESS_TOKEN STREQUAL "")
    set(_CS_REPO_URL "https://${CIRCUITSIM_ACCESS_TOKEN}@github.com/Cooble/circuitsim")
else()
    set(_CS_REPO_URL "https://github.com/Cooble/circuitsim")
endif()

# ── plugin.json ──────────────────────────────────────────────────────────────
if(NOT EXISTS "${CMAKE_SOURCE_DIR}/plugin.json")
    message(FATAL_ERROR "plugin.json not found in ${CMAKE_SOURCE_DIR}.")
endif()

function(extract_var_from_file out_var file_path var_name)
    file(READ "${file_path}" _json_content)
    string(JSON _value ERROR_VARIABLE _err GET "${_json_content}" ${var_name})
    if(_err)
        message(FATAL_ERROR "Key '${var_name}' not found in ${file_path}")
    endif()
    set(${out_var} "${_value}" PARENT_SCOPE)
endfunction()

extract_var_from_file(CS_PLUGIN_VERSION "${CMAKE_SOURCE_DIR}/plugin.json" CS_PLUGIN_VERSION)
extract_var_from_file(CS_PLUGIN_NAME    "${CMAKE_SOURCE_DIR}/plugin.json" CS_PLUGIN_NAME)

string(REGEX MATCH "^[0-9]+" SDK_VERSION "${CS_PLUGIN_VERSION}")

# ── Fetch CircuitSim SDK ──────────────────────────────────────────────────────
if(NOT TARGET Common)
    set_property(GLOBAL PROPERTY CIRCUIT_SIM_PLUGIN_DEVELOPMENT_TARGET ${CS_PLUGIN_NAME})
    message(STATUS "Fetching CircuitSim SDK v${SDK_VERSION}...")

    FetchContent_Declare(
        SDK
        GIT_REPOSITORY "${_CS_REPO_URL}"
        GIT_TAG        v${SDK_VERSION}
        SOURCE_DIR     "${CMAKE_SOURCE_DIR}/SDK"
        GIT_SHALLOW    TRUE
    )
    FetchContent_MakeAvailable(SDK)
endif()

# ── Pull in SDK macros ────────────────────────────────────────────────────────
include("${CMAKE_SOURCE_DIR}/SDK/cmake/SetupCircuitSimPlugin.cmake")