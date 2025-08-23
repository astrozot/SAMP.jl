"""
`SAMPClient{H <:`[`AbstractSAMPHub`](@ref)`}`

A structure representing a SAMP client.

The same structure is used for clients of a [`SAMPHub`](@ref) or of
[`SAMPWebHub`](@ref).

# Members
- `hub`: the hub server
- `name`: the name of the client (compulsory)
- `key`: a string representing the secret key used by the client to contact
  the server
- `hub_id`: the id the hub has assigned to himself
- `client_id`: the id the hud has assigned to the client
- `translator`: the URL translator (only present if the server is a
  [`SAMPWebHub`](@ref))

# Contructors

    SAMPClient(hub, name)
    register(hub, name [; metadata])

The first form simply create and register the client. The second form,
[`register`](@ref), also accepts metadata as keywords, which will be sent to
the server (see [setMetadata](@ref)).
"""
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

@doc (@doc SAMPClient)
function register(hub::AbstractSAMPHub, name::String; kw...)
    client = SAMPClient(hub, name)
    if length(kw) > 0
        setMetadata(client; kw...)
    end
    client
end

"""
    unregister(client)

Unregister `client` from the associated hub.
"""
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

"""
    setMetadata(client; metadata)
    declareMetadata(client; metadata)

Set the metadata associated with the client.

The metadata are passed as keyword arguments; metadata consisting of non-valid
Julia keywords can be passed with the `var"long.name"` syntax. For example

    setMetadata(client; var"samp.description.text"="A fast FITS image displayer")

Standard metadata can be entered using a shorter syntax. In particular, the
following aliases are recognized

```
name => samp.name
description => samp.description.text
icon => samp.icon.url
documentation => samp.documentation.url
```

Note that, by design, if no icon is provided this function uses a standard
icon; if no icon is desired, enter `icon=""` as keyword parameter.

If this function is called multiple times, the latest metadata are kept (all
the others are discarded). Both functions are identical: `declareMetadata` is
just an alias for `setMetadata`, kept to honour the original SAMP command.
"""
function setMetadata(client::SAMPClient; kw...)
    metadata = Dict("samp.name" => client.name)
    for (k, v) ∈ kw
        sk = string(k)
        metadata[get(metadata_aliases, sk, sk)] = string(v)
    end
    if !haskey(metadata, "samp.icon.url")
        metadata["samp.icon.url"] = "https://astrozot.github.io/SAMP.jl/dev/assets/logo.png"
    end
    methodName = "$(methodPrefix(client)).declareMetadata"
    client.hub.proxy[methodName](client.key, metadata)
end

@doc (@doc setMetadata)
@inline declareMetadata(client::SAMPClient; kw...) = setMetadata(client; kw...)

"""
    getMetadata(client, id=client.client_id)

Return the metadata set for the client with the given `id`.
"""
function getMetadata(client::SAMPClient, client_id=client.client_id)
    methodName = "$(methodPrefix(client)).getMetadata"
    client.hub.proxy[methodName](client.key, client_id)
end

"""
    getSubscriptions(client, id)

Return the subscriptions for the client with the given `id`.
"""
function getSubscriptions(client::SAMPClient, client_id)
    methodName = "$(methodPrefix(client)).getSubscriptions"
    collect(keys(client.hub.proxy[methodName](client.key, client_id)))
end

"""
    getRegisteredClients(client)

Return a list of all clients registered with the hub of `client`.
"""
function getRegisteredClients(client::SAMPClient)
    methodName = "$(methodPrefix(client)).getRegisteredClients"
    client.hub.proxy[methodName](client.key)
end

"""
    getSubscribedClients(client, mtype)

Return a list of all clients that subscribed to the given `mtype`.
"""
function getSubscribedClients(client::SAMPClient, mtype::String)
    methodName = "$(methodPrefix(client)).getSubscribedClients"
    collect(keys(client.hub.proxy[methodName](client.key, mtype)))
end

"""
    notify(client, dest, mtype [; args...])

Notify the message `mtype` with the optional arguments `args` to `dest`.

`dest` must be the ID of the destination client: this can be obtained from
[`getSubscribedClients`](@ref) or [`getRegisteredClients`](@ref).

The optional message arguments can be passed as keywords: as with
[`setMetadata`](@ref), arguments with non-valid Julia names can be entered as
`var"long.name"=value`.
"""
function Base.notify(client::SAMPClient, dest::String, mtype::String; kw...)
    methodName = "$(methodPrefix(client)).notify"
    client.hub.proxy[methodName](client.key, dest, Dict("samp.mtype" => mtype, "samp.params" => kw))
    nothing
end

"""
    notifyAll(client, mtype [; args...])

Notify the message `mtype` to all clients.

See also: [`notify`](@ref)
"""
function notifyAll(client::SAMPClient, mtype::String; kw...)
    methodName = "$(methodPrefix(client)).notifyAll"
    client.hub.proxy[methodName](client.key, Dict("samp.mtype" => mtype, "samp.params" => kw))
    nothing
end

"""
    callAndWait(client, dest, mtype; timeout=0 [, args...])

Send the message `mtype` to `dest` and wait for the reply.

Arguments to the message can be added as keywords, similarly to
[`notify`](@ref).

The `timeout` keyword controls the timeout in seconds: if set to 0 or to a
negative number, there is no timeout (this is the default). Note that in this
case the client can wait indefinitely.
"""
function callAndWait(client::SAMPClient, dest::String, mtype::String; timeout=0, kw...)
    methodName = "$(methodPrefix(client)).callAndWait"
    SAMPResult(client.hub.proxy[methodName](client.key, dest, Dict("samp.mtype" => mtype, "samp.params" => kw), string(timeout)))
end
