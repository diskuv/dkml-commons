#!/bin/bash
#################################################
# _common_tool.sh
#
# Inputs:
#   DKMLDIR: The location of the vendored directory 'diskuv-ocaml' containing
#      the file '.dkmlroot'.
#   TOPDIR: Optional. The project top directory containing 'dune-project'. If
#     not specified it will be discovered from DKMLDIR.
#   DKML_DUNE_BUILD_DIR: Optional. The directory that will have a _opam subdirectory containing
#     the Opam switch. If not specified will be crafted from BUILDTYPE.
#   PLATFORM: One of the PLATFORMS defined in TOPDIR/Makefile
#   BUILDTYPE: One of the BUILDTYPES defined in TOPDIR/Makefile
#
#################################################

# shellcheck disable=SC1091
. "$DKMLDIR"/vendor/drc/unix/_common_tool.sh

# The build root is where all the build files go (except _build for Dune in dev platform). Ordinarily it is a relative
# directory but can be overridden with DKML_BUILD_ROOT to be an absolute path.
# For Windows you want to use it so that you do not run into 260 character absolute path limits!
# Here is an example of a 260 character limit violation ... it is VERY HARD to see what the problem is!
#   $ (cd _build/default && D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\bin\ocamlc.opt.exe -w -40 -g -bin-annot -I expander/.ppx_sexp_conv_expander.objs/byte -I D:/a/diskuv-ocaml-starter-ghmirror/diskuv-ocaml-starter-ghmirror/build/windows_x86_64/Release/_opam/lib/ocaml\compiler-libs -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\base -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\base\base_internalhash_types -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\base\caml -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\base\shadow_stdlib -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\ocaml-compiler-libs\common -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\ocaml-compiler-libs\shadow -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\ocaml-migrate-parsetree -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\ppx_derivers -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\ppxlib -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\ppxlib\ast -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\ppxlib\metaquot_lifters -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\ppxlib\print_diff -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\ppxlib\stdppx -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\ppxlib\traverse_builtins -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\sexplib0 -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\stdlib-shims -no-alias-deps -open Ppx_sexp_conv_expander__ -o expander/.ppx_sexp_conv_expander.objs/byte/ppx_sexp_conv_expander__Str_generate_sexp_grammar.cmi -c -intf expander/str_generate_sexp_grammar.pp.mli)
#   File "expander/str_generate_sexp_grammar.mli", line 1:
#   Error: I/O error: expander/.ppx_sexp_conv_expander.objs/byte\ppx_sexp_conv_expander__Str_generate_sexp_grammar.cmi9d73bb.tmp: No such file or directory
if [ "${DKML_FEATUREFLAG_CMAKE_PLATFORM:-OFF}" = OFF ]; then
    if [ -z "${DKML_DUNE_BUILD_DIR:-}" ]; then
        DKML_DUNE_BUILD_DIR="$BUILD_ROOT_UNIX/$PLATFORM/$BUILDTYPE"
    fi
else
    if [ -n "${DKML_BUILD_ROOT:-}" ]; then
        buildhost_pathize "$DKML_BUILD_ROOT"
        # shellcheck disable=SC2154
        DKML_DUNE_BUILD_DIR="$buildhost_pathize_RETVAL"
    elif cmake_flag_off "$USERMODE"; then
        DKML_DUNE_BUILD_DIR="$STATEDIR/_build"
    else
        DKML_DUNE_BUILD_DIR="$TOPDIR/_build"
    fi
fi

# Make into absolute path if not already
if [ "${DKML_FEATUREFLAG_CMAKE_PLATFORM:-OFF}" = OFF ]; then
    if [ -x /usr/bin/cygpath ]; then
        # Trim any trailing slash because `cygpath -aw .` has trailing slash
        BUILDDIR_BUILDHOST=$(/usr/bin/cygpath -aw "$DKML_DUNE_BUILD_DIR" | sed 's#\\$##')
    else
        BUILDDIR_BUILDHOST="$BUILD_BASEPATH$DKML_DUNE_BUILD_DIR"
    fi
fi

# DKML_DUNE_BUILD_DIR is sticky, so that platform-opam-exec.sh and any other scripts can be called as children and behave correctly.
export DKML_DUNE_BUILD_DIR

# Opam Windows has a weird bug where it rsyncs very very slowly all pinned directories (recursive
# super slowness). There is a possibly related reference on https://github.com/ocaml/opam/wiki/2020-Developer-Meetings#opam-tools
# By setting ON we can use GLOBAL switches for Windows, and namespace it with
# a hash-based encoding of the TOPDIR so, for all intents and purposes, it is a local switch.
USE_GLOBALLY_REGISTERED_LOCAL_SWITCHES_ON_WINDOWS=OFF

# There is one Opam switch for each build directory.
#
# Inputs:
# - env:PLATFORM
# - env:BUILDTYPE. Deprecated. Used when DKML_FEATUREFLAG_CMAKE_PLATFORM=OFF.
# - env:DKML_DUNE_BUILD_DIR. Automatically set by this script if not already set.
# Outputs:
# - env:OPAMROOTDIR_BUILDHOST - [As per set_opamrootdir] The path to the Opam root directory that is usable only on the
#     build machine (not from within a container)
# - env:OPAMROOTDIR_EXPAND - [As per set_opamrootdir] The path to the Opam root directory switch that works as an
#     argument to `exec_in_platform`
# - env:OPAMSWITCHFINALDIR_BUILDHOST - Either:
#     The path to the switch that represents the build directory that is usable only on the
#     build machine (not from within a container). For an external (aka local) switch the returned path will be
#     a `.../_opam`` folder which is where the final contents of the switch live. Use OPAMSWITCHNAME_EXPAND
#     if you want an XXX argument for `opam --switch XXX` rather than this path which is not compatible.
# - env:OPAMSWITCHNAME_BUILDHOST - The name of the switch seen on the build host from `opam switch list --short`
# - env:OPAMSWITCHISGLOBAL - Either ON (switch is global) or OFF (switch is external; aka local)
# - env:OPAMSWITCHNAME_EXPAND - Either
#     The path to the switch **not including any _opam subfolder** that works as an argument to `exec_in_platform` -OR-
#     The name of a global switch that represents the build directory.
#     OPAMSWITCHNAME_EXPAND works inside or outside of a container.
# - env:WITHDKMLEXE_BUILDHOST - The plugin binary 'with-dkml.exe'
set_opamrootandswitchdir() {
    # Set OPAMROOTDIR_BUILDHOST, OPAMROOTDIR_EXPAND and WITHDKMLEXE_BUILDHOST
    set_opamrootdir

    if [ "$USE_GLOBALLY_REGISTERED_LOCAL_SWITCHES_ON_WINDOWS" = ON ] && is_unixy_windows_build_machine; then
        set_opamrootandswitchdir_OPAMGLOBALNAME=$(printf "%s" "$TOPDIR" | sha256sum | cut -c1-16 | awk '{print $1}')$(printf "%s" "$TOPDIR" | tr / . |  tr -dc '[:alnum:]-_.')
        OPAMSWITCHISGLOBAL=ON
        OPAMSWITCHFINALDIR_BUILDHOST="$OPAMROOTDIR_BUILDHOST${OS_DIR_SEP}$set_opamrootandswitchdir_OPAMGLOBALNAME"
        OPAMSWITCHNAME_BUILDHOST="$set_opamrootandswitchdir_OPAMGLOBALNAME"
        OPAMSWITCHNAME_EXPAND="$set_opamrootandswitchdir_OPAMGLOBALNAME"
    else
        # shellcheck disable=SC2034
        OPAMSWITCHISGLOBAL=OFF
        if [ "${DKML_FEATUREFLAG_CMAKE_PLATFORM:-OFF}" = OFF ]; then
            OPAMSWITCHFINALDIR_BUILDHOST="$BUILDDIR_BUILDHOST${OS_DIR_SEP}_opam"
            if [ -z "$BUILD_BASEPATH" ]; then
                OPAMSWITCHNAME_EXPAND="$BUILDDIR_BUILDHOST"
            else
                OPAMSWITCHNAME_EXPAND="@@EXPAND_TOPDIR@@/$DKML_DUNE_BUILD_DIR"
            fi
            OPAMSWITCHNAME_BUILDHOST="$BUILDDIR_BUILDHOST"
        else
            if cmake_flag_off "$USERMODE"; then
                set_opamrootandswitchdir_EXPAND="$STATEDIR"
            else
                set_opamrootandswitchdir_EXPAND="$TARGET_OPAMSWITCH"
            fi
            if [ -x /usr/bin/cygpath ]; then
                set_opamrootandswitchdir_BUILDHOST=$(/usr/bin/cygpath -aw "$set_opamrootandswitchdir_EXPAND")
            else
                set_opamrootandswitchdir_BUILDHOST="$set_opamrootandswitchdir_EXPAND"
            fi
            # shellcheck disable=SC2034
            OPAMSWITCHFINALDIR_BUILDHOST="$set_opamrootandswitchdir_BUILDHOST${OS_DIR_SEP}_opam"
            # shellcheck disable=SC2034
            OPAMSWITCHNAME_EXPAND="$set_opamrootandswitchdir_BUILDHOST"
            # shellcheck disable=SC2034
            OPAMSWITCHNAME_BUILDHOST="$set_opamrootandswitchdir_BUILDHOST"
        fi
    fi
}
