#!/usr/bin/env python
import os
import sys

from methods import print_error


libname = "godot_meta_carl"
projectdir = "studio"

localEnv = Environment(tools=["default"], PLATFORM="")

customs = ["custom.py"]
customs = [os.path.abspath(path) for path in customs]

opts = Variables(customs, ARGUMENTS)
opts.Update(localEnv)

Help(opts.GenerateHelpText(localEnv))

env = localEnv.Clone()
env['disable_exceptions'] = 'no'

if not (os.path.isdir("godot-cpp") and os.listdir("godot-cpp")):
    print_error("""godot-cpp is not available within this folder, as Git submodules haven't been initialized.
Run the following command to download godot-cpp:

    git submodule update --init --recursive""")
    sys.exit(1)

env = SConscript("godot-cpp/SConstruct", {"env": env, "customs": customs})

env.Append(CXXFLAGS=['-Wall', '-Wuninitialized'])
env.Append(CPPPATH=[
    "src",
    "CARL/CARL/include",
    "CARL/Dependencies/eigen",
    "CARL/Dependencies/arcana.cpp/Source/Submodules/GSL/include",
    "CARL/Dependencies/arcana.cpp/Source/Shared",
])

# Include suffix in object files, so we can build for multiple platforms in one checkout.
env['OBJSUFFIX'] = env['suffix'] + env['OBJSUFFIX']
env['SHOBJSUFFIX'] = env['suffix'] + env['SHOBJSUFFIX']

sources = Glob("CARL/CARL/source/*.cpp") + Glob("src/*.cpp")

if env["target"] in ["editor", "template_debug"]:
    try:
        doc_data = env.GodotCPPDocData("src/gen/doc_data.gen.cpp", source=Glob("doc_classes/*.xml"))
        sources.append(doc_data)
    except AttributeError:
        print("Not including class reference as we're targeting a pre-4.3 baseline.")

env.Append(
    LINKFLAGS=[
        "-Wl,--no-undefined",
        "-static-libgcc",
        "-static-libstdc++",
    ]
)

# .dev doesn't inhibit compatibility, so we don't need to key it.
# .universal just means "compatible with all relevant arches" so we don't need to key it.
suffix = env['suffix'].replace(".dev", "").replace(".universal", "")

lib_filename = "{}{}{}{}".format(env.subst('$SHLIBPREFIX'), libname, suffix, env.subst('$SHLIBSUFFIX'))

library = env.SharedLibrary(
    "bin/{}/{}".format(env['platform'], lib_filename),
    source=sources,
)

copy = env.Install("{}/addons/godot-meta-carl/{}/".format(projectdir, env["platform"]), library)

default_args = [library, copy]
Default(*default_args)
