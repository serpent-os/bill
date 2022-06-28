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
import bill.build_api;

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

        /* Set all the workers as "free" (available) */
        isWorkerAvailable.reserve(numWorkers);
        isWorkerAvailable.length = numWorkers;

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
        ulong deadWorkers;

        /* Main loop */
        while (running)
        {
            /* Immediately request shutdown as we dont "work" */
            shutdown();

            receive((WorkerStopResponse msg) {
                ++deadWorkers;
                if (deadWorkers == numWorkers)
                {
                    running = false;
                    info("All workers completed");
                }
            });
        }

        /* Tear down */
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

private:

    void shutdown()
    {
        shuttingDown = true;
        foreach (ref thr; workers)
        {
            thr.shutdown();
        }
    }
    /**
     * Ensure all workers are registered
     */
    void ensureStarted()
    {
        uint activeWorkers;
        while (activeWorkers < numWorkers)
        {
            receive((WorkerActivatedMessage msg) {
                msg.sender.send(WorkerActivatedResponse());
                ++activeWorkers;
                /* Map them */
                tidToWorker[msg.sender] = msg.workerIndex;
                isWorkerAvailable[msg.workerIndex] = true;
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
    bool shuttingDown;
    BuildWorker[] workers;
    __gshared bool[] isWorkerAvailable;
    __gshared uint[Tid] tidToWorker;
}
