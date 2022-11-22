function createtar(files::Vector{String}, target::String; gzip::Bool=false)
  command = ["tar", "--create", "--file", target, files... ]
  if gzip
    push!(command, "--gzip")
  end

  run(Cmd(command))
end

function listtar(target::String)
  run(`tar --list --file $(target)`)
end

function appendfiles(files::Vector{String}, target::String)
  command = ["tar", "--append", "--file", target, files...]
  run(Cmd(command))
end

function appendfile(file::String, target::String)
  run(`tar --append --file $(target) $(file)`)
end

function deletefile(file::String, target::String)
  run(`tar --delete --file $(target) $(file)`)
end

function extracttar(tarfile::String, target::String="."; gzip::Bool=false)
  !isdir(target) && throw("$(target) not exists")
  
  command = ["tar", "--extract", "--file", tarfile, "-C", target]
  if gzip
    push!(command, "--gzip")
  end

  run(Cmd(command))

end


