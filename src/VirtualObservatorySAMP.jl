module VirtualObservatorySAMP

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

end
