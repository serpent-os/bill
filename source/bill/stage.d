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

import std.experimental.logger;
import std.string : format, endsWith;
import std.path : baseName;
import std.conv : to, ConvException;
import std.stdio : File;
import std.file : dirEntries, SpanMode;
import moss.format.source.spec;
import bill.build_controller;

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
        controller = new BuildController();

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
            controller.addRecipe(spec);
        }
    }

    void build() @system
    {
        controller.build();
    }

private:

    ulong _index;
    string _workTree;
    BuildController controller;
}
