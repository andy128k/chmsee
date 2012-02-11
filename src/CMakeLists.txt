include(UseVala)

include_directories(
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_CURRENT_BINARY_DIR}
        ${CHMSEE_INCLUDE_DIRS}
        )
add_definitions(
        ${CHMSEE_CFLAGS_OTHER}
        -DGETTEXT_PACKAGE="ChmSee"
        )

link_directories(
        ${CHMSEE_LIBRARY_DIRS}
        )

vala_precompile(CHMSEE_SRCS
        ${CMAKE_CURRENT_BINARY_DIR}/configuration.vala

        utils.vala
        setup.vala
        chmsee.vala

        models/link.vala
        models/parser.vala
        models/bookmarksfile.vala
        models/chmfile.vala

        components/treeview.vala
        components/index.vala
        components/toc.vala
        components/bookmarks.vala
        components/html-webkit.vala
        components/book.vala

        main.vala
    PACKAGES
        glib-2.0
        gio-2.0
        gee-1.0
        libxml-2.0
        gtk+-2.0
        webkit-1.0
    OPTIONS
        --thread
    CUSTOM_VAPIS
        ../vapi/chm.vapi)

add_executable(chmsee ${CHMSEE_SRCS})
target_link_libraries(chmsee
        ${CHMSEE_LIBRARIES}
        )

install(TARGETS chmsee DESTINATION bin)

