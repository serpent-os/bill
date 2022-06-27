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
import std.algorithm : filter, map, sort, each;
import std.array : array;
import std.conv : to;
import std.experimental.logger;
import std.file : dirEntries, SpanMode, exists;
import std.path : baseName;
import std.range : empty;
import std.string : startsWith, format;

void main() @system
{
    configureLogging();
    globalLogLevel = LogLevel.trace;

    trace("--- bill is now starting ---");
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
    info("Host configuration is supported");

    trace(bc);

    /* Load the stages now */
    immutable stageDir = bc.rootDir ~ "/stages";
    if (!stageDir.exists)
    {
        error(format!"Stage directory is missing: %s"(stageDir));
        return;
    }

    auto stages = stageDir.dirEntries(SpanMode.shallow, false).array
        .filter!((s) => s.baseName.startsWith("stage") && s.isDir)
        .map!((s) => new Stage(s.name))
        .array;
    if (stages.empty)
    {
        error("No valid stages found");
        return;
    }
    /* Sort ascending */
    stages.sort!"a.index < b.index";
    stages.each!((s) {
        info(format!"Loading recipes in stage %s"(s.index));
        s.loadRecipes();
        s.build();
    });
}
