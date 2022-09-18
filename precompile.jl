using PackageCompiler

PackageCompiler.create_sysimage([:CairoMakie], sysimage_path=joinpath(@__DIR__, "MakieSys.so"))
