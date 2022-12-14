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
import std.concurrency : send, receive, receiveOnly, thisTid, Tid, locate, prioritySend;
import std.string : format;
import bill.build_api;

/**
 * Implements a simple build worker mechanism via threading
 */
public final class BuildWorker : Thread
{

    @disable this();

    /**
     * Construct a new BuildWorker with the given job index
     */
    this(QueueAPI parent, uint workerIndex)
    {
        super(&runnable);
        this._workerIndex = workerIndex;
        isDaemon = false;
        this.parent = parent;
    }

    /**
     * Worker index
     *
     * Returns: integer worker index
     */
    pragma(inline, true) pure @property uint workerIndex() @safe @nogc nothrow const
    {
        return _workerIndex;
    }

    /**
     * Blocking main thread call, unlocks the thread
     */
    void startServing()
    {
        ourID.send(WorkerBeginMessage(thisTid()));
        receiveOnly!WorkerBeginResponse;
    }

    /**
     * Send a message to wake up and look for work
     * UB40 style
     */
    void awaken(bool blocking = true)
    {
        ourID.prioritySend(WorkerWakeMessage(thisTid(), blocking));
        if (blocking)
        {
            receiveOnly!WorkerWakeResponse;
        }
    }

    /**
     * Asynchrously shut down.
     */
    void shutdown()
    {
        ourID.prioritySend(WorkerStopMessage());
    }

private:

    /**
     * Main execution code
     */
    void runnable() @system
    {
        auto controller = locate("buildQueueMain");
        ourID = thisTid();

        /* Immediately send a "we're up message" */
        controller.send(WorkerActivatedMessage(ourID, workerIndex));
        receiveOnly!WorkerActivatedResponse;

        info(format!"Worker %d registered"(workerIndex));

        /* Await work transition */
        auto msg = receiveOnly!WorkerBeginMessage;
        msg.sender.send(WorkerBeginResponse(ourID));

        info(format!"Worker %d awaiting work"(workerIndex));

        running = true;
        bool lookForWork;
        bool shutdownRequired;

        while (running)
        {
            WorkerRequestJobResponse nextWork;

            /* Handle shutdown */
            if (shutdownRequired)
            {
                running = false;
                lookForWork = false;
                info(format!"Worker %d shutting down"(workerIndex));
                controller.send(WorkerStopResponse(ourID));
                break;
            }

            /* Handle wakeups / work requests */
            if (lookForWork)
            {
                info(format!"Worker %d looking for work"(workerIndex));
                lookForWork = false;
                controller.send(WorkerRequestJobMessage(ourID));
                nextWork = receiveOnly!WorkerRequestJobResponse;
            }

            /* Can haz job? */
            if (nextWork.item.isNull)
            {
                trace(format!"Worker %d found no work"(workerIndex));
            }
            else
            {
                trace(format!"Worker %d found work: %s"(workerIndex, nextWork.item.get));
            }

            /* Look for messages now */
            receive((WorkerWakeMessage msg) {
                if (msg.blocking)
                {
                    msg.sender.send(WorkerWakeResponse(ourID));
                }
                info(format!"Worker %d looking for work"(workerIndex));
                lookForWork = true;
            }, (WorkerStopMessage msg) { shutdownRequired = true; });
        }
    }

    uint _workerIndex;
    Tid ourID;
    QueueAPI parent;
    bool running;
}
