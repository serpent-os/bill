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
import bill.stage;

import moss.core.logging : configureLogging;
import std.experimental.logger;
import std.file : dirEntries, SpanMode, exists;
import std.string : startsWith;
import std.conv : to;
import std.path : baseName;

void main() @system
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

    Stage[] stages;
    immutable stageDir = bc.rootDir ~ "/stages";
    if (!stageDir.exists)
    {
        errorf("Stage directory is missing: %s", stageDir);
        return;
    }

    foreach (i; dirEntries(stageDir, SpanMode.shallow, false))
    {
        auto s = i.name.baseName;
        immutable prefix = "stage";
        if (!s.startsWith(prefix))
        {
            continue;
        }
        auto nom = s[prefix.length .. $];
        if (nom.length < 1)
        {
            errorf("Invalid stage tree: %s", nom);
            return;
        }
        auto id = to!ulong(nom);
        stages ~= new Stage(id);
    }

    info("Host configuration is supported");
    trace(stages);
}
