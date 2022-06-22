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
import bill.logging;

/**
 * Configure our multilogging
 */
private static void configureLogging(LogLevel level = LogLevel.all)
{
    auto mlog = new MultiLogger(level);
    mlog.insertLogger("tui", new ColorLogger(level));
    mlog.insertLogger("file", new FileLogger("bill.log", level));
    sharedLog = mlog;
}

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
