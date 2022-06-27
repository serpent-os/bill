/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * bill.build_queue
 *
 * Thread-safe build queue
 *
 * The build queue is operated from the main thread and uses messaging
 * APIs to communicate with workers.
 *
 * Authors: Copyright © 2022 Serpent OS Developers
 * License: Zlib
 */

module bill.build_queue;

import core.atomic : atomicFetchAdd;
import std.container.rbtree;
import std.datetime.systime : Clock, SysTime;
import std.experimental.logger;
import std.string : format;

/**
 * Every build gets a job index.
 */
private alias BuildIndex = ulong;

/**
 * We set a BuildStatus per job.
 */
private enum BuildStatus
{
    Pending = 0,
    Claimed,
    Failed,
    Succeeded,
}

/**
 * Encapsulation of a build item
 *
 * Maps a string ID to our internal build type
 */
private struct BuildItem
{
    BuildIndex index;

    /** 
     *  Associated package ID
     */
    string pkgID;

    /* Timing information */
    SysTime creation;
    SysTime updated;
}

/**
 * Sorted BuildItem by job index - no dupes!
 */
private alias BuildTree = RedBlackTree!(BuildItem, "a.index < b.index", false);

/**
 * Dependency backed queue implementation.
 */
public final class BuildQueue
{

    /**
     * Construct a new BuildQueue and initialise as empty
     */
    this()
    {
        builds = new BuildTree();
    }

    /**
     * Run the BuildQueue to completion
     */
    void run()
    {
    }

    /**
     * Enqueue the operation.
     *
     * Do *NOT* use this outside of the main thread!
     *
     * Params:
     *      pkgID   = Corresponding package ID
     */
    void enqueue(const(string) pkgID)
    {
        immutable auto mctime = Clock.currTime();
        auto job = BuildItem(nextBuildIndex, pkgID, mctime, mctime);
        builds.insert([job]);
        trace(format!"New job allocated: %s"(job));
    }

private:

    /**
     * Atomically increment the build index, return last usable
     *
     * Returns: new build ID
     */
    ulong nextBuildIndex() @safe @nogc nothrow
    {
        return atomicFetchAdd(buildIndex, 1);
    }

    BuildTree builds;
    ulong buildIndex;
}