cmake_minimum_required(VERSION 3.16)
project(pkg_extractor CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(ZLIB 1.3 REQUIRED)

add_executable(pkg_extractor
  shadps4/extractor/main.cpp
  shadps4/src/core/loader.cpp
  shadps4/src/core/file_format/pkg.cpp
  shadps4/src/core/file_format/psf.cpp
  shadps4/src/core/file_format/pkg_type.cpp
  shadps4/src/core/crypto/crypto.cpp
  shadps4/src/common/io_file.cpp
  shadps4/src/common/assert.cpp
  shadps4/src/common/error.cpp
  shadps4/src/common/path_util.cpp
  shadps4/src/common/string_util.cpp)

target_include_directories(pkg_extractor PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/shadps4/src"
  "${CMAKE_CURRENT_SOURCE_DIR}")

add_library(libcryptopp STATIC IMPORTED)
set_property(TARGET libcryptopp PROPERTY IMPORTED_LOCATION
  "${CMAKE_CURRENT_SOURCE_DIR}/cryptopp/libcryptopp.a")

target_link_libraries(pkg_extractor PRIVATE libcryptopp ZLIB::ZLIB)
