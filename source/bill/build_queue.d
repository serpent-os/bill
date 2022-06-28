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

import bill.build_worker;
import core.atomic : atomicFetchAdd;
import std.concurrency : send, receive, receiveOnly, register, thisTid;
import std.container.rbtree;
import std.datetime.systime : Clock, SysTime;
import std.experimental.logger;
import std.parallelism : totalCPUs;
import std.string : format;
import core.sync.mutex;
import core.sync.condition;
import bill.build_api;

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
public final class BuildQueue : QueueAPI
{

    /**
     * Construct a new BuildQueue and initialise as empty
     *
     * Params:
     *      numWorkers  = Number of worker threads, 0 for automatic.
     */
    this(int numWorkers = 0) @system
    {
        builds = new BuildTree();

        if (numWorkers == 0)
        {
            numWorkers = totalCPUs() - 1;
        }
        this.numWorkers = numWorkers;
        workers.reserve(numWorkers);
        workers.length = numWorkers;

        mutNotify = new Mutex();
        condNotify = new Condition(mutNotify);

        info(format!"BuildQueue initialised with %d workers"(numWorkers));
    }

    /**
     * Run the BuildQueue to completion
     */
    void run()
    {
        register("buildQueueMain", thisTid());
        running = true;

        /* Start all the bees */
        foreach (i; 0 .. numWorkers)
        {
            workers[i] = new BuildWorker(this, i);
            workers[i].start();
        }

        ensureStarted();
        activateWorkers();
        warning("Waking..");
        synchronized (mutNotify)
        {
            condNotify.notifyAll();
        }
        warning("Ending builds");

        /* Tear down the workers */
        foreach (ref thr; workers)
        {
            thr.join();
            thr.destroy();
        }
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

    /**
     * Await work. We will sleep for 2 seconds max to allow other events
     * to happen.
     */
    override void awaitWork()
    {
        synchronized (mutNotify)
        {
            condNotify.wait(dur!"seconds"(2));
        }
    }

private:

    /**
     * Ensure all workers are registered
     */
    void ensureStarted()
    {
        uint activeWorkers = 0;
        while (activeWorkers < numWorkers)
        {
            receive((WorkerActivatedMessage msg) {
                msg.sender.send(WorkerActivatedResponse());
                ++activeWorkers;
            });
        }
    }

    /**
     * Pivot the workers into "go go go" mode.
     *
     * Each worker has been awaiting this message and will begin their
     * main loop.
     */
    void activateWorkers()
    {
        foreach (ref worker; workers)
        {
            worker.startServing();
        }
    }

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
    uint numWorkers;
    bool running;
    BuildWorker[] workers;
    __gshared Condition condNotify;
    __gshared Mutex mutNotify;
}
