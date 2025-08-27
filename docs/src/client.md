# Client

## Object

```@docs
SAMP.SAMPClientId
SAMP.SAMPClient
SAMP.register
SAMP.defaultClient
SAMP.getClient
```

## Methods

All methods can use the default client [`SAMP.defaultClient`](@ref), which is
automatically registered using the [`SAMP.getClient](@ref) method. This can be
handy if one just need to perform queries and not receive messages.

Each registered client (including the default one) should be unregistered by a
call to [`SAMP.unregister](@ref) when not needed anymore. This is done
automatically by the code at the exit of Julia.

```@docs
SAMP.unregister
SAMP.setMetadata
SAMP.declareMetadata
SAMP.getMetadata
SAMP.getSubscriptions
SAMP.getRegisteredClients
SAMP.getSubscribedClients
Base.notify(::SAMPClient, ::SAMPClientId, ::String)
SAMP.notifyAll
SAMP.callAndWait
SAMP.findFirstClient
SAMP.findAllClients
```
