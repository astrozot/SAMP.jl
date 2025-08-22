abstract type SAMPResult end

struct SAMPSuccess{T} <: SAMPResult
    value::T
end

struct SAMPError <: SAMPResult
    error::String
    user::String
    debug::String
    code::String
end

struct SAMPWarning{T} <: SAMPResult
    value::T
    warning::SAMPError
end

function SAMPResult(result::AbstractDict)
    status = result["samp.status"]
    if status == "samp.ok"
        return SAMPSuccess(result["samp.result"])
    elseif status == "samp.error"
        return SAMPError(result["samp.errortxt"], get(result, "samp.usertxt", ""),
            get(result, "samp.debugtxt", ""), get(result, "samp.code", ""))
    elseif status == "samp.warning"
        return SAMPWarning(result["samp.result"], 
            SAMPError(result["samp.errortxt"], get(result, "samp.usertxt", ""),
                get(result, "samp.debugtxt", ""), get(result, "samp.code", "")))
    else
        error("Malformed SAMP response")
    end
end
