```@meta
CurrentModule = SAMP
```

# SAMP

This package provides a Julia implementation of the [Simple Application
Messaging Protocol (SAMP)](https://www.ivoa.net/documents/SAMP/), a messaging
protocol that enables astronomy software tools to interoperate and communicate
(see also [Taylor et al.
2015](https://ui.adsabs.harvard.edu/abs/2015A%26C....11...81T/abstract)).

Currently, the package implements only the non-callable client interface: this
allows one to send synchronous message to SAMP-aware applications such as
[SAOImage DS9](https://sites.google.com/cfa.harvard.edu/saoimageds9),
[TOPCAT](https://www.star.bris.ac.uk/~mbt/topcat/), [Aladin Sky
Atlas](https://aladin.cds.unistra.fr) and similar.

The package can also connect using a WEB hub provided, for example, by [Aladin
lite](https://aladin.cds.unistra.fr/AladinLite/).

## Example 1

Let us find all subscriptions that [TOPCAT](https://www.star.bris.ac.uk/~mbt/topcat/) is providing.

Open [TOPCAT](https://www.star.bris.ac.uk/~mbt/topcat/), then type the
following commands on the Julia REPL:

```julia-repl
julia> using SAMP

julia> hub = SAMPHub();

julia> client = register(hub, "Test"; 
       description="Simple test of SAMP.jl", version=v"1.0.0");

julia> topcat = findFirstClient(clients, "topcat")

julia> getSubscriptions(client, topcat)

julia> unregister(client)
```

## Example 2

In this example we send various messages to [SAOImage
DS9](https://sites.google.com/cfa.harvard.edu/saoimageds9).

Open [TOPCAT](https://www.star.bris.ac.uk/~mbt/topcat/) and, then, [SAOImage
DS9](https://sites.google.com/cfa.harvard.edu/saoimageds9) on your local computer.

Then type the following commands on the Julia REPL:

```julia-repl
julia> using SAMP

julia> hub = SAMPHub();

julia> client = register(hub, "Test"; 
       description="Simple test of SAMP.jl", version=v"1.0.0");

julia> ds9 = first(getSubscribedClients(client, "ds9.get"))
"c2"

julia> getMetadata(client, ds9)
Dict{Any, Any} with 9 entries:
  "samp.icon.url"          => "http://ds9.si.edu/sun.png"
  "author.name"            => "William Joye"
  "author.affiliation"     => "Smithsonian Astrophysical Observatory"
  "ds9.version"            => "8.6"
  "home.page"              => "http://ds9.si.edu/"
  "samp.description.text"  => "SAOImageDS9 is an astronomical visualization application"
  "samp.documentation.url" => "http://ds9.si.edu/doc/ref/index.html"
  "samp.name"              => "ds9"
  "author.email"           => "ds9help@cfa.harvard.edu"

julia> callAndWait(client, ds9, "ds9.get"; cmd="version")
SAMP.SAMPSuccess{Dict{Any, Any}}(Dict{Any, Any}("value" => "ds9 8.6"))

julia> notify(client, ds9, "image.load.fits"; 
       url="https://fits.gsfc.nasa.gov/samples/UITfuv2582gc.fits", name="Astro UIT")

julia> unregister(client)
```

## Example 3

Here we display a color image in [SAOImage
DS9](https://sites.google.com/cfa.harvard.edu/saoimageds9). Start as a in the
previous example, then type the following commands:

```julia-repl
julia> using SAMP

julia> hub = SAMPHub();

julia> client = register(hub, "Test"; 
       description="Simple test of SAMP.jl", version=v"1.0.0");

julia> ds9 = first(getSubscribedClients(client, "ds9.get"))
"c2"

julia> callAndWait(client, ds9, "ds9.set"; cmd="rgb")

julia> callAndWait(client, ds9, "ds9.set"; cmd="rgb red")

julia> callAndWait(client, ds9, "ds9.set"; cmd="url http://ds9.si.edu/download/data/673nmos.fits")

julia> callAndWait(client, ds9, "ds9.set"; cmd="zscale")

julia> callAndWait(client, ds9, "ds9.set"; cmd="rgb green")

julia> callAndWait(client, ds9, "ds9.set"; cmd="url http://ds9.si.edu/download/data/656nmos.fits")

julia> callAndWait(client, ds9, "ds9.set"; cmd="zscale")

julia> callAndWait(client, ds9, "ds9.set"; cmd="rgb blue")

julia> callAndWait(client, ds9, "ds9.set"; cmd="url http://ds9.si.edu/download/data/502nmos.fits")

julia> callAndWait(client, ds9, "ds9.set"; cmd="zscale")

julia> callAndWait(client, ds9, "ds9.set"; cmd="rotate 270")

julia> callAndWait(client, ds9, "ds9.set"; cmd="zoom to fit")

julia> unregister(client)
```
