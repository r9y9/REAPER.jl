module REAPER

export reaper

const libreaper = joinpath(Pkg.dir("REAPER"), "deps", "REAPER", "build", "libreaper")

# TODO separate `reaper` to small functions. This is just a demo code.
function reaper(x::Vector{Int16}, fs;
                minf0::Float64=40.0,
                maxf0::Float64=500.0,
                do_high_pass::Bool=true,
                do_hilbert_transform::Bool=true,
                inter_pulse::Float64=0.01,
                frame_period::Float64=0.005)
    et = ccall((:CreateEpochTracker, libreaper), Ptr{Void}, ())

    # Initialization
    ccall((:InitEpochTracker, libreaper), Bool,
          (Ptr{Void}, Ptr{Int16}, Int32, Float32, Float32, Float32,
          Bool, Bool), et, x, length(x), fs, minf0, maxf0,
          do_high_pass, do_hilbert_transform)

    # Computations
    ccall((:ComputeFeatures, libreaper), Bool, (Ptr{Void},), et)
    ccall((:TrackEpochs, libreaper), Bool, (Ptr{Void},), et)

    # Create tracks
    pm_track = ccall((:CreateTrack, libreaper), Ptr{Void}, ())
    f0_track = ccall((:CreateTrack, libreaper), Ptr{Void}, ())
    corr_track = ccall((:CreateTrack, libreaper), Ptr{Void}, ())

    # Store computation results to tracks
    ccall((:GetEpochTrack, libreaper), Bool,
          (Ptr{Void}, Float32, Ptr{Void}), et, inter_pulse, pm_track)
    ccall((:GetF0AndCorrTrack, libreaper), Bool,
          (Ptr{Void}, Float32, Ptr{Void}, Ptr{Void}),
          et, frame_period, f0_track, corr_track)

    pm_nframes = ccall((:GetTrackNumFrames, libreaper), Int,
                       (Ptr{Void},), pm_track)
    f0_nframes = ccall((:GetTrackNumFrames, libreaper), Int,
                       (Ptr{Void},), f0_track)
    corr_nframes = ccall((:GetTrackNumFrames, libreaper), Int,
                         (Ptr{Void},), corr_track)
    @assert f0_nframes == corr_nframes

    # transform C++ `Track` to julia array
    pm_times = Array(Float32, pm_nframes)
    pm = Array(Int32, pm_nframes)
    f0_times = Array(Float32, f0_nframes)
    f0 = Array(Float32, f0_nframes)
    corr = Array(Float32, f0_nframes)

    ccall((:GetTrackTimes, libreaper), Void,
          (Ptr{Void}, Ptr{Float32}), pm_track, pm_times)
    ccall((:GetTrackVoicedFlags, libreaper), Void,
          (Ptr{Void}, Ptr{Int32}), pm_track, pm)

    ccall((:GetTrackTimes, libreaper), Void,
          (Ptr{Void}, Ptr{Float32}), f0_track, f0_times)
    ccall((:GetTrackValues, libreaper), Void,
          (Ptr{Void}, Ptr{Float32}), f0_track, f0)
    ccall((:GetTrackValues, libreaper), Void,
          (Ptr{Void}, Ptr{Float32}), corr_track, corr)

    ccall((:DestroyTrack, libreaper), Void, (Ptr{Void},), pm_track)
    ccall((:DestroyTrack, libreaper), Void, (Ptr{Void},), f0_track)
    ccall((:DestroyTrack, libreaper), Void, (Ptr{Void},), corr_track)

    ccall((:DestroyEpochTracker, libreaper), Void, (Ptr{Void},), et)

    pm_times, pm, f0_times, f0, corr
end

end # module
