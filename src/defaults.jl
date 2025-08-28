"""
    defaultHub::Union{SAMPHub,Nothing}

The default hub.

Can be obtained (and set, if it is `nothing`) using [`getHub`](@ref).
"""
defaultHub::Union{SAMPHub,Nothing} = nothing

"""
    defaultClient::Union{SAMPClient,Nothing}

The default client.

Can be obtained (and set, if it is `nothing`) using [`getClient`](@ref).
"""
defaultClient::Union{SAMPClient,Nothing} = nothing

"""
    getHub()

Return the default hub.

This function also sets it the first time it is called.
"""
function getHub()
    global defaultHub
    if isnothing(defaultHub)
        defaultHub = SAMPHub()
    end
    defaultHub
end

"""
    getClient()

Return the default client.

This function also sets it the first time it is called.
"""
function getClient()::SAMPClient{SAMPHub}
    global defaultClient
    if isnothing(defaultClient)
        defaultClient = register(getHub(), "Julia"; description="Julia default client",
            version="1.0.0", var"julia.pid" = getpid())
    end
    defaultClient
end

function unregister()
    global defaultClient
    unregister(getClient())
    defaultClient = nothing
end

