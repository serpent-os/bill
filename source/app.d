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

import std.experimental.logger;

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
        error(readLink(p.source).absolutePath);
        bc.host.usrMerged = false;
        break;
    }

    return bc;
}

void main()
{
    info("Checking host configuration");
    const auto bc = buildConfiguration();
    if (!bc.host.usrMerged)
    {
        fatal("Unsupported build host - /usr is not merged");
        return;
    }

    info("Host configuration supported");
}
