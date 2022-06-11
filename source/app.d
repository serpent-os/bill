/* SPDX-License-Identifier: Zlib */

/**
 * Bill
 *
 * Main entry point
 *
 * Authors: © 2022 Serpent OS Developers
 * License: ZLib
 */
module main;

import std.stdio : stderr;
import bill.logging;

/**
 * BuildHost helps identify certain host OS requirements
 */
struct BuildHost
{
    /** True if /usr and / are merged */
    bool usrMerged = true;
}

/**
 * Known system configuration
 */
struct BuildConfiguration
{
    /** Information on the host */
    BuildHost host;
}

/**
 * Return a build configuration at runtime
 *
 * Returns: an instantiated BuildConfiguration.
 */
BuildConfiguration buildConfiguration()
{
    BuildConfiguration bc;
    import std.file : isSymlink;
    import std.file : readLink;
    import std.path : absolutePath;

    static struct CheckPath
    {
        string source;
        string target;
    }

    CheckPath[] paths = [
        CheckPath("/bin", "/usr/bin"), CheckPath("/sbin", "/usr/sbin"),
    ];

    foreach (p; paths)
    {
        if (isSymlink(p.source) && readLink(p.source).absolutePath("/") == p.target)
        {
            continue;
        }
        bc.host.usrMerged = false;
        break;
    }

    return bc;
}

void main()
{
    trace("Checking host configuration");
    const auto bc = buildConfiguration();
    if (!bc.host.usrMerged)
    {
        error("Unsupported build host - /usr is not merged");
        return;
    }

    info("Host configuration is supported");
}
