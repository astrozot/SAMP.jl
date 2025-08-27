"""
`SAMPClient{H <:`[`SAMP.AbstractSAMPHub`](@ref)`}`

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
- `hub_query_by_meta`: a string that, if non-void, indicates the mtype accepted
  by the hub to perform queries by meta (can be "x-samp.query.by-meta" or "samp.query.by-meta")

# Contructors

    SAMPClient([hub,] name)
    register([hub,] name [; metadata])

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
    hub_query_by_meta::String
    translator::String
end

"A list of registered clients, used to unregister with `atexit`"
const _registeredClients = SAMPClient[]

function SAMPClient(hub::SAMPHub, name::String; iterations=3, sleeptime=0.2)
    registration = @robust hub.proxy["samp.hub.register"](hub.secret)
    key = registration["samp.private-key"]
    hub_id = registration["samp.hub-id"]
    client_id = registration["samp.self-id"]
    # Find the server subscriptions
    hub_subscriptions = collect(keys(convert(Dict{String,Any},
        @robust hub.proxy["samp.hub.getSubscriptions"](key, hub_id))))
    if "samp.query.by-meta" ∈ hub_subscriptions
        hub_query_by_meta = "samp.query.by-meta"
    elseif "x-samp.query.by-meta" ∈ hub_subscriptions
        hub_query_by_meta = "x-samp.query.by-meta"
    else
        hub_query_by_meta = ""
    end
    client = SAMPClient(hub, name, key, hub_id, client_id, hub_query_by_meta, "")
    push!(_registeredClients, client)
    client
end

function SAMPClient(hub::SAMPWebHub, name::String)
    registration = @robust hub.proxy["samp.webhub.register"](Dict("samp.name" => name))
    key = registration["samp.private-key"]
    hub_id = registration["samp.hub-id"]
    client_id = registration["samp.self-id"]
    translator = registration["samp.url-translator"]
    hub_subscriptions = collect(keys(convert(Dict{String,Any},
        @robust hub.proxy["samp.webhub.getSubscriptions"](key, hub_id))))
    if "samp.query.by-meta" ∈ hub_subscriptions
        hub_query_by_meta = "samp.query.by-meta"
    elseif "x-samp.query.by-meta" ∈ hub_subscriptions
        hub_query_by_meta = "x-samp.query.by-meta"
    else
        hub_query_by_meta = ""
    end
    SAMPClient(hub, name, key, hub_id, client_id, hub_query_by_meta, translator)
end

methodPrefix(::SAMPClient{SAMPHub}) = "samp.hub"
methodPrefix(::SAMPClient{SAMPWebHub}) = "samp.webhub"

@doc (@doc SAMPClient)
function register(hub::AbstractSAMPHub, name::String; kw...)
    client = SAMPClient(hub, name)
    if length(kw) > 0
        @robust setMetadata(client; kw...)
    end
    client
end

@inline register(name::String; kw...) = register(getHub(), name; kw...)

"""
    unregister([client])

Unregister `client` from the associated hub.
"""
function unregister(client::SAMPClient)
    methodName = "$(methodPrefix(client)).unregister"
    @robust client.hub.proxy[methodName](client.key)
    deleteat!(_registeredClients, findfirst(==(client), _registeredClients))
    nothing
end

"""
    _unregisterAll()
    
Unregisters all registered clients.

The clients are taken from the list `_registeredClients`. This procedure is
automatically called by `atexit`.
"""
function _unregisterAll()
    for client ∈ _registeredClients
        unregister(client)
    end
end

const metadata_aliases = Dict(
    "name" => "samp.name", 
    "description" => "samp.description.text",
    "version" => "samp.version",
    "icon" => "samp.icon.url",
    "documentation" => "samp.documentation.url")

"""
    setMetadata([client]; metadata)
    declareMetadata([client]; metadata)

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
function setMetadata(client::SAMPClient=getClient(); kw...)
    metadata = Dict("samp.name" => client.name)
    for (k, v) ∈ kw
        sk = string(k)
        metadata[get(metadata_aliases, sk, sk)] = string(v)
    end
    if !haskey(metadata, "samp.icon.url")
        metadata["samp.icon.url"] = "https://astrozot.github.io/SAMP.jl/dev/assets/logo.png"
    end
    methodName = "$(methodPrefix(client)).declareMetadata"
    @robust client.hub.proxy[methodName](client.key, metadata)
    nothing
end

@doc (@doc setMetadata)
@inline declareMetadata(client::SAMPClient=getClient(); kw...) = setMetadata(client; kw...)

"""
    getMetadata([client,] dest=client.client_id)
    getMetadata(dest)

Return the metadata set for the client `dest`.
"""
function getMetadata(client::SAMPClient, dest::String=client.client_id)
    methodName = "$(methodPrefix(client)).getMetadata"
    convert(Dict{String,String}, @robust client.hub.proxy[methodName](client.key, dest))
end

@inline getMetadata(dest::String) = getMetadata(getClient(), dest)

"""
    getSubscriptions([client,] dest)

Return the subscriptions for the client `dest`.
"""
function getSubscriptions(client::SAMPClient, dest::String)
    methodName = "$(methodPrefix(client)).getSubscriptions"
    collect(keys(convert(Dict{String,Any}, @robust client.hub.proxy[methodName](client.key, dest))))
end

@inline getSubscriptions(dest::String) = getSubscriptions(getClient(), dest)

"""
    getRegisteredClients([client])

Return a list of all clients registered with the hub of `client`.
"""
function getRegisteredClients(client::SAMPClient=getClient())
    methodName = "$(methodPrefix(client)).getRegisteredClients"
    convert(Vector{String}, @robust client.hub.proxy[methodName](client.key))
end

"""
    getSubscribedClients([client,] mtype)

Return a list of all clients that subscribed to the given `mtype`.
"""
function getSubscribedClients(client::SAMPClient, mtype::String)
    methodName = "$(methodPrefix(client)).getSubscribedClients"
    convert(Vector{String}, collect(keys(@robust client.hub.proxy[methodName](client.key, mtype))))
end

@inline getSubscribedClients(mtype::String) = getSubscriptions(getClient(), mtype)

"""
    notify(client, dest, mtype [; args...])
    communicate([client,] dest, mtype [; args...])

Notify the message `mtype` with the optional arguments `args` to `dest`.

`dest` must be the ID of the destination client: this can be obtained from
[`getSubscribedClients`](@ref) or [`getRegisteredClients`](@ref).

The optional message arguments can be passed as keywords: as with
[`setMetadata`](@ref), arguments with non-valid Julia names can be entered as
`var"long.name"=value`.

The alias `communicate` is used to avoid type piracy.
"""
function Base.notify(client::SAMPClient, dest::String, mtype::String; kw...)
    methodName = "$(methodPrefix(client)).notify"
    @robust client.hub.proxy[methodName](client.key, dest, Dict("samp.mtype" => mtype, "samp.params" => kw))
    nothing
end

@inline communicate(client::SAMPClient, dest::String, mtype::String; kw...) = notify(client, dest, mtype; kw...)
@inline communicate(dest::String, mtype::String; kw...) = notify(getClient(), dest, mtype; kw...)

"""
    notifyAll([client,] mtype [; args...])
    communicateAll([client,] mtype [; args...])

Notify the message `mtype` to all clients.

See also: [`notify`](@ref)
"""
function notifyAll(client::SAMPClient, mtype::String; kw...)
    methodName = "$(methodPrefix(client)).notifyAll"
    @robust client.hub.proxy[methodName](client.key, Dict("samp.mtype" => mtype, "samp.params" => kw))
    nothing
end

@inline notifyAll(mtype::String; kw...) = notifyAll(getClient(), mtype; kw...)
@inline communicateAll(client::SAMPClient, mtype::String; kw...) = notifyAll(client, mtype; kw...)
@inline communicateAll(mtype::String; kw...) = notifyAll(getClient(), mtype; kw...)

"""
    callAndWait([client,] dest, mtype; timeout=0 [, args...])

Send the message `mtype` to `dest` and wait for the reply.

Arguments to the message can be added as keywords, similarly to
[`notify`](@ref).

The `timeout` keyword controls the timeout in seconds: if set to 0 or to a
negative number, there is no timeout (this is the default). Note that in this
case the client can wait indefinitely.
"""
function callAndWait(client::SAMPClient, dest::String, mtype::String; timeout=0, kw...)
    methodName = "$(methodPrefix(client)).callAndWait"
    SAMPResult(@robust client.hub.proxy[methodName](client.key, dest, Dict("samp.mtype" => mtype, "samp.params" => kw), string(timeout)))
end

@inline callAndWait(dest::String, mtype::String; timeout=0, kw...) = 
    callAndWait(getClient(), dest, mtype; timeout, kw...)

"""
    ping(client, dest=client.client_id)
    pint(dest)

Ping `id`; return `nothing` in case of success.
"""
ping(client::SAMPClient, dest::String=client.client_id) = 
    isa(callAndWait(client, dest, "samp.app.ping"), SAMPSuccess) ? nothing : error("A call to `ping` failed")

@inline ping(dest::String) = ping(getClient(), dest)

"""
    findFirstClient([client,] name; key="samp.name")

Return the first client with the metadata `key = name`

Returns `nothing` if no client is found.

`name` can be a simple string (and then it must match exactly `key`), or
a regular expression.

Equivalent to `first(findFirstClient(client, name))`, but with less
allocations.
"""
function findFirstClient(client::SAMPClient, name::String; key="samp.name")
    if client.hub_query_by_meta != ""
        result = callAndWait(client, client.hub_id, client.hub_query_by_meta; key=key, value=name)
        if isa(result, SAMP.SAMPSuccess)
            if length(result.value["ids"]) > 0
                return String(first(result.value["ids"])) :: String
            else
                return nothing
            end
        end
    end
    clients = getRegisteredClients(client)
    index = findfirst(clients) do c
        get(getMetadata(client, c), key, "") == name
    end
    if isnothing(index)
        nothing
    else
        clients[index]
    end
end

@inline findFirstClient(name::String; key="samp.name") = findFirstClient(getClient(), name; key)

function findFirstClient(client::SAMPClient, name::Regex; key="samp.name")
    clients = getRegisteredClients(client)
    index = findfirst(clients) do c
        match(name, get(getMetadata(client, c), key, "")) !== nothing
    end
    if isnothing(index)
        nothing
    else
        clients[index]
    end
end

@inline findFirstClient(name::Regex; key="samp.name") = findFirstClient(getClient(), name; key)

"""
    findAllClients([client,] name; key="samp.name")

Return all clients with the metadata `key = name`

`name` can be a simple string (and then it must match exactly `key`), or
a regular expression.
"""
function findAllClients(client::SAMPClient, name::String; key="samp.name")
    if client.hub_query_by_meta != ""
        result = callAndWait(client, client.hub_id, client.hub_query_by_meta; key=key, value=name)
        if isa(result, SAMP.SAMPSuccess)
            return convert(Vector{String}, result.value["ids"]) :: Vector{String}
        end
    end
    [id for id ∈ getRegisteredClients(client)
     if get(getMetadata(client, id), key, "") == name]
end

@inline findAllClients(name::String; key="samp.name") = findAllClients(getClient(), name; key)

function findAllClients(client::SAMPClient, name::Regex; key="samp.name")
    [id for id ∈ getRegisteredClients(client)
     if match(name, get(getMetadata(client, id), key, "")) !== nothing]
end

@inline findAllClients(name::Regex; key="samp.name") = findAllClients(getClient(), name; key)
