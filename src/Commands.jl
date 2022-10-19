module Commands
include("listdir.jl")
include("findfile.jl")
include("wipe.jl")
export listdir, findfile, wipe, pathsToDelete
export RUST, NODE_MODULES
end # module
