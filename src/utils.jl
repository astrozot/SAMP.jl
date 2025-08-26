function robust_call(f; iterations=3, delay=0.1)
    iter = 1
    sleeptime = delay
    while true
        try
            res = f()
            return res
        catch e
            if iter < iterations
                sleep(sleeptime)
                sleeptime *= 2
                iter += 1
            else
                rethrow(e)
            end
        end
    end
end

macro robust(args...)
    iterations = 3
    delay = 0.1
    verbose = false
    e = nothing
    for arg ∈ args
        if isa(arg, Expr)
            if arg.head == :call
                e = arg
            elseif arg.head == :(=)
                if arg.args[1] == :(iterations)
                    iterations = arg.args[2]
                elseif arg.args[2] == :(delay)
                    delay = arg.args[2]
                elseif arg.args[2] == :(verbose)
                    verbose = arg.args[2]
                else
                    throw(KeyError("Unrecognized keyword $arg in marco @robust"))
                end
            else
                throw(ArgumentError("Unrecognized argument in macro @robust"))
            end
        end
    end
    if isnothing(e)
        throw(ArgumentError("Missing function argument in macro @robust"))
    end
    return quote
        iter = 1
        sleeptime = $(esc(delay))
        local res
        while true
            try
                res = $(esc(e))
                break
            catch err
                if iter < $(esc(iterations))
                    sleep(sleeptime)
                    if $(esc(verbose))
                        @warn "Retry #$iter"
                    end
                    sleeptime *= 2
                    iter += 1
                else
                    @error "The call failed after $iterations retries with initial delay $delay s"
                    rethrow(err)
                end
            end
        end
        res
    end
end

"""
    load_url_content(url; delete=false)

Load and return the content of a given `url`.

If the `url` is a local file, i.e. starts as "file://" and 
`delete = true`, the file is deleted.
"""
function load_url_content(url; delete=false)
    uri = URI(url)
    if uri.scheme in ["http", "https"]
        response = HTTP.get(url)
        return String(response.body)
    elseif uri.scheme == "file"
        path = uri.path
        Sys.iswindows() && startswith(path, "/") && (path = path[2:end])
        result = read(path, String)
        try
            delete && Base.Filesystem.rm(path)
        finally
            return result
        end
    else
        error("Unsupported URL scheme: $(uri.scheme)")
    end
end

