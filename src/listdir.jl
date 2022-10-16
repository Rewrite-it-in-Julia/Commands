import Base.show
using Base.Filesystem: getusername, getgroupname
using Dates
using DataFrames

struct File
    permissions::String
    size::Float64
    user::String
    group::String
    date::DateTime
    modified::DateTime
    name::String
end

struct ListDir
    files::Vector{File}
end

function permissions(path::AbstractString)::String
    userPermission = uperm(path)
    groupPermission = gperm(path)
    otherPermission = operm(path)

    mapfn(bit::UInt8) = begin
        readperm = 4 & bit == 4 ? "r" : "-"
        writeperm = 2 & bit == 2 ? "w" : "-"
        execperm = 1 & bit == 1 ? "x" : "-"

        return join([readperm, writeperm, execperm])
    end

    prefix = isdir(path) ? "d" : "."

    return join([prefix, mapfn(uperm(path)), mapfn(gperm(path)), mapfn(operm(path))])
end

function calculateFileSize(path::AbstractString)::Int
    if isdir(path)
        reduce(+, map(calculateFileSize, readdir(path; join=true))) + filesize(path)
    else
        return filesize(path)
    end
end


function File(path::AbstractString)::File
    perm = permissions(path)
    size = calculateFileSize(path)

    _stat = stat(path)
    user = getusername(_stat.uid)
    group = getgroupname(_stat.gid)

    date = unix2datetime(_stat.ctime)
    modified = unix2datetime(_stat.mtime)
    
    path = last(split(path, '/'))
    return File(perm, round(size / 1024; digits=2), user, group, date, modified, path)
end

listdir(start::String)::ListDir = begin
    # ListDir(map(File, readdir(start; join=true)))
    files = readdir(start; join = true)
    files = map(File, files)
  
    return ListDir(files)
end

function show(io::IO, ld::ListDir)
    files = ld.files

    dataframe = DataFrame()
    dataframe[!, :Name] = map(x -> x.name, files)
    dataframe[!, :Permission] = map(x -> x.permissions, files)
    dataframe[!, :User] = map(x -> x.user, files)
    dataframe[!, :Group] = map(x -> x.group, files)
    dataframe[!, :Date] = map(x -> x.date, files)
    dataframe[!, :Modified] = map(x -> x.modified, files)
    dataframe[!, Symbol("Size(KB)")] = map(x -> x.size, files)
    show(io, dataframe, allrows = true)
end