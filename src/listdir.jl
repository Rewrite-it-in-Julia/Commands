import Base.show
using Base.Filesystem: getusername, getgroupname
using Dates, DataFrames, Crayons, PrettyTables

struct File
    permissions::String
    size::Float64
    user::String
    group::String
    date::DateTime
    modified::DateTime
    name::String

    isdir::Bool
    isfile::Bool
    islink::Bool
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
        try
            files = readdir(path; join = true)
            reduce(+, map(calculateFileSize, files)) + filesize(path)    
        catch error
            if isa(error, Base.IOError)
                @error error
                return 0
            end
        end
        
    else
        return filesize(path)
    end
end


function File(path::AbstractString)::File
    perm = permissions(path)
    size = calculateFileSize(path)

    filestat = stat(path)
    user = getusername(filestat.uid)
    group = getgroupname(filestat.gid)

    date = unix2datetime(filestat.ctime)
    modified = unix2datetime(filestat.mtime)
    
    filepath = last(split(path, '/'))
    
    return File(perm, 
                round(size / 1024; digits=2), 
                user, 
                group, 
                date, 
                modified, 
                filepath, 
                isdir(path),
                isfile(path),
                islink(path))
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
    dataframe[!, :Name] = map(x::File -> x.name, files)
    
    dataframe[!, :Permission] = map(x::File -> x.permissions, files)
    dataframe[!, Symbol("Size(KB)")] = map(x::File -> x.size, files)
    dataframe[!, :User] = map(x::File -> x.user, files)
    dataframe[!, :Group] = map(x::File -> x.group, files)
    dataframe[!, :Date] = map(x::File -> x.date, files)
    dataframe[!, :Modified] = map(x::File -> x.modified, files)
    
    highlighter1 = Highlighter((data, row, column) -> column == 1 && files[row].isdir, foreground = :blue, bold = true)
    highlighter2 = Highlighter((data, row, column) -> column == 1 && files[row].islink, foreground = :green)

    pretty_table(io, dataframe, highlighters = (highlighter1, highlighter2))
end