using VirtualObservatorySAMP
using Documenter

DocMeta.setdocmeta!(VirtualObservatorySAMP, :DocTestSetup, :(using VirtualObservatorySAMP); recursive=true)

makedocs(;
    modules=[VirtualObservatorySAMP],
    authors="Marco Lombardi",
    sitename="VirtualObservatorySAMP.jl",
    format=Documenter.HTML(;
        canonical="https://astrozot.github.io/VirtualObservatorySAMP.jl",
        edit_link="main",
        assets=["assets/favicon/favicon.ico"],
    ),
    checkdocs=:exports,
    pages=[
        "Home" => Any[
            "SAMP" => "index.md",
            "Hub discovery" => "hubs.md",
            "Client" => "client.md",
            "Results" => "results.md"
        ]
    ],
)

deploydocs(;
    repo="github.com/astrozot/VirtualObservatorySAMP.jl",
    devbranch="master",
)
