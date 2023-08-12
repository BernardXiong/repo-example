package("test")
do
    set_description("The test package")

    set_sourcedir(path.join(os.scriptdir(), "src"))

    add_configs("shared", {
        description = "Build shared library.",
        default = os.getenv("RT_XMAKE_LINK_TYPE") ~= "static",
        type = "boolean"
    })

    on_install(function(package)
        import("package.tools.xmake").install(package, {}, {envs = {}})
    end)

    on_test(function(package)
        assert(package:has_cfuncs("test", {includes = "test.h"}))
    end)
end
