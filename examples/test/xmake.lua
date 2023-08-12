add_rules("mode.debug", "mode.release")

add_requires("test")

target("example")
    set_kind("binary")
    add_files("*.c")
    add_packages("test")
