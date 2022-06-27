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
import std.string : format;
import moss.deps.registry;
import std.array : array;
import std.range : empty;

/**
 * Handle integration of recipes in the Registry
 */
final class BuildPlugin : RegistryPlugin
{

    /**
     * No support for anything
     */
    override RegistryItem[] queryProviders(in DependencyType dt, in string matcher,
            ItemFlags flags = ItemFlags.None)
    {
        return null;
    }

    /** Noop */
    override ItemInfo info(in string pkgID) const
    {
        return ItemInfo();
    }

    /** Noop */
    override const(Dependency)[] dependencies(in string pkgID) const
    {
        return null;
    }

    /** Noop */
    override const(Provider)[] providers(in string pkgID) const
    {
        return null;
    }

    /** noop */
    override void fetchItem(FetchContext fc, in string pkgID)
    {
    }

    /** Noop */
    override const(RegistryItem)[] list(in ItemFlags flags) const
    {
        return null;
    }

    override NullableRegistryItem queryID(in string pkgID) const
    {
        return NullableRegistryItem(RegistryItem.init);
    }

    /** Noop */
    override void close()
    {
    }

    void addRecipe(Spec* recipe) @system
    {
        recipes ~= recipe;
    }

private:
    Spec*[] recipes;

}

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
        info(format!"Build order: %s"(toApply));
    }

private:

    RegistryManager registry;
    BuildPlugin plugin;
}
