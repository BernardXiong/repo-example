target("test")
do
    set_kind("$(kind)") -- 自动切换是动态库还是静态库
    add_installfiles("test.h", {prefixdir = "include"}) -- install 时导出 test.h 到 include 目录
    add_files("*.c")

    before_build(function(target)
        local cc, _ = target:tool("cc")
        target:set("toolset", "sh", cc) -- 由于xmake默认用g++去创建动态库，这里可以强制用gcc
        --（加不加都不影响程序运行，但是链接elf时会有警告说找不到libstdc++.so.6）
        -- warning: libstdc++.so.6, needed by libtest.so, not found (try using -rpath or -rpath-link)
    end)
end
