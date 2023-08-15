add_rules("mode.debug", "mode.release")

add_requires("python", {system = false})

target("pytest")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("python")
