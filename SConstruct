#!/usr/bin/env python
import os
import sys

from methods import print_error


libname = "godot_meta_carl"
projectdir = "demo"

localEnv = Environment(tools=["default"], PLATFORM="")

# Build profiles can be used to decrease compile times.
# You can either specify "disabled_classes", OR
# explicitly specify "enabled_classes" which disables all other classes.
# Modify the example file as needed and uncomment the line below or
# manually specify the build_profile parameter when running SCons.

# localEnv["build_profile"] = "build_profile.json"

customs = ["custom.py"]
customs = [os.path.abspath(path) for path in customs]

opts = Variables(customs, ARGUMENTS)
opts.Update(localEnv)

Help(opts.GenerateHelpText(localEnv))

env = localEnv.Clone()
env['disable_exceptions'] = 'no'
# @todo Why doesn't this work?
env['ndk_version'] = '28.1.13356709'

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

sources = Glob("src/*.cpp")

if env["target"] in ["editor", "template_debug"]:
    try:
        doc_data = env.GodotCPPDocData("src/gen/doc_data.gen.cpp", source=Glob("doc_classes/*.xml"))
        sources.append(doc_data)
    except AttributeError:
        print("Not including class reference as we're targeting a pre-4.3 baseline.")

if env['platform'] == 'android':
    env.Append(LIBPATH=['CARL_build_android/CARL'])
else:
    env.Append(LIBPATH=['CARL_build/CARL'])

env.Append(LIBS=['carl_core'])

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

copy = env.Install("{}/bin/{}/".format(projectdir, env["platform"]), library)

default_args = [library, copy]
Default(*default_args)
