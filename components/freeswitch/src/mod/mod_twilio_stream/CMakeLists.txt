cmake_minimum_required(VERSION 3.8)
set(CMAKE_C_COMPILER "gcc")
set(CMAKE_CXX_COMPILER "g++")
project(mod_twilio_stream C CXX)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14 -fno-gnu-unique -fPIC -Wreturn-type")

option(MOD_BUILD_VERSION "Build version" "")

if (MOD_BUILD_VERSION)
    add_definitions ( -DMOD_BUILD_VERSION=\"${MOD_BUILD_VERSION}\" )
endif()

include(FetchContent)

set(FREESWITCH_INCLUDE_DIR "/usr/include/freeswitch" CACHE PATH "Location of FreeSWITCH headers")
set(INSTALL_MOD_DIR "/usr/local/freeswitch/mod" CACHE PATH "Location install library")

if (NOT EXISTS "${FREESWITCH_INCLUDE_DIR}")
    message( SEND_ERROR "Not exists FREESWITCH_INCLUDE_DIR = ${FREESWITCH_INCLUDE_DIR}" )
endif()

find_package(OpenSSL REQUIRED)

FetchContent_Declare(libwebsockets 
GIT_REPOSITORY https://github.com/warmcat/libwebsockets.git
GIT_TAG        v4.3.3
)
FetchContent_MakeAvailable(libwebsockets)

add_library(mod_twilio_stream SHARED 
        src/mod_twilio_stream.c 
        src/audio_pipe.cpp 
        src/lws_glue.cpp
        src/parser.cpp
        src/twilio_helper.cpp)

target_include_directories(
  ${PROJECT_NAME}
  PRIVATE
  include
  ${FREESWITCH_INCLUDE_DIR}
)

target_include_directories(mod_twilio_stream PRIVATE  )
target_link_libraries(mod_twilio_stream PRIVATE websockets)

set_target_properties(mod_twilio_stream PROPERTIES PREFIX "")
set_target_properties(mod_twilio_stream PROPERTIES OUTPUT_NAME "mod_twilio_stream")

install(TARGETS mod_twilio_stream DESTINATION ${INSTALL_MOD_DIR})