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

/**
 * Stage encapsulation
 *
 * Wraps contextual management and queue ordering.
 */
final class Stage
{

    @disable this();

    /**
     * Index property
     *
     * Returns: index of this stage
     */
    pure @property ulong index() @safe @nogc nothrow
    {
        return _index;
    }

package:

    /**
     * Construct stage with given index
     */
    this(ulong index)
    {
        _index = index;
    }

private:

    ulong _index;
}
