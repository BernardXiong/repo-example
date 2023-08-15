package("python")
    set_homepage("https://www.python.org/")
    set_description("The python programming language.")

    add_urls("https://www.python.org/ftp/python/$(version)/Python-$(version).tgz")
    add_versions("2.7.18", "da3080e3b488f648a3d7a4560ddee895284c3380b11d6de75edb986526b9a814")
    add_versions("3.11.3", "1a79f3df32265d9e6625f1a0b31c28eb1594df911403d11f3320ee1da1b3e048")

    set_kind("binary")
    add_deps("libffi", "zlib", {system = false})

    on_load(function (package)
        local version = package:version()

        -- set openssl dep
        package:add("deps", "openssl", "ca-certificates")

        -- set includedirs
        local pyver = ("python%d.%d"):format(version:major(), version:minor())
        package:add("includedirs", path.join("include", pyver))

        -- set python environments
        local PYTHONPATH = package:installdir("lib", pyver, "site-packages")
        package:addenv("PYTHONPATH", PYTHONPATH)
        package:addenv("PATH", "bin")
        package:addenv("PATH", "Scripts")

        if package:config("headeronly") then
            package:set("links", "")
        end
    end)

    on_fetch("fetch")

    on_install(function (package)

        -- init configs
        local configs = {"--enable-ipv6", "--with-ensurepip", "--enable-optimizations"}
        table.insert(configs, "--libdir=" .. package:installdir("lib"))
        table.insert(configs, "--with-platlibdir=lib")
        table.insert(configs, "--datadir=" .. package:installdir("share"))
        table.insert(configs, "--datarootdir=" .. package:installdir("share"))
        table.insert(configs, "--enable-shared=" .. (package:config("shared") and "yes" or "no"))

        -- add openssl libs path for detecting
        local openssl_dir
        local openssl = package:dep("openssl"):fetch()
        if openssl then
            for _, linkdir in ipairs(openssl.linkdirs) do
                if path.filename(linkdir) == "lib" then
                    openssl_dir = path.directory(linkdir)
                    if openssl_dir then
                        break
                    end
                end
            end
        end

        table.insert(configs, "--with-openssl=" .. openssl_dir)

        -- add flags for macOS
        local cppflags = {}
        local ldflags = {}

        -- add pic
        if package:is_plat("linux") and package:config("pic") ~= false then
            table.insert(cppflags, "-fPIC")
        end

        -- add external path for zlib and libffi
        for _, libname in ipairs({"zlib", "libffi"}) do
            local lib = package:dep(libname)
            print("for lib -" .. libname)

            if lib and not lib:is_system() then
                local fetchinfo = lib:fetch({external = false})
                if fetchinfo then
                    for _, includedir in ipairs(fetchinfo.includedirs or fetchinfo.sysincludedirs) do
                        table.insert(cppflags, "-I" .. includedir)
                    end
                    for _, linkdir in ipairs(fetchinfo.linkdirs) do
                        table.insert(ldflags, "-L" .. linkdir)
                    end
                end
            end
        end

        if #cppflags > 0 then
            table.insert(configs, "CPPFLAGS=" .. table.concat(cppflags, " "))
        end
        if #ldflags > 0 then
            table.insert(configs, "LDFLAGS=" .. table.concat(ldflags, " "))
        end

        -- unset these so that installing pip and setuptools puts them where we want
        -- and not into some other Python the user has installed.
        import("package.tools.autoconf").configure(package, configs, {envs = {PYTHONHOME = "", PYTHONPATH = ""}})
        os.vrunv("make", {"-j4", "PYTHONAPPSDIR=" .. package:installdir()})
        os.vrunv("make", {"install", "-j4", "PYTHONAPPSDIR=" .. package:installdir()})
        if package:version():ge("3.0") then
            os.cp(path.join(package:installdir("bin"), "python3"), path.join(package:installdir("bin"), "python"))
            os.cp(path.join(package:installdir("bin"), "python3-config"), path.join(package:installdir("bin"), "python-config"))
        end

        -- install wheel
        local python = path.join(package:installdir("bin"), "python")
        local version = package:version()
        local pyver = ("python%d.%d"):format(version:major(), version:minor())
        local envs = {
            PATH = package:installdir("bin"),
            PYTHONPATH = package:installdir("lib", pyver, "site-packages"),
            LD_LIBRARY_PATH = package:installdir("lib")
        }
        os.vrunv(python, {"-m", "pip", "install", "--upgrade", "--force-reinstall", "pip"}, {envs = envs})
        os.vrunv(python, {"-m", "pip", "install", "wheel"}, {envs = envs})
    end)

    on_test(function (package)
        os.vrun("python --version")
        os.vrun("python -c \"import pip\"")
        os.vrun("python -c \"import setuptools\"")
        os.vrun("python -c \"import wheel\"")
    end)