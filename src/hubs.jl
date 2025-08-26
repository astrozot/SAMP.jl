"""
The parent of [`SAMPHub`](@ref) and [`SAMPWebHub`](@ref).
"""
abstract type AbstractSAMPHub end

"""
    SAMPHub <: [`AbstractSAMPHub`](@ref)

A local SAMP hub.

Can be created by a simple call `SAMPHub()`: all fields are automatically set
following the SAMP protocol.

# Members
- proxy: the XMLRPC proxy associated with the hub
- url: the hub URL
- secret: the hub secret (used for the client registration)
- version: the hub version, as a string
- conf: a dictionary with all hub configuration parameters
"""
struct SAMPHub <: AbstractSAMPHub
    proxy::XMLRPC.Proxy
    url::String
    secret::String
    version::String
    conf::Dict{String,String}
    function SAMPHub()
        # Check if the SAMP_HUB environment is set
        if haskey(ENV, "SAMP_HUB")
            samp_hub = ENV["SAMP_HUB"]
            if !startswith(samp_hub, "std-lockurl:")
                @warn "The environment variable `SAMP_HUB` should start with `std-lockurl:`"
                content = readlines(samp_hub)
            else
                url = samp_hub[13:end]
                content = load_url_content(url)
            end
        else
            localfile = joinpath(homedir(), ".samp")
            if isreadable(localfile)
                content = readlines(localfile)
            else
                # Try a WEB host
                response = HTTP.get("http://localhost:21012/")
                # FIXME: TODO
            end
        end
        # Parse the lockfile
        conf = Dict{String,String}()
        for line ∈ content
            if length(line) > 0 && line[1] == "#"
                continue
            end
            if occursin("=", line)
                name, value = split(line, "=")
                conf[string(name)] = string(value)
            end 
        end
        url = conf["samp.hub.xmlrpc.url"]
        proxy = XMLRPC.Proxy(url)
        @robust proxy["samp.hub.ping"]()
        secret = conf["samp.secret"]
        version = conf["samp.profile.version"]
        new(proxy, url, secret, version, conf)
    end
end

"""
    ping(hub)

Ping the `hub`.

This function retunrs `nothing` if the hub can be pinged; otherwise, an error
is thrown.
"""
ping(hub::SAMPHub) = (@robust hub.proxy["samp.hub.ping"](); nothing)

"""
    methodPrefix(hub)
    methodPrefix(client)

Return "samp.hub" or "samp.webhub" depending on the hub type.
"""
methodPrefix(::SAMPHub) = "samp.hub"

"""
    SAMPWebHub <: [`AbstractSAMPHub`](@ref)

A Web SAMP hub.

Can be created by a simple call `SAMPWebHub()`: all fields are automatically set
following the SAMP protocl.

# Members
- proxy: the XMLRPC proxy associated with the hub
- url: the hub URL (always equal to "http://localhost:21012/")
"""
struct SAMPWebHub <: AbstractSAMPHub
    proxy::XMLRPC.Proxy
    url::String
    function SAMPWebHub()
        url = "http://localhost:21012/"
        proxy = XMLRPC.Proxy(url)
        @robust proxy["samp.webhub.ping"]()
        new(proxy, url)
    end
end

ping(hub::SAMPWebHub) = (hub.proxy["samp.webhub.ping"](); nothing)
methodPrefix(::SAMPWebHub) = "samp.webhub"
