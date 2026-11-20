cmake_minimum_required(VERSION 3.22.1)
project(MathaniZipformer LANGUAGES CXX)

if(NOT ANDROID_ABI STREQUAL "arm64-v8a")
    return()
endif()

add_library(mathani_zipformer_qnn SHARED zipformer_qnn.cpp)
target_compile_features(mathani_zipformer_qnn PRIVATE cxx_std_17)
target_include_directories(mathani_zipformer_qnn PRIVATE "${MATHANI_ORT_HEADERS}")
target_link_libraries(mathani_zipformer_qnn PRIVATE dl)
