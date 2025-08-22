abstract type AbstractSAMPHub end

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
        proxy["samp.hub.ping"]()
        secret = conf["samp.secret"]
        version = conf["samp.profile.version"]
        new(proxy, url, secret, version, conf)
    end
end

ping(hub::SAMPHub) = hub.proxy["samp.hub.ping"]()
methodPrefix(::SAMPHub) = "samp.hub"

struct SAMPWebHub <: AbstractSAMPHub
    proxy::XMLRPC.Proxy
    url::String
    function SAMPWebHub()
        url = "http://localhost:21012/"
        proxy = XMLRPC.Proxy(url)
        proxy["samp.webhub.ping"]()
        new(proxy, url)
    end
end

ping(hub::SAMPWebHub) = hub.proxy["samp.webhub.ping"]()
methodPrefix(::SAMPWebHub) = "samp.webhub"
