cmake_minimum_required(VERSION 3.16.1)
project("ExamplePlugin")


file(GLOB_RECURSE all_source_files
	"src/*.cpp"
    "src/*.hpp"
)

add_library(${PROJECT_NAME} SHARED ${all_source_files})
	
target_include_directories(${PROJECT_NAME} PUBLIC
	"src"
)

cs_add_plugin(${PROJECT_NAME})

add_subdirectory(test)
