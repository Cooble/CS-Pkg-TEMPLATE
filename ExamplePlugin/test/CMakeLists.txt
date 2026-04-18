cmake_minimum_required(VERSION 3.16.1)
project("ExamplePlugin_Tests")



# -----------------------------
# Test Executable
# -----------------------------

set (TEST_SOURCES
    src/test_example.cpp
)

add_executable(${PROJECT_NAME} ${TEST_SOURCES})
target_include_directories(${PROJECT_NAME} PRIVATE "src")


# Register tests against the Plugin
include("${CMAKE_SOURCE_DIR}/SDK/cmake/cs_test.cmake")
cs_add_integration_test(${PROJECT_NAME} ExamplePlugin)