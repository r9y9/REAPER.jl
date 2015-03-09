# build REAPER as a shared library

if !isdir(joinpath(dirname(@__FILE__), "REAPER", "build"))
    cd(Pkg.dir("REAPER"))
    run(`git submodule update --init --recursive`)
end

build_dir = joinpath(Pkg.dir("REAPER"), "deps", "REAPER", "build")
!isdir(build_dir) && mkdir(build_dir)

cd(build_dir)

run(`cmake ..`)
run(`make reaper_wrap`)

# After runing make, REAPER/build/libreaper.so/dylib will be created
try
    dlopen(joinpath(build_dir, "libreaper"))
catch e
    rethrow(e)
end

info("successfully compiled")
