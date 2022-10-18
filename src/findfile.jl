using Base.Filesystem: getusername

function findfile(start::AbstractString, pattern::Union{Regex, AbstractString};
                    absolute::Bool = false, 
                    extension::String = "", 
                    owner::Union{String, Nothing} = nothing)::Vector{String}

    predfn(file::String) = begin
        flag1 = endswith(file, extension) 
        filestat = stat(file)
        
        user = getusername(filestat.uid)
        flag2 = isnothing(owner) || user == owner

        findindex = findlast(pattern, file)
        flag3 = !isnothing(findindex)

        return flag1 && flag2 && flag3
    end

    readed = String[]
    for (root, dirs, files) in walkdir(start)
        for file in files
            file = joinpath(root, file)
            if predfn(file)
                push!(readed, file)
            end
        end
    end

    
    if absolute
        readed = map(abspath, readed)
    end

    return readed
end
