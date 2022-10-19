using Test, Commands

@testset "test wipe" begin
    #= fileitems = pathsToDelete("/home/steiner/workspace/", RUST)
    println(length(fileitems))
    for item in fileitems
        println(item)
    end =#

    wipe("/home/steiner/workspace/", RUST)
end