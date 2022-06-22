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

import std.file : isSymlink;
import std.file : readLink;
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
}

/**
 * Return a build configuration at runtime
 *
 * Returns: an instantiated BuildConfiguration.
 */
BuildConfiguration buildConfiguration()
{
    BuildConfiguration bc;

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
