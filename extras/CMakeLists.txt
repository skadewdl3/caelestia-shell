# Version
add_executable(version version.cpp)
target_compile_definitions(version PRIVATE
    PROJECT_NAME="${PROJECT_NAME}"
    VERSION="${VERSION}"
    GIT_REVISION="${GIT_REVISION}"
    DISTRIBUTOR="${DISTRIBUTOR}"
)
install(TARGETS version DESTINATION "${INSTALL_LIBDIR}")

# Small runtime adapter for Swappy's GTK UI. This keeps the post-capture
# workflow downstream-friendly without carrying a fork of Swappy itself.
add_library(swappy-ui SHARED swappy-ui.cpp)
target_link_libraries(swappy-ui PRIVATE "${CMAKE_DL_LIBS}")
set_target_properties(swappy-ui PROPERTIES OUTPUT_NAME caelestia-swappy-ui)
install(TARGETS swappy-ui DESTINATION "${INSTALL_LIBDIR}")
