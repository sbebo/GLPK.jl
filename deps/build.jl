using BinDeps

glpkvers = "4.48"
glpkname = "glpk-$glpkvers"

@unix_only glpkarchive = "$glpkname.tar.gz"
@windows_only glpkarghive = "win$(glpkname).zip"

depsdir = joinpath(Pkg.dir(), "GLPK", "deps")
prefix = joinpath(depsdir, "usr")
uprefix = replace(replace(prefix, "\\", "/"), "C:/", "/c/")

function build()
    s = @build_steps begin
        c = Choices(Choice[Choice(:skip, "Skip Installation - Binaries must be installed manually", nothing)])
    end

    ## Homebrew
    @osx_only push!(c, Choice(:brew, "Install GLPK using brew", @build_steps begin
        HomebrewInstall("glpk",ASCIIString[])
        `brew link glpk`
    end))

    ## Prebuilt Binaries
    #@windows_only begin
        #local_file = joinpath(depsdir, "downloads", glpkarchive)
        #push!(c, Choice(:binary, "Download prebuilt binary",
                         #@build_steps begin
                             #ChangeDirectory(depsdir)
                             #FileDownloader("http://downloads.sourceforge.net/project/winglpk/winglpk/GLPK-$glpkvers/$glpkarchive", local_file)
                             #FileUnpacker(local_file, joinpath(depsdir, "usr"))
                         #end))
    #end

    ## Install from source
    @unix_only begin
        steps = @build_steps begin ChangeDirectory(depsdir) end

        ENV["PKG_CONFIG_LIBDIR"] = ENV["PKG_CONFIG_PATH"] = joinpath(depsdir, "usr", "lib", "pkgconfig")
        @unix_only ENV["PATH"] = joinpath(prefix, "bin") * ":" * ENV["PATH"]

        steps |= @build_steps begin
                autotools_install(
                    depsdir,
                    "http://ftp.gnu.org/gnu/glpk/$glpkarchive", # url
                    glpkarchive, # downloaded file
                    String["--with-gmp", "--enable-dl"], # config opts
                    glpkname, # directory name
                    glpkname, # directory
                    #joinpath("builds", glpkname, "src", ".lib", "libglpk.la"), # libname
                    joinpath("src", ".libs", "libglpk.la"), # libname
                    "libglpk.la") # installed_libname
        end

        push!(c, Choice(:source, "Install GLPK from source", steps))
    end
    run(s)
end # build()

function find_glpk_library()
    pkgd_libname = joinpath(prefix, "lib", "libglpk")
    system_libname = "libglpk"

    depsdir = joinpath(Pkg.dir(), "GLPK", "deps")
    pkgd_versiontest_script = joinpath(depsdir, "versiontest_pkgd.jl")
    system_versiontest_script = joinpath(depsdir, "versiontest_system.jl")

    vers_file = joinpath(depsdir, "glpkvers.txt")

    function check_glpk_version(dl, script)
        if dl == C_NULL
            return false
        end
        reload(script)
        found_glpkvers = readchomp(vers_file)
        rm(vers_file)
        if found_glpkvers != glpkvers
            return false
        end
        return true
    end

    dl = dlopen_e(pkgd_libname)
    if check_glpk_version(dl, pkgd_versiontest_script)
        ccall(:add_library_mapping, Cint, (Ptr{Cchar}, Ptr{Void}), "libglpk", dl)
        return true
    end
    dl = dlopen_e(system_libname)
    if check_glpk_version(dl, system_versiontest_script)
        dlclose(dl)
        return true
    end
    return false
end

find_glpk_library() || build()
