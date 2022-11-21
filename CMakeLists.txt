project(zello_world)

add_subdirectory(./src)
include_directories(src)

add_executable(zello_world src/zello_world.cpp)

target_link_libraries(zello_world "ze_loader" ${CMAKE_DL_LIBS})

install (TARGETS zello_world)
