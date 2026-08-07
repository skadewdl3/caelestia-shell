cmake_minimum_required(VERSION 3.19)

if(NOT DEFINED VERSION)
    execute_process(COMMAND git describe --tags --abbrev=0
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        OUTPUT_VARIABLE VERSION
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if("${VERSION}" STREQUAL "")
        message(FATAL_ERROR "VERSION is not set and failed to get from git")
    endif()
endif()

if(NOT DEFINED GIT_REVISION)
    execute_process(COMMAND git rev-parse HEAD
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        OUTPUT_VARIABLE GIT_REVISION
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if("${GIT_REVISION}" STREQUAL "")
        message(FATAL_ERROR "GIT_REVISION is not set and failed to get from git")
    endif()
endif()

string(REGEX REPLACE "^v" "" VERSION "${VERSION}")

project(caelestia-shell VERSION ${VERSION} LANGUAGES CXX)

include(GNUInstallDirs)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

set(DISTRIBUTOR "Unset" CACHE STRING "Distributor")
set(ENABLE_MODULES "extras;plugin;shell;greeter;m3shapes" CACHE STRING "Modules to build/install")
set(INSTALL_LIBDIR "${CMAKE_INSTALL_LIBDIR}/caelestia" CACHE STRING "Library install dir")
set(INSTALL_QMLDIR "${CMAKE_INSTALL_LIBDIR}/qt6/qml" CACHE STRING "QML install dir")
set(INSTALL_QSCONFDIR "${CMAKE_INSTALL_SYSCONFDIR}/xdg/quickshell/caelestia" CACHE STRING "Quickshell config install dir")
set(INSTALL_GREETER_QSCONFDIR "${CMAKE_INSTALL_DATADIR}/caelestia-greeter" CACHE STRING "Greeter Quickshell config install dir")
set(INSTALL_GREETER_LIBEXECDIR "${CMAKE_INSTALL_LIBEXECDIR}/caelestia-greeter" CACHE STRING "Greeter helper install dir")

add_compile_options(
    -Wall -Wextra -Wpedantic -Wshadow -Wconversion
    -Wold-style-cast -Wnull-dereference -Wdouble-promotion
    -Wformat=2 -Wfloat-equal -Woverloaded-virtual
    -Wsign-conversion -Wredundant-decls -Wswitch
    -Wunreachable-code
)

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    add_compile_options(-Wunused-lambda-capture)
endif()

if("extras" IN_LIST ENABLE_MODULES)
    add_subdirectory(extras)
endif()

if("plugin" IN_LIST ENABLE_MODULES)
    add_subdirectory(plugin)
endif()

if("shell" IN_LIST ENABLE_MODULES)
    foreach(dir assets components modules services utils)
        install(DIRECTORY ${dir} DESTINATION "${INSTALL_QSCONFDIR}")
    endforeach()

    install(PROGRAMS assets/wrap_term_launch.sh DESTINATION "${INSTALL_QSCONFDIR}/assets")

    file(READ shell.qml SHELL_QML)
    string(REPLACE "settings.watchFiles: true" "settings.watchFiles: false" SHELL_QML "${SHELL_QML}")
    file(WRITE "${CMAKE_BINARY_DIR}/qml/shell.qml" "${SHELL_QML}")
    install(FILES "${CMAKE_BINARY_DIR}/qml/shell.qml" DESTINATION "${INSTALL_QSCONFDIR}")

    install(FILES LICENSE DESTINATION "${INSTALL_QSCONFDIR}")
endif()

if("greeter" IN_LIST ENABLE_MODULES)
    if(IS_ABSOLUTE "${INSTALL_GREETER_QSCONFDIR}")
        set(GREETER_QSCONFDIR "${INSTALL_GREETER_QSCONFDIR}")
    else()
        set(GREETER_QSCONFDIR "${CMAKE_INSTALL_PREFIX}/${INSTALL_GREETER_QSCONFDIR}")
    endif()

    if(IS_ABSOLUTE "${INSTALL_GREETER_LIBEXECDIR}")
        set(GREETER_LIBEXECDIR "${INSTALL_GREETER_LIBEXECDIR}")
    else()
        set(GREETER_LIBEXECDIR "${CMAKE_INSTALL_PREFIX}/${INSTALL_GREETER_LIBEXECDIR}")
    endif()

    configure_file(
        packaging/greetd/caelestia-greeter.in
        "${CMAKE_BINARY_DIR}/caelestia-greeter"
        @ONLY
    )

    install(PROGRAMS "${CMAKE_BINARY_DIR}/caelestia-greeter" DESTINATION "${CMAKE_INSTALL_BINDIR}")
    install(PROGRAMS
        packaging/greetd/start-session
        packaging/greetd/system-info
        DESTINATION "${INSTALL_GREETER_LIBEXECDIR}"
    )
    install(FILES
        greeter.qml
        LICENSE
        DESTINATION "${INSTALL_GREETER_QSCONFDIR}"
    )
    install(FILES modules/GSFLoader.qml DESTINATION "${INSTALL_GREETER_QSCONFDIR}/modules")
    install(DIRECTORY modules/greeter DESTINATION "${INSTALL_GREETER_QSCONFDIR}/modules")
    install(DIRECTORY assets/google-sans-flex DESTINATION "${INSTALL_GREETER_QSCONFDIR}/assets")
    install(FILES assets/wallpaper.webp DESTINATION "${INSTALL_GREETER_QSCONFDIR}/assets")
    install(FILES
        packaging/greetd/config.example
        packaging/greetd/greetd-config.toml
        DESTINATION "${INSTALL_GREETER_QSCONFDIR}"
    )
    install(FILES packaging/greetd/caelestia-greeter.tmpfiles
        DESTINATION "${CMAKE_INSTALL_LIBDIR}/tmpfiles.d"
        RENAME caelestia-greeter.conf
    )
endif()

if("m3shapes" IN_LIST ENABLE_MODULES)
    message(STATUS "Fetching M3Shapes module")
    include(FetchContent)
    set(M3SHAPES_REV bdc327b29f95394a732baf3c9b19658ba23755b6)
    FetchContent_Declare(
        m3shapes_external
        GIT_REPOSITORY https://github.com/soramanew/m3shapes.git
        GIT_TAG        ${M3SHAPES_REV}
        SOURCE_DIR     "${CMAKE_BINARY_DIR}/_deps/m3shapes-${M3SHAPES_REV}"
    )
    FetchContent_MakeAvailable(m3shapes_external)
    message(STATUS "Done fetching M3Shapes module")

    # Fix m3shapes wrong rpath
    if(TARGET m3shapesplugin)
        set_target_properties(m3shapesplugin PROPERTIES INSTALL_RPATH "$ORIGIN")
    endif()
endif()
