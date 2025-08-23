using SAMP
using Documenter

DocMeta.setdocmeta!(SAMP, :DocTestSetup, :(using SAMP); recursive=true)

makedocs(;
    modules=[SAMP],
    authors="Marco Lombardi",
    sitename="SAMP.jl",
    format=Documenter.HTML(;
        canonical="https://astrozot.github.io/SAMP.jl",
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
    repo="github.com/astrozot/SAMP.jl",
    devbranch="master",
)
