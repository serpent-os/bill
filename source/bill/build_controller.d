/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * bill.build_controller
 *
 * Manage the builds for a given set of input YAMLS
 *
 * Authors: Copyright © 2022 Serpent OS Developers
 * License: Zlib
 */

module bill.build_controller;

import moss.format.source.spec;
import std.experimental.logger;
import std.algorithm : filter, map, joiner;
import std.string : format;
import moss.deps.registry;
import std.array : array, byPair;
import std.range : empty;

import bill.build_plugin;

/** 
 * Management of Build control
 */
final class BuildController
{
    this()
    {
        registry = new RegistryManager();
        plugin = new BuildPlugin();
        registry.addPlugin(plugin);
    }

    /**
     * Add a recipe to our set of work
     */
    void addRecipe(Spec* recipe) @system
    {
        plugin.addRecipe(recipe);
        trace(format!"Loaded recipe for %s [%s]"(recipe.source.name,
                recipe.source.versionIdentifier));
    }

    void build()
    {
        /* We need to build and install everything in the stage. */
        auto names = cast(RegistryItem[]) registry.listAvailable().array;
        Transaction tx = registry.transaction();
        tx.installPackages(names);
        auto toApply = tx.apply();
        if (toApply.empty)
        {
            fatal("No build order defined!");
        }
        auto problems = tx.problems;
        if (!problems.empty)
        {
            error("Cannot proceed with build due to problems: ");
            foreach (problem; problems)
            {
                error(problem);
            }
            fatal("quitting");
        }
        auto renderString = toApply.map!((a) => format!"%s (%s)"(a.info.name, a.info.versionID));
        info(format!"Build order: %s"(renderString.joiner(", ")));
    }

private:

    RegistryManager registry;
    BuildPlugin plugin;
}
