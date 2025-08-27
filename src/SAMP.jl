module SAMP

using HTTP, URIs

include("utils.jl")
include("xmlrpc.jl")
include("hubs.jl")
include("sampresult.jl")
include("client.jl")
include("defaults.jl")

export SAMPHub, SAMPWebHub, ping, SAMPClient, SAMPClientId,
    register, unregister, 
    declareMetadata, setMetadata, getMetadata, getSubscriptions,
    getRegisteredClients, getSubscribedClients, notify, notifyAll,
    callAndWait, findFirstClient, findAllClients

function __init__()
    atexit(_unregisterAll)
end

function test()
    hub = SAMPHub()
    # hub = SAMPWebHub()
    client = register(hub, "Gravity3.jl";
        description="An effecient gravitational lens modeling software",
        version=v"1.3.1", icon="https://astrozot.github.io/Gravity.jl/assets/logo.png",
        documentation="https://astrozot.github.io/Gravity.jl/")
    ds9 = first(getSubscribedClients(client, "ds9.get"))
    clients = getRegisteredClients(client)
    info = getMetadata(client, ds9)
    println(SAMP.load_url_content(callAndWait(client, ds9, "ds9.get"; cmd="about").value["url"]; delete=true))
end

end
