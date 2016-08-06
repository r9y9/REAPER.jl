# build REAPER as a shared library

depsdir = joinpath(dirname(@__FILE__))

if !isdir(joinpath(depsdir, "REAPER", "build"))
    cd(depsdir)
    run(`git submodule update --init --recursive`)
end

builddir = joinpath(depsdir, "REAPER", "build")
!isdir(builddir) && mkdir(builddir)

cd(builddir)

run(`cmake ..`)
run(`make reaper_wrap`)

# After runing make, REAPER/build/libreaper.so/dylib will be created
try
    Libdl.dlopen(joinpath(builddir, "libreaper"))
catch e
    rethrow(e)
end

info("successfully compiled")
