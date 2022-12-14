/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * Stage management
 *
 * Each stage in the bootstrap requires special management and
 * an encapsulation of build tasks to ensure a sane bootstrap
 * process.
 *
 * Authors: Copyright © 2022 Serpent OS Developers
 * License: Zlib
 */
module bill.stage;

import bill.build_plugin;
import bill.build_queue;
import moss.format.source.spec;
import std.algorithm : each, joiner, map;
import std.array : array;
import std.conv : ConvException, to;
import std.experimental.logger;
import std.file : dirEntries, SpanMode;
import std.path : baseName;
import std.range : empty;
import std.stdio : File;
import std.string : endsWith, format;

/**
 * Stage encapsulation
 *
 * Wraps contextual management and queue ordering.
 */
final class Stage
{

    @disable this();

    /**
     * Construct stage with given work tree
     */
    this(in string workTree) @trusted
    {
        /* We're loaded in a map operation */
        _workTree = workTree.dup;
        _index = 0;
        registry = new RegistryManager();
        plugin = new BuildPlugin();
        registry.addPlugin(plugin);
        buildQueue = new BuildQueue();

        immutable nom = workTree.baseName;
        immutable partial = nom["stage".length .. $];
        if (partial.length < 1)
        {
            return;
        }
        /* We'll dump core if this is wrong. Users fault. */
        try
        {
            _index = partial.to!ulong;
        }
        catch (ConvException ex)
        {
            fatal(format!"Invalid stage tree \"%s\".\nError: %s"(nom, ex));
        }
        _index = partial.to!ulong;
    }

    /**
     * Index property
     *
     * Returns: index of this stage
     */
    pure @property ulong index() @safe @nogc nothrow
    {
        return _index;
    }

    /**
     * String representation of Stage
     *
     * Returns: allocated string
     */
    override pure const(string) toString() @safe const
    {
        return format!"stage(%d)"(_index);
    }

    /**
     * Attempt to locate all recipes and load them
     */
    void loadRecipes() @system
    {
        foreach (item; dirEntries(_workTree, SpanMode.depth, false))
        {
            auto bn = item.baseName;
            if (!bn.endsWith(".yml"))
            {
                continue;
            }
            auto spec = new Spec(File(item.name));
            spec.parse();
            addRecipe(spec);
        }
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
        import std.algorithm : filter;

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
        toApply.each!((i) => buildQueue.enqueue(i.pkgID));

        buildQueue.run();
    }

private:

    ulong _index;
    string _workTree;
    BuildPlugin plugin;
    RegistryManager registry;

    BuildQueue buildQueue;
}
