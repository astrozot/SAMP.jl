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
