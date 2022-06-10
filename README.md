## (Bootstrap) Bill

`bill` is a simple tool to perform a bootstrap of Serpent OS in a reproducible fashion. The resulting output of the process is a small set of `.stone` archives forming an initial bootstrap repository to then build the rest of the distribution.

The resulting repository should be **immutable** and the distribution bootstrapped (rebuilt with user-facing packages) with these.

Currently a high priority ticket item:

 - Improves boulder
 - Unlock builder infrastructure with seed repository (layering)

### Authors

Available under the terms of the [zlib](https://spdx.org/licenses/Zlib.html) license

Copyright &copy; 2022 Serpent OS Developers