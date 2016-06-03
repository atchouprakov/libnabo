cmake_minimum_required(VERSION 3.0)

set(LIB_NAME nabo)
project("${LIB_NAME}" VERSION 1.0.6)

set(D4D_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../D4DWand") 
include("${D4D_ROOT}/1stParty/Cmake/D4DCommonConfig.cmake")
include(D4DCreateProjectConfig)



# Extract version from header
#set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR})
execute_process(
	COMMAND grep "NABO_VERSION " nabo/nabo.h
	WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
	RESULT_VARIABLE GREP_VERSION_RESULT
	OUTPUT_VARIABLE PROJECT_VERSION
	OUTPUT_STRIP_TRAILING_WHITESPACE
)



# Documentation
# Switch on warnings.


# main nabo lib
set(NABO_SRC
	nabo/nabo.cpp
	nabo/brute_force_cpu.cpp
	nabo/kdtree_cpu.cpp
	nabo/kdtree_opencl.cpp
)
set(SHARED_LIBS "false" CACHE BOOL "To build shared (true) or static (false) library")
if (SHARED_LIBS)
	add_library(${LIB_NAME} SHARED ${NABO_SRC})
else(SHARED_LIBS)
	add_library(${LIB_NAME} ${NABO_SRC})
	add_definitions(-fPIC)
endif(SHARED_LIBS)
set_target_properties(${LIB_NAME} PROPERTIES VERSION "${PROJECT_VERSION}" SOVERSION 1)

# create doc before installing
#set(DOC_INSTALL_TARGET "share/doc/${PROJECT_NAME}/api" CACHE STRING "Target where to install doxygen documentation")
#add_dependencies(${LIB_NAME} doc)
target_include_directories(${PROJECT_NAME} 
    PRIVATE 
        include  
        ${Boost_INCLUDE_DIRS}
		${EIGEN3_INCLUDE_DIR}
	PUBLIC
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include> 
	    $<INSTALL_INTERFACE:include/${PROJECT_NAME}> 
		$<INSTALL_INTERFACE:include> 

        )
set_target_properties(${PROJECT_NAME} PROPERTIES
	PUBLIC_HEADER 
	nabo/nabo.h
	DESTINATION ${INSTALL_INCLUDE_DIR}/nabo
)
#install(FILES README.md DESTINATION share/doc/${PROJECT_NAME})
if (DOXYGEN_FOUND)
	install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/doc/html DESTINATION ${DOC_INSTALL_TARGET})
endif(DOXYGEN_FOUND)


install(TARGETS ${PROJECT_NAME} EXPORT ${PROJECT_NAME}Targets
			    LIBRARY DESTINATION lib/\@CMAKE_INSTALL_CONFIG_NAME@ COMPONENT Devel
			    ARCHIVE DESTINATION lib/\@CMAKE_INSTALL_CONFIG_NAME@ COMPONENT Devel
			    RUNTIME DESTINATION bin/\@CMAKE_INSTALL_CONFIG_NAME@ COMPONENT Devel
			    PUBLIC_HEADER DESTINATION include/${PROJECT_NAME} COMPONENT Devel #since it is a static lib, it is only installed as a develepment component
			    INCLUDES DESTINATION include/${PROJECT_NAME}
)
D4D_create_project_config(
	TARGETS ${PROJECT_NAME}
	DEPENDENCIES 
	NAMESPACE pointmatch::
)
# enable_testing()

# add_subdirectory(examples)
# add_subdirectory(tests)
# add_subdirectory(python)

# Install catkin package.xml
# install(FILES package.xml DESTINATION share/libnabo)

# #=============================================
# # to allow find_package() on libnabo
# #=============================================
# # 
# # the following case be used in an external project requiring libnabo:
# #  ...
# #  find_package(libnabo) 
# #  include_directories(${libnabo_INCLUDE_DIRS}) 
# #  target_link_libraries(executableName ${libnabo_LIBRARIES})
# #  ...

# # NOTE: the following will support find_package for 1) local build (make) and 2) for installed files (make install)

# # 1- local build #

# # Register the local build in case one doesn't use "make install"
# export(PACKAGE libnabo)

# # Create variable with the library location
# get_property(libnabo_library TARGET ${LIB_NAME} PROPERTY LOCATION)

# # Create variable for the local build tree
# get_property(libnabo_include_dirs DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY INCLUDE_DIRECTORIES)
# # Configure config file for local build tree
# configure_file(libnaboConfig.cmake.in
  # "${PROJECT_BINARY_DIR}/libnaboConfig.cmake" @ONLY)

# # 2- installation build #

# # Change the library location for an install location
# get_filename_component(NABO_LIB_NAME ${libnabo_library} NAME)
# set(libnabo_library ${CMAKE_INSTALL_PREFIX}/lib/${NABO_LIB_NAME})

# # Change the include location for the case of an install location
# set(libnabo_include_dirs ${CMAKE_INSTALL_PREFIX}/include)

# # We put the generated file for installation in a different repository (i.e., ./CMakeFiles/)
# configure_file(libnaboConfig.cmake.in
  # "${PROJECT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/libnaboConfig.cmake" @ONLY)

# # The same versioning file can be used for both cases
# configure_file(libnaboConfigVersion.cmake.in
  # "${PROJECT_BINARY_DIR}/libnaboConfigVersion.cmake" @ONLY)

# install(FILES
  # "${PROJECT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/libnaboConfig.cmake"
  # "${PROJECT_BINARY_DIR}/libnaboConfigVersion.cmake"
  # DESTINATION share/libnabo/cmake COMPONENT dev)



# #=============================================
# # Add uninstall target
# #=============================================
# configure_file(
    # "${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in"
    # "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
    # IMMEDIATE @ONLY)

# add_custom_target(uninstall
    # COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)
