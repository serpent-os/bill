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

/** 
 * Management of Build control
 */
final class BuildController
{
    /**
     * Add a recipe to our set of work
     */
    void addRecipe(Spec *recipe) @system
    {
        recipes ~= recipe;
        trace(format!"Loaded recipe for %s [%s]"(recipe.source.name, recipe.source.versionIdentifier));
    }

private:

    Spec*[] recipes;
}
