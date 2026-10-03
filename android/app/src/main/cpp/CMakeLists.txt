cmake_minimum_required(VERSION 3.22)
project(tvvnc LANGUAGES C CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
get_filename_component(DEPS "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../native" ABSOLUTE)

include(ExternalProject)
set(JPEG_BUILD "${CMAKE_CURRENT_BINARY_DIR}/jpeg")
ExternalProject_Add(jpeg-build
  SOURCE_DIR "${DEPS}/libjpeg-turbo"
  BINARY_DIR "${JPEG_BUILD}"
  CMAKE_ARGS
    "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
    "-DANDROID_ABI=${ANDROID_ABI}" "-DANDROID_PLATFORM=${ANDROID_PLATFORM}"
    "-DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}"
    "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
    "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
    "-DENABLE_SHARED=OFF" "-DENABLE_STATIC=ON" "-DWITH_TOOLS=OFF"
    "-DWITH_TESTS=OFF" "-DWITH_TURBOJPEG=OFF" "-DBUILD=20260920"
  BUILD_COMMAND "${CMAKE_COMMAND}" --build <BINARY_DIR> --target jpeg-static --parallel 2
  INSTALL_COMMAND ""
  BUILD_BYPRODUCTS "${JPEG_BUILD}/libjpeg.a")
add_library(jpeg-static STATIC IMPORTED GLOBAL)
set_target_properties(jpeg-static PROPERTIES IMPORTED_LOCATION "${JPEG_BUILD}/libjpeg.a")
add_dependencies(jpeg-static jpeg-build)
set(JPEG_LIBRARY "${JPEG_BUILD}/libjpeg.a" CACHE FILEPATH "" FORCE)
set(JPEG_INCLUDE_DIR "${DEPS}/libjpeg-turbo/src" CACHE PATH "" FORCE)

set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(WITH_LIBVNCSERVER OFF CACHE BOOL "" FORCE)
set(WITH_LIBVNCCLIENT ON CACHE BOOL "" FORCE)
set(LIBVNCSERVER_INSTALL OFF CACHE BOOL "" FORCE)
foreach(option WITH_EXAMPLES WITH_TESTS WITH_SDL WITH_GTK WITH_QT WITH_FFMPEG
  WITH_PNG WITH_LIBSSHTUNNEL WITH_GNUTLS WITH_OPENSSL WITH_GCRYPT WITH_SYSTEMD
  WITH_SASL WITH_XCB WITH_WEBSOCKETS WITH_TIGHTVNC_FILETRANSFER)
  set(${option} OFF CACHE BOOL "" FORCE)
endforeach()
add_subdirectory("${DEPS}/libvncserver" vnc EXCLUDE_FROM_ALL)
target_include_directories(vncclient PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/jpeg")
add_dependencies(vncclient jpeg-build)

add_library(tvvnc SHARED vnc_bridge.cpp)
target_include_directories(tvvnc PRIVATE "${DEPS}/libvncserver/include" "${CMAKE_CURRENT_BINARY_DIR}/vnc/include")
target_link_libraries(tvvnc PRIVATE vncclient jpeg-static android jnigraphics log)
target_link_options(tvvnc PRIVATE "-Wl,-z,max-page-size=16384")
