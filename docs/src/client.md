# Client

## Object

```@docs
VirtualObservatorySAMP.SAMPClientId
VirtualObservatorySAMP.SAMPClient
VirtualObservatorySAMP.register
VirtualObservatorySAMP.defaultClient
VirtualObservatorySAMP.getClient
```

## Methods

All methods can use the default client [`VirtualObservatorySAMP.defaultClient`](@ref), which is
automatically registered using the [`VirtualObservatorySAMP.getClient](@ref) method. This can be
handy if one just need to perform queries and not receive messages.

Each registered client (including the default one) should be unregistered by a
call to [`VirtualObservatorySAMP.unregister](@ref) when not needed anymore. This is done
automatically by the code at the exit of Julia.

```@docs
VirtualObservatorySAMP.unregister
VirtualObservatorySAMP.setMetadata
VirtualObservatorySAMP.declareMetadata
VirtualObservatorySAMP.getMetadata
VirtualObservatorySAMP.getSubscriptions
VirtualObservatorySAMP.getRegisteredClients
VirtualObservatorySAMP.getSubscribedClients
Base.notify(::SAMPClient, ::SAMPClientId, ::String)
VirtualObservatorySAMP.notifyAll
VirtualObservatorySAMP.callAndWait
VirtualObservatorySAMP.findFirstClient
VirtualObservatorySAMP.findAllClients
```
