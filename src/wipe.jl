import Base.show
using Formatting: FormatExpr, format

const SPACING_FILES = 12
const SPACING_SIZE = 18
const SPACING_PATH = 9

@enum Target begin
    RUST
    NODE_MODULES
end

struct DeleteFileItem
    filecount::Int
    filesize::Float64
    path::String
end

function wipe(start::AbstractString, target::Target; wipe = false)
    fileitems = pathsToDelete(start, target)
    
    for item in fileitems
        println(item)
    end

    if wipe
        foreach(item -> rm(item.path; recursive = true), fileitems)
    end
end

function isvalidTarget(path::AbstractString)::Bool
    if path == "target" || endswith(path, "target")
        filepath = joinpath(path, ".rustc_info.json")
        return ispath(filepath)
    else
        return true
    end
end

function pathsToDelete(start::AbstractString, target::Target)::Vector{DeleteFileItem}
    function _walk(start::AbstractString)::Vector{String}
        readed = readdir(start; join = true)
        dirs = filter(isdir, readed)
        result = String[]
        restdirs = String[]
        for dir in dirs
            if endswith(dir, String(target)) && isvalidTarget(dir)
                push!(result, dir)
            else
                push!(restdirs, dir)
            end
        end

        for dir in restdirs
            for targetdir in _walk(dir)
                push!(result, targetdir)
            end
        end

        return result
    end

    dirs = _walk(start)
    return map(DeleteFileItem, dirs)
end

function DeleteFileItem(directory::AbstractString)
    filecount = calculateFileCount(directory)
    filesize = round(calculateFileSize(directory) / 1024 / 1024, digits = 2)
    return DeleteFileItem(filecount, filesize, directory)
end

function show(io::IO, fileitem::DeleteFileItem)
    fe = FormatExpr("{:$(SPACING_FILES)}{:$(SPACING_SIZE)}{:$(SPACING_PATH)}")
    print(io, format(fe, fileitem.filecount, fileitem.filesize, fileitem.path))
end

function String(target::Target)::String
    if target == RUST
        return "target"
    elseif target == NODE_MODULES
        return "node_modules"
    else
        error("unknown target")
    end
end

function calculateFileCount(directory::AbstractString)::Int
    !isdir(directory) && error("$(directory) is not a dir")

    result = 0
    readed = readdir(directory; join = true)
    notdirs = filter(!isdir, readed)
    dirs = filter(isdir, readed)
    result += length(notdirs)
    for dir in dirs
        count = calculateFileCount(dir)
        result += count
    end

    return result
end