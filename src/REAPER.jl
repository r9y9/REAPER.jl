module REAPER

export
    # High level interface
    reaper,

    # Low-level interface
    EpochTracker,
    init,
    compute_features,
    track_epochs,
    get_epoch,
    get_f0_and_corr


const libreaper = joinpath(Pkg.dir("REAPER"), "deps", "REAPER", "build", "libreaper")

try
    dlopen(libreaper)
catch e
    rethrow(e)
end

type EpochTracker
    ptr::Ptr{Void}

    function EpochTracker()
        p = new(ccall((:CreateEpochTracker, libreaper), Ptr{Void}, ()))
        finalizer(p, p -> ccall((:DestroyEpochTracker, libreaper),
                                Void, (Ptr{Void},), p.ptr))
        return p
    end
end

type Track
    ptr::Ptr{Void}

    function Track()
        p = new(ccall((:CreateTrack, libreaper), Ptr{Void}, ()))
        finalizer(p, p -> ccall((:DestroyTrack, libreaper),
                                Void, (Ptr{Void},), p.ptr))
        return p
    end
end

function nframes(t::Track)
    ccall((:GetTrackNumFrames, libreaper), Int,(Ptr{Void},), t.ptr)
end

function get_track_times(track::Track)
    times = Array(Float32, nframes(track))
    ccall((:GetTrackTimes, libreaper), Void,
          (Ptr{Void}, Ptr{Float32}), track.ptr, times)
    times
end

function get_track_voiced_flags(track::Track)
    flags = Array(Int32, nframes(track))
    ccall((:GetTrackTimes, libreaper), Void,
          (Ptr{Void}, Ptr{Int32}), track.ptr, flags)
    flags
end

function get_track_values(track::Track)
    values = Array(Float32, nframes(track))
    ccall((:GetTrackValues, libreaper), Void,
          (Ptr{Void}, Ptr{Float32}), track.ptr, values)
    values
end

function init(et::EpochTracker, x::Vector{Int16}, fs,
              minf0::Float64=40.0,
              maxf0::Float64=500.0,
              do_high_pass::Bool=true,
              do_hilbert_transform::Bool=true,
              inter_pulse::Float64=0.01,
              frame_period::Float64=0.005)
    ccall((:InitEpochTracker, libreaper), Bool,
          (Ptr{Void}, Ptr{Int16}, Int32, Float32, Float32, Float32,
          Bool, Bool), et.ptr, x, length(x), fs, minf0, maxf0,
          do_high_pass, do_hilbert_transform)
end

function compute_features(et::EpochTracker)
    ccall((:ComputeFeatures, libreaper), Bool, (Ptr{Void},), et.ptr)
end

function track_epochs(et::EpochTracker)
    ccall((:TrackEpochs, libreaper), Bool, (Ptr{Void},), et.ptr)
end

function get_epoch_track(et::EpochTracker, inter_pulse::Float64)
    pm_track = Track()
    ccall((:GetEpochTrack, libreaper), Bool,
          (Ptr{Void}, Float32, Ptr{Void}), et.ptr, inter_pulse, pm_track.ptr)
    pm_track
end

function get_epoch(et::EpochTracker, inter_pulse::Float64)
    pm_track = get_epoch_track(et, inter_pulse)
    n = nframes(pm_track)

    pm_times = get_track_times(pm_track)
    pm = get_track_voiced_flags(pm_track)

    pm_times, pm
end

function get_f0_and_corr_track(et::EpochTracker, frame_period::Float64)
    f0_track = Track()
    corr_track = Track()

    ok = ccall((:GetF0AndCorrTrack, libreaper), Bool,
               (Ptr{Void}, Float32, Ptr{Void}, Ptr{Void}),
               et.ptr, frame_period, f0_track.ptr, corr_track.ptr)
    !ok && error("EpochTracker GetF0AndCorrTrack faild")

    f0_track, corr_track
end

function get_f0_and_corr(et::EpochTracker, frame_period::Float64)
    f0_track, corr_track = get_f0_and_corr_track(et, frame_period)
    times = get_track_times(f0_track)
    f0 = get_track_values(f0_track)
    corr = get_track_values(corr_track)

    times, f0, corr
end

function reaper(x::Vector{Int16}, fs;
                minf0::Float64=40.0,
                maxf0::Float64=500.0,
                do_high_pass::Bool=true,
                do_hilbert_transform::Bool=true,
                inter_pulse::Float64=0.01,
                frame_period::Float64=0.005)
    et = EpochTracker()

    ok = init(et, x, fs, minf0, maxf0, do_high_pass, do_hilbert_transform)
    !ok && error("EpochTracker init failed")

    ok = compute_features(et)
    !ok && error("EpochTracker compute_features failed")

    ok = track_epochs(et)
    !ok && error("EpochTracker track_epochs failed")

    pm_times, pm = get_epoch(et, inter_pulse)
    f0_times, f0, corr = get_f0_and_corr(et, frame_period)

    pm_times, pm, f0_times, f0, corr
end

end # module
