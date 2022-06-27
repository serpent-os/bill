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
import std.algorithm : filter, map;
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
        auto r = recipes[pkgID];
        return cast(const(Dependency)[]) r.rootBuild.buildDependencies.map!(
                (d) => Dependency(d, DependencyType.PackageName)).array;
    }

    /** We only support name dependencies */
    override const(Provider)[] providers(in string pkgID) const
    {
        auto r = recipes[pkgID];
        return [Provider(r.source.name, ProviderType.PackageName)];
    }

    /** noop */
    override void fetchItem(FetchContext fc, in string pkgID)
    {
    }

    /** Noop */
    override const(RegistryItem)[] list(in ItemFlags flags) const
    {
        return recipes.values
            .filter!((r) {
                if ((flags & ItemFlags.Installed) == ItemFlags.Installed)
                {
                    return (r in installationMap) !is null;
                }
                return true;
            })
            .map!((r) => recipetoItem(r))
            .array;
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
        recipes[genPkgID(recipe)] = recipe;
    }

private:

    RegistryItem recipetoItem(const(Spec)* spec) const
    {
        return RegistryItem(genPkgID(spec), cast(BuildPlugin) this,
                spec in installationMap ? ItemFlags.Installed : ItemFlags.Available);
    }

    auto genPkgID(const(Spec)* spec) const
    {
        return format!"source:%s-%s-%s"(spec.source.name,
                spec.source.versionIdentifier, spec.source.release);
    }

    Spec*[string] recipes;
    bool[Spec* ] installationMap;
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
        info(format!"Build order: %s"(toApply.map!((a) => a.pkgID)));
    }

private:

    RegistryManager registry;
    BuildPlugin plugin;
}
