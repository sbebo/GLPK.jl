let
    glpkvers = "4.48"

    depsdir = joinpath(Pkg.dir(), "GLPK", "deps")
    pkgd_versiontest_script = joinpath(depsdir, "versiontest_pkgd.jl")
    system_versiontest_script = joinpath(depsdir, "versiontest_system.jl")

    pkgd_libname = joinpath(depsdir, "usr", "lib", "libglpk")
    system_libname = "libglpk"

    vers_file = joinpath(depsdir, "glpkvers.txt")

    function find_glpk_library()
        warnpkgd = ""
        warnsystem = ""
        dl = dlopen_e(pkgd_libname)
        if dl != C_NULL
            reload(pkgd_versiontest_script)
            pkgd_glpkvers = readchomp(vers_file)
            rm(vers_file)
            if pkgd_glpkvers != glpkvers
                warnpkgd = "The version of the library installed in the GLPK.jl package directory is " *
                            "not compatible with the current version of the GLPK.jl package " *
                            "(found=$pkgd_glpkvers required=$glpkvers)"
            else
                ccall(:add_library_mapping, Cint, (Ptr{Cchar}, Ptr{Void}), "libglpk", dl)
                return
            end
        end
        dl = dlopen_e(system_libname)
        if dl != C_NULL
            realod(system_versiontest_script)
            system_glpkvers = readchomp(vers_file)
            rm(vers_file)
            if system_glpkvers != glpkvers
                warnsystem = "A version of the GLPK library was found in the system, but it is " *
                             "not compatible with the current version of the GLPK.jl package " *
                             "(found=$system_glpkvers required=$glpkvers)"
            else
                dlclose(dl)
                return
            end
        end
        isempty(warnpkgd) || warn(warnpkgd)
        isempty(warnsystem) || warn(warnsystem)
        error("Failed to find required library libglpk. Try re-running the package script using Pkg.runbuildscript(\"GLPK\")")
    end
    find_glpk_library()
end
const _jl_libGLPK = "libglpk"
