/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * bill.build_worker
 *
 * The busy bee.
 *
 * Each worker is a simple thread that keeps claiming work
 * from the main thread until it is told to shut down.
 *
 * Authors: Copyright © 2022 Serpent OS Developers
 * License: Zlib
 */

module bill.build_worker;

import core.thread.osthread;
import std.experimental.logger;

/**
 * Implements a simple build worker mechanism via threading
 */
public final class BuildWorker : Thread
{

    @disable this();

    /**
     * Construct a new BuildWorker with the given job index
     */
    this(uint workerIndex)
    {
        super(&runnable);
        this.workerIndex = workerIndex;
        isDaemon = false;
    }

private:

    /**
     * Main execution code
     */
    void runnable() @system
    {
        error("We can't actually run yet :(");
    }

    uint workerIndex;
}
