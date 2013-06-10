depsdir = joinpath(Pkg.dir(), "GLPK", "deps")
vers_file = joinpath(depsdir, "glpkvers.txt")
const libname = joinpath(depsdir, "usr", "lib", "libglpk")
pkgd_glpkvers = bytestring(ccall(("glp_version", libname), Ptr{Uint8}, ()))
open(vers_file, "w") do f
    println(f, pkgd_glpkvers)
end
