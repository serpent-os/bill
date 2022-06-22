/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * Build conf
 *
 * Helpers for determining build configuration
 *
 * Authors: Copyright © 2022 Serpent OS Developers
 * License: Zlib
 */
module bill.buildconf;

import std.exception : assumeWontThrow;
import std.file : isSymlink, readLink, exists;
import std.path : absolutePath;

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

    /** Base directory */
    string rootDir;
}

/**
 * Construct a build configuration at runtime
 *
 * Params:
 *      buildDir = Root of all build/data
 *
 * Returns: an instantiated BuildConfiguration.
 */
BuildConfiguration buildConfiguration(const string buildDir) @safe nothrow
{
    BuildConfiguration bc;
    bc.rootDir = assumeWontThrow(buildDir.absolutePath);

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
        immutable cmpEqual = assumeWontThrow(p.source.exists && isSymlink(p.source)
                && p.source.readLink.absolutePath("/") == p.target);
        if (cmpEqual)
        {
            continue;
        }
        bc.host.usrMerged = false;
        break;
    }

    return bc;
}
