/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * Bill
 *
 * Main entry point
 *
 * Authors: Copyright © 2022 Serpent OS Developers
 * License: Zlib
 */
module main;

import bill.buildconf;

import moss.core.logging : configureLogging;
import std.experimental.logger;

void main() @safe
{
    configureLogging();

    trace("--- bill is now starting ---");
    scope (exit)
    {
        trace("--- bill exited normally ---");
    }
    scope (failure)
    {
        error("--- bill exited abnormally ---");
    }
    trace("Checking host configuration");
    /* Always the relative . directory. */
    const auto bc = buildConfiguration(".");
    if (!bc.host.usrMerged)
    {
        error("Unsupported build host - /usr is not merged");
        return;
    }

    trace(bc);

    info("Host configuration is supported");
}
