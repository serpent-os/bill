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
 * Authors: © 2022 Serpent OS Developers
 * License: ZLib
 */
module main;

import bill.buildconf;

import moss.core.logging : configureLogging;

void main()
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
    const auto bc = buildConfiguration();
    if (!bc.host.usrMerged)
    {
        error("Unsupported build host - /usr is not merged");
        return;
    }

    info("Host configuration is supported");
}
