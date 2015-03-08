using REAPER
using Base.Test

x = int16(vec(readdlm(joinpath(dirname(@__FILE__), "test16k.txt"))))
const fs = 16000
@assert length(x) == 60700
@assert isa(x, Vector{Int16})

pm_times, pm, f0_times, f0, corr = reaper(x, fs)
@test !any(isnan(pm_times))
@test !any(isnan(pm))
@test !any(isnan(f0_times))
@test !any(isnan(f0))
@test !any(isnan(corr))
@test length(pm_times) == length(pm)
@test length(f0_times) == length(f0) == length(corr)
