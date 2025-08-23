module XMLRPC

using HTTP
using LightXML
using Dates
using Base64: base64decode

"""
An XML RPC Proxy wrapper type for the server URL.
"""
struct Proxy
    url::String
end

"""
An XMLRPC call used for dispatch.
"""
struct MethodCall
    proxy::Proxy
    name::String
end

"""
A fully determined XMLRPC call with parameters specified
"""
struct Call
    method::MethodCall
    parameters::Tuple
end

"""
The exception raised by faulty XMLRPC calls
"""
struct XMLRPCException <: Exception
    code::Int
    messsage::String
end

function Base.getindex(proxy::Proxy, s::AbstractString)
    function ret(m...)
        meth = Call(MethodCall(proxy, string(s)), m)
        xdoc = xml(meth)
        headers = Dict(
            "Content-Type" => "text/xml",
            "User-Agent" => "Julia XML-RPC Client"
        )
        res = try
            HTTP.post(proxy.url, headers, string(xdoc))
        finally
            @debug headers
            @debug string(xdoc)
            free(xdoc)
        end
        if res.status!= 200
            error("HTTP error $res.status: $res.body")
        end
        xmlrpc_parse(String(res.body))
    end
end


"""
    xml(x::Call)

Convert a `XMLRPCCall` into XML.
"""
function xml(x::Call)
    xdoc = XMLDocument()
    xroot = create_root(xdoc, "methodCall")
    xs1 = new_child(xroot, "methodName")
    add_text(xs1, x.method.name)
    params = new_child(xroot, "params")
    for p in x.parameters
        rpc_arg(new_child(params, "param"), p)
    end
    xdoc
end

"""
    rpc_arg(x::XMLElement, stuff)

Convert a value, Dict, or Vector into an XMLRPC snippet.
"""
function rpc_arg(x::XMLElement, p::Bool)
    add_text(new_child(new_child(x, "value"), "string"), p ? "1" : "0")
end

function rpc_arg(x::XMLElement, p)
    add_text(new_child(new_child(x, "value"), "string"), string(p))
end

function rpc_arg(x::XMLElement, p::Vector)
    d = new_child(new_child(new_child(x, "value"), "array"), "data")
    for e in p
        rpc_arg(d, e)
    end
end

function rpc_arg(x::XMLElement, d::AbstractDict)
    s = new_child(new_child(x, "value"), "struct")
    for p in d
        rpc_arg(s, p)
    end
end

function rpc_arg(x::XMLElement, p::Pair)
    m = new_child(x, "member")
    n = new_child(m, "name")
    add_text(n, string(p.first))
    rpc_arg(m, p.second)
end

"""
    xmlrpc_parse(element)

Parse `element` into a Julia object.

`element` can be a string or an `XMLElement`.
"""
function xmlrpc_parse(s::AbstractString)
    x = LightXML.parse_string(s)
    try
        xroot = root(x)
        name(xroot) == "methodResponse" || error("malformed XMLRPC response")
        xmlrpc_parse(collect(child_elements(xroot))[1])
    finally
        free(x)
    end
end

function xmlrpc_parse(x::XMLElement)
    name_x = name(x)
    if name_x == "value"
        children = collect(child_elements(x))
        if length(children) == 0 # special case in case of malformed node: interpret as string
            return content(x)
        end
        child1 = children[1]
        name_child1 = name(child1)
        if name_child1 == "i4" || name_child1 == "int"
            return parse(Int32, content(child1))
        elseif name_child1 == "i8"
            return parse(Int64, content(child1))
        elseif name_child1 == "dateTime.iso8601"
            return DateTime(content(child1))
        elseif name_child1 == "boolean"
            return content(child1) == "true" || content(child1) == "1"
        elseif name_child1 == "nil"
            return nothing
        elseif name_child1 == "double"
            return parse(Float64, content(child1))
        elseif name_child1 == "base64"
            return base64decode(content(child1))
        elseif name_child1 == "string"
            return content(child1)
        elseif name_child1 == "array"
            c′ = collect(child_elements(child1))[1] # <data>
            arr = []
            for elt in child_elements(c′)
                push!(arr, xmlrpc_parse(elt))
            end
            return arr
        elseif name_child1 == "struct"
            d = Dict()
            for elt in child_elements(child1)
                push!(d, xmlrpc_parse(elt))
            end
            return d
        end
    elseif name_x == "member"
        c″ = collect(child_elements(x))
        n = content(c″[1]) # name
        v = xmlrpc_parse(c″[2]) # value
        return Pair(n,v)
    elseif name_x == "params" || name_x == "param" # always one param on return
        return xmlrpc_parse(collect(child_elements(x))[1])
    elseif name_x == "fault"
        c‴ = collect(child_elements(x))[1]
        fault = xmlrpc_parse(c‴)
        throw(XMLRPCException(fault["faultCode"], fault["faultString"]))
    end
end

end