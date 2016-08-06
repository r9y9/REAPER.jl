using REAPER
using Base.Test

import REAPER: Track, nframes

x = map(Int16, vec(readdlm(joinpath(dirname(@__FILE__), "test16k.txt"))))
const fs = 16000
@assert length(x) == 60700
@assert isa(x, Vector{Int16})

## High-level interface

let
    pm_times, pm, f0_times, f0, corr = reaper(x, fs)
    @test !any(isnan(pm_times))
    @test !any(isnan(pm))
    @test !any(isnan(f0_times))
    @test !any(isnan(f0))
    @test !any(isnan(corr))
    @test length(pm_times) == length(pm)
    @test length(f0_times) == length(f0) == length(corr)
end

## Low-level interface

# EpochTracker
let
    et = EpochTracker()
    @test et.ptr != C_NULL
end

# Track
let
    track = Track()
    @test track.ptr != C_NULL
    @test nframes(track) == 0
end

# Confirm no error happens (in C code)
let
    et = EpochTracker()
    ok = init(et, x, fs)
    @test ok
    ok = compute_features(et)
    @test ok
    ok = track_epochs(et)
    @test ok

    inter_pulse = 0.01
    frame_period = 0.005

    pm_times, pm = get_epochs(et, inter_pulse)
    f0_times, f0, corr = get_f0_and_corr(et, frame_period)
end

# skipping init should fail in compute_features
let
    et = EpochTracker()
    # ok = init(et, x, fs)
    ok = compute_features(et)
    @test !ok
end

# skipping track_epochs should fail in get_f0_and_corr
let
    et = EpochTracker()
    ok = init(et, x, fs)
    ok = compute_features(et)
    # ok = track_epochs(et)

    inter_pulse = 0.01
    frame_period = 0.005
    get_epochs(et, inter_pulse)

    @test_throws Exception get_f0_and_corr(et, frame_period)
end

# Use EpochTracker multiple times
# Calling `Init` twice.
# `Init` should reset internal states of the EpochTracker.
let
    et = EpochTracker()
    ok = init(et, x, fs)
    ok = compute_features(et)
    ok = track_epochs(et)

    inter_pulse = 0.01
    frame_period = 0.005

    # First
    pm_times, pm = get_epochs(et, inter_pulse)
    f0_times, f0, corr = get_f0_and_corr(et, frame_period)

    pm_times_copy = copy(pm_times)
    pm_copy = copy(pm)
    f0_times_copy = copy(f0_times)
    f0_copy = copy(f0)
    corr_copy = copy(corr)

    ok = init(et, x, fs)
    @test ok
    ok = compute_features(et)
    @test ok
    ok = track_epochs(et)

    # Second
    pm_times, pm = get_epochs(et, inter_pulse)
    f0_times, f0, corr = get_f0_and_corr(et, frame_period)

    # Expect same results
    @test pm_times == pm_times_copy
    @test pm == pm_copy
    @test f0_times == f0_times
    @test f0 == f0_copy
    @test corr == corr_copy
end
