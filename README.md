## (Bootstrap) Bill

`bill` is a simple tool to perform a bootstrap of Serpent OS in a reproducible fashion. The resulting output of the process is a small set of `.stone` archives forming an initial bootstrap repository to then build the rest of the distribution.

The resulting repository should be **immutable** and the distribution bootstrapped (rebuilt with user-facing packages) with these.

Currently a high priority ticket item:

 - Improves boulder
 - Unlock builder infrastructure with seed repository (layering)

### Requirements

 - moss-container
 - boulder
 - moss
 - Merged-`/usr` host OS

### Plan

Subject to change and currently a brain dump.

#### Environment:

Stage1-2:

Fancy chroot in which `boulder` can run from `/tools`, a usable
distro is found at `/host` and we can immediately set about replacing
those components.

Minimal optimisation should be employed during bootstrap (`-O2`) as
we really need the performance at stage4+.

#### Stage0: Prepare `/tools`

 - Install `boulder` to `/tools`
 - Install `moss` to `/tools`
 - Install `moss-container` to `/tools`

#### Stage1: (replace `/host`)

 - Use stage0 as `/tools`
 - Use host OS as `/host` (usr-merge)
 - Cross-compile rudimentary GNU toolchain (libstdc++/libgcc/etc)
 - Set global `PREFIX` to `/usr/stage1`
 - Set `PT_INTERP` to `/usr/stage1/lib/ld-linux-*.so.2`
 - Set `includedir` to `/usr/stage1/include`
 - etc.
 - `moss install` a new root 

#### Stage2: Replace `/tools`

 - Repackage upstream binary `ldc2` release
 - Build dependent libraries:
    - `rocksdb`
    - `zstd`
    - `curl`
    - `openssl`
 - Build our tooling:
   - `-L=-dynamic-linker=/usr/stage1/lib/ld-linux-*.so.2`
   - `--link-defaultlib-shared=false`
 - Set prefix + co back to `/usr`

#### Stage2.5:

 - Construct a binary repo `seed` from all of our `.stone`s

#### Stage3: LLVMification

 - All `native` options now, no twisty bootstrappy
 - Seed entirely from `seed` repo
 - GNU toolchain respecting LLVM preference
 - Build `libcxx`
 - Build `toolchain` (llvm)
 - Build `lld`

#### Stage4: Whole hog rebootstrap

 - Low level pkgs + libs
 - Native LDC
 - Serpent tooling (`moss`, `moss-container`, `boulder`)

### Authors

Available under the terms of the [zlib](https://spdx.org/licenses/Zlib.html) license

Copyright &copy; 2022 Serpent OS Developers