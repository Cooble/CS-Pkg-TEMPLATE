project("ExamplePlugin")


file(GLOB_RECURSE all_source_files CONFIGURE_DEPENDS
	"src/*.cpp"
    "src/*.hpp"
)

add_library(${PROJECT_NAME} OBJECT ${all_source_files})
	
target_include_directories(${PROJECT_NAME} PUBLIC
	"src"
)

cs_add_plugin(${PROJECT_NAME}
    FOUNDRY        ExampleFoundry
    FOUNDRY_HEADER "start.hpp")

if(CS_TESTING_ENABLED)
    add_subdirectory(test)
endif()
