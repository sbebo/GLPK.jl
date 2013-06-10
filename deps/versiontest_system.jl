depsdir = joinpath(Pkg.dir(), "GLPK", "deps")
vers_file = joinpath(depsdir, "glpkvers.txt")
system_glpkvers = bytestring(ccall(("glp_version", "libglpk"), Ptr{Uint8}, ()))
open(vers_file, "w") do f
    println(f, system_glpkvers)
end
