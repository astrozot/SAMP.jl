struct SAMPClient{H<:AbstractSAMPHub}
    hub::H
    name::String
    key::String
    hub_id::String
    client_id::String
    translator::String
end

function SAMPClient(hub::SAMPHub, name::String)
    registration = hub.proxy["samp.hub.register"](hub.secret)
    key = registration["samp.private-key"]
    hub_id = registration["samp.hub-id"]
    client_id = registration["samp.self-id"]
    SAMPClient(hub, name, key, hub_id, client_id, "")
end

function SAMPClient(hub::SAMPWebHub, name::String)
    registration = hub.proxy["samp.webhub.register"](Dict("samp.name" => name))
    key = registration["samp.private-key"]
    hub_id = registration["samp.hub-id"]
    client_id = registration["samp.self-id"]
    translator = registration["samp.url-translator"]
    SAMPClient(hub, name, key, hub_id, client_id, translator)
end

methodPrefix(::SAMPClient{SAMPHub}) = "samp.hub"
methodPrefix(::SAMPClient{SAMPWebHub}) = "samp.webhub"

function register(hub::AbstractSAMPHub, name::String; kw...)
    client = SAMPClient(hub, name)
    if length(kw) > 0
        setMetadata(client; kw...)
    end
    client
end

function unregister(client::SAMPClient)
    methodName = "$(methodPrefix(client)).unregister"
    client.hub.proxy[methodName](client.key)
end

const metadata_aliases = Dict(
    "name" => "samp.name", 
    "description" => "samp.description.text",
    "version" => "samp.version",
    "icon" => "samp.icon.url",
    "documentation" => "samp.documentation.url")

function setMetadata(client::SAMPClient; kw...)
    metadata = Dict("samp.name" => client.name)
    for (k, v) ∈ kw
        sk = string(k)
        metadata[get(metadata_aliases, sk, sk)] = string(v)
    end
    methodName = "$(methodPrefix(client)).declareMetadata"
    client.hub.proxy[methodName](client.key, metadata)
end

declareMetadata(client::SAMPClient; kw...) = setMetadata(client; kw...)

function getMetadata(client::SAMPClient, client_id=client.client_id)
    methodName = "$(methodPrefix(client)).getMetadata"
    client.hub.proxy[methodName](client.key, client_id)
end

function getSubscriptions(client::SAMPClient, client_id)
    methodName = "$(methodPrefix(client)).getSubscriptions"
    collect(keys(client.hub.proxy[methodName](client.key, client_id)))
end

function getRegisteredClients(client::SAMPClient)
    methodName = "$(methodPrefix(client)).getRegisteredClients"
    client.hub.proxy[methodName](client.key)
end

function getSubscribedClients(client::SAMPClient, mtype::String)
    methodName = "$(methodPrefix(client)).getSubscribedClients"
    collect(keys(client.hub.proxy[methodName](client.key, mtype)))
end

function Base.notify(client::SAMPClient, dest::String, mtype::String; kw...)
    methodName = "$(methodPrefix(client)).notify"
    client.hub.proxy[methodName](client.key, dest, Dict("samp.mtype" => mtype, "samp.params" => kw))
end

function notifyAll(client::SAMPClient, mtype::String; kw...)
    methodName = "$(methodPrefix(client)).notifyAll"
    client.hub.proxy[methodName](client.key, Dict("samp.mtype" => mtype, "samp.params" => kw))
end

function callAndWait(client::SAMPClient, dest::String, mtype::String; timeout=0, kw...)
    methodName = "$(methodPrefix(client)).callAndWait"
    SAMPResult(client.hub.proxy[methodName](client.key, dest, Dict("samp.mtype" => mtype, "samp.params" => kw), string(timeout)))
end
