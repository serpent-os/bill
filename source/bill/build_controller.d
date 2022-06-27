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

/**
 * Handle integration of recipes in the Registry
 */
final class BuildPlugin : RegistryPlugin
{

    /**
     * Perform a provider lookup
     */
    override RegistryItem[] queryProviders(in DependencyType dt, in string matcher,
            ItemFlags flags = ItemFlags.None)
    {
        switch (dt)
        {
        case DependencyType.PackageName:
            return recipes.byPair
                .filter!((r) => r.value.source.name == matcher)
                .map!((r) => recipetoItem(r.value))
                .array;
        default:
            return null;
        }
    }

    /** Noop */
    override ItemInfo info(in string pkgID) const
    {
        auto r = recipes[pkgID];
        return ItemInfo(r.source.name, r.rootPackage.summary,
                r.rootPackage.description, r.source.release, r.source.versionIdentifier,
                r.source.homepage, cast(immutable(string)[]) r.source.license);
    }

    /** Return dependencies */
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

    /** No fetching supported by us */
    override void fetchItem(FetchContext fc, in string pkgID)
    {
    }

    /** List all of the items */
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

    /** Direct lookup */
    override NullableRegistryItem queryID(in string pkgID) const
    {
        auto s = pkgID in recipes;
        if (s is null)
        {
            return NullableRegistryItem(RegistryItem.init);
        }
        return NullableRegistryItem(recipetoItem(*s));
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
        auto renderString = toApply.map!((a) => format!"%s (%s)"(a.info.name, a.info.versionID));
        info(format!"Build order: %s"(renderString.joiner(", ")));
    }

private:

    RegistryManager registry;
    BuildPlugin plugin;
}
