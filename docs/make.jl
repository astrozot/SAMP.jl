using SAMP
using Documenter

DocMeta.setdocmeta!(SAMP, :DocTestSetup, :(using SAMP); recursive=true)

makedocs(;
    modules=[SAMP],
    authors="Marco Lombardi <marco.lombardi@gmail.com> and contributors",
    sitename="SAMP.jl",
    format=Documenter.HTML(;
        canonical="https://astrozot.github.io/SAMP.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/astrozot/SAMP.jl",
    devbranch="main",
)
