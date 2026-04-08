include(FetchContent)
set(CMAKE_POLICY_VERSION_MINIMUM 3.5) # Since glad v1 is too old, and modern glad v2 is a generator

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(FETCHCONTENT_BASE_DIR "${CMAKE_SOURCE_DIR}/.deps" CACHE PATH "")
set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1)

if(MSVC)
    set(CMAKE_MSVC_RUNTIME_LIBRARY
        "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL"
        CACHE STRING "" FORCE)
endif()

# Optional read-only GitHub token for accessing the private CircuitSim repository.
# Can be set via -DCIRCUITSIM_ACCESS_TOKEN=<token> on the cmake command line,
# or via the CIRCUITSIM_ACCESS_TOKEN environment variable.
if(NOT DEFINED CIRCUITSIM_ACCESS_TOKEN OR CIRCUITSIM_ACCESS_TOKEN STREQUAL "")
    if(DEFINED ENV{CIRCUITSIM_ACCESS_TOKEN} AND NOT "$ENV{CIRCUITSIM_ACCESS_TOKEN}" STREQUAL "")
        set(CIRCUITSIM_ACCESS_TOKEN "$ENV{CIRCUITSIM_ACCESS_TOKEN}" CACHE STRING "GitHub token for accessing the private CircuitSim repository" FORCE)
    else()
        set(CIRCUITSIM_ACCESS_TOKEN "" CACHE STRING "GitHub token for accessing the private CircuitSim repository")
    endif()
endif()

# Build the authenticated repository URL if a token was provided
if(NOT CIRCUITSIM_ACCESS_TOKEN STREQUAL "")
    set(_CS_REPO_URL "https://${CIRCUITSIM_ACCESS_TOKEN}@github.com/Cooble/circuitsim")
else()
    set(_CS_REPO_URL "https://github.com/Cooble/circuitsim")
endif()


# Helper: read a single JSON key from a file using CMake's built-in string(JSON ...) command.
function(extract_var_from_file out_var file_path var_name)
    file(READ "${file_path}" _json_content)

    string(JSON _value ERROR_VARIABLE _err GET "${_json_content}" ${var_name})

    if(_err)
        message(WARNING "Key '${var_name}' not found in ${file_path}")
        set(${out_var} "" PARENT_SCOPE)
    else()
        set(${out_var} "${_value}" PARENT_SCOPE)
    endif()
endfunction()


macro(verify_package_file)
    # Error if package.json is not found
    if(NOT EXISTS "${CMAKE_SOURCE_DIR}/package.json")
        message(FATAL_ERROR "package.json not found in ${CMAKE_SOURCE_DIR}. Please create a package.json file with CS_PLUGIN_VERSION and CS_PLUGIN_NAME defined.")
    endif()
    # Read CS_PLUGIN_VERSION and CS_PLUGIN_NAME from the JSON file
    extract_var_from_file(CS_PLUGIN_VERSION "${CMAKE_SOURCE_DIR}/package.json" CS_PLUGIN_VERSION)
    extract_var_from_file(CS_PLUGIN_NAME    "${CMAKE_SOURCE_DIR}/package.json" CS_PLUGIN_NAME)

    # Error if CS_PLUGIN_VERSION or CS_PLUGIN_NAME is not defined
    if(NOT DEFINED CS_PLUGIN_VERSION OR CS_PLUGIN_VERSION STREQUAL "" OR
       NOT DEFINED CS_PLUGIN_NAME    OR CS_PLUGIN_NAME    STREQUAL "")
        message(FATAL_ERROR "CS_PLUGIN_VERSION and CS_PLUGIN_NAME must be defined in package.json")
    endif()

    # Extract the first number from <sdk>.<major>.<minor> as the SDK version
    string(REGEX MATCH "^[0-9]+" SDK_VERSION ${CS_PLUGIN_VERSION})

    ## Check that the SDK tag exists in the remote
    execute_process(
        COMMAND git ls-remote --heads --tags ${_CS_REPO_URL} v${SDK_VERSION}
        RESULT_VARIABLE GIT_CHECK_RESULT
        OUTPUT_VARIABLE GIT_CHECK_OUTPUT
        ERROR_QUIET
    )

    if(GIT_CHECK_RESULT OR "${GIT_CHECK_OUTPUT}" STREQUAL "")
        message(FATAL_ERROR
            "\n"
            "CircuitSim SDK reference '${SDK_VERSION}' does not exist.\n"
            "It must be a valid tag, branch, or commit hash.\n"
            "Please check CS_PLUGIN_VERSION in package.json.\n"
        )
    endif()
endmacro()
verify_package_file()



# Macro to wire a plugin target into the CircuitSim build system.
macro(setup_circuitsim_package target)
    
    # Only fetch the SDK when this plugin is the top-level project.
    # When the SDK is the main project and the plugin is a sub-project, Common is
    # already a target – no need to fetch again.
    if(NOT TARGET Common)
        set_property(GLOBAL PROPERTY CIRCUIT_SIM_PLUGIN_DEVELOPMENT_TARGET  ${CS_PLUGIN_NAME})

        message(STATUS "Target Common not detected: Running as the main plugin project, fetching SDK")
        FetchContent_Declare(
            SDK
            GIT_REPOSITORY "${_CS_REPO_URL}"
            GIT_TAG        v${SDK_VERSION}
            SOURCE_DIR     ${CMAKE_SOURCE_DIR}/SDK
            GIT_SHALLOW    TRUE
        )
        FetchContent_MakeAvailable(SDK)

        # Expose the main plugin name to all translation units so that SDK headers
        # (e.g. Circuit.hpp) can build type strings like "<plugin>/<circuit>".
        target_compile_definitions(${target} PRIVATE CS_MAIN_PLUGIN_NAME="${CS_PLUGIN_NAME}")
        target_compile_definitions(CircuitSim PRIVATE CS_MAIN_PLUGIN_NAME="${CS_PLUGIN_NAME}")
    endif()

    target_link_libraries(${target} PUBLIC Common)
    add_dependencies(CircuitSim ${target})

    # Define CS_PLUGIN_NAME so the CIRCUIT_TYPE() macro in Circuit.hpp compiles.
    target_compile_definitions(${target} PRIVATE CS_PLUGIN_NAME="${CS_PLUGIN_NAME}")
    target_compile_definitions(${target} PUBLIC CS_PLUGIN_NAME_RAW=${CS_PLUGIN_NAME})

    # Exporting the plugin API (DLL export)
    include(GenerateExportHeader)
    generate_export_header(${target}
        EXPORT_FILE_NAME cs_plugin_api.h
        EXPORT_MACRO_NAME  CS_PLUGIN_API
    )
    target_include_directories(${target} PUBLIC "${CMAKE_CURRENT_BINARY_DIR}")

    set_target_properties(${target} PROPERTIES
        CXX_VISIBILITY_PRESET hidden
        VISIBILITY_INLINES_HIDDEN 1
    )

    copyDllToExportFolder(${target})

    # Casing pin headers generation
    include(${CMAKE_SOURCE_DIR}/SDK/cmake/GenerateCasHeaders.cmake)
    generate_cas_headers(
        PACKAGE_DIR  "${CMAKE_CURRENT_SOURCE_DIR}/.."
        OUTPUT_DIR  "${CMAKE_BINARY_DIR}/generated/cas_pins_${CS_PLUGIN_NAME}"
    )
    target_include_directories(${target} PUBLIC "${CMAKE_BINARY_DIR}/generated/cas_pins_${CS_PLUGIN_NAME}")
endmacro()

macro(copyDllToExportFolder target)
    set(EXPORT_DIR "${CMAKE_SOURCE_DIR}/export")

    # Create the directory if it doesn't exist
    add_custom_command(TARGET ${target} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "${EXPORT_DIR}")

    add_custom_command(TARGET ${target} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<TARGET_FILE:${target}>"
            "${EXPORT_DIR}/$<TARGET_FILE_NAME:${target}>"
        COMMENT "Deploying ${target} binary to: ${EXPORT_DIR}"
        VERBATIM
    )

    # Copy the PDB (Windows only)
    if(MSVC)
        add_custom_command(TARGET ${target} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "$<TARGET_PDB_FILE:${target}>"
                "${EXPORT_DIR}/$<TARGET_PDB_FILE_NAME:${target}>"
            COMMAND_EXPAND_LISTS
            VERBATIM
        )
    endif()
endmacro()