"""The parent of all SAMP results"""
abstract type SAMPResult end

"""`SAMPSuccess <:`[`SAMPResult`](@ref)

A successful SAMP result

# Field
- `value`: the return value provided
"""
struct SAMPSuccess{T} <: SAMPResult
    value::T
end

"""`SAMPError <:`[`SAMPResult`](@ref)

A faulty SAMP result.

# Fields
- `error`: the error raised, as a string
- `user`: an optional additional user message
- `debug`: an optional longer string which may contain more detail on what
  went wrong. This is typically intended for debugging purposes, and may for
  instance be a stack trace.
- `code`: an optional string containing a numeric or textual code identifying
  the error, perhaps intended to be parsable by software.
"""
struct SAMPError <: SAMPResult
    error::String
    user::String
    debug::String
    code::String
end

"""`SAMPWarning <:`[`SAMPResult`](@ref)

A partially successful SAMP result.

# Fields
- `value`: the value returned
- `warning`: a structure of type [`SAMPError`](@ref), with details on what
  went wrong
"""
struct SAMPWarning{T} <: SAMPResult
    value::T
    warning::SAMPError
end

"""
    SAMPResult(result::AbstractDict)

Build an appropriate [`SAMPResult`](@ref).

The specific instance returned dependings on the `result` fields.
"""
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
