/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * bill.build_api
 *
 * Internal helpers for the BuildQueue & BuildWorker types
 *
 * Authors: Copyright © 2022 Serpent OS Developers
 * License: Zlib
 */

module bill.build_api;

public import std.concurrency : Tid;
public import std.datetime.systime : SysTime;
public import std.typecons : Nullable;

/**
 * Every build gets a job index.
 */
public alias BuildIndex = ulong;

/**
 * Each job can have exactly one status flag
 */
public enum BuildStatus
{
    /**
     * Job is awaiting collection
     */
    Pending = 0,

    /**
     * Job has been claimed, awaiting some work
     */
    Claimed,

    /**
     * Job failed (permanently)
     */
    Failed,

    /**
     * Job succeeded
     */
    Succeeded,
}

/**
 * Encapsulation of a build item
 *
 * Maps a string ID to our internal build type
 */
public struct BuildItem
{
    /**
     * Identifier for the job
     */
    BuildIndex index;

    /** 
     *  Associated package ID
     */
    string pkgID;

    /**
     * When was this job created?
     */
    SysTime creation;

    /**
     * When was the job last updated?
     */
    SysTime updated;
}

/**
 * Request for work may be null
 */
public alias NullableBuildItem = Nullable!(BuildItem, BuildItem.init);

/**
 * The BuildQueue implements our QueueAPI
 */
public interface QueueAPI
{
}

/**
 * When a worker is activated, it should notify the main loop
 */
struct WorkerActivatedMessage
{
    Tid sender;
    uint workerIndex;
}

/**
 * The main thread sends a response.
 */
struct WorkerActivatedResponse
{
}

/**
 * Set the worker to its main loop
 */
struct WorkerBeginMessage
{
    Tid sender;
}

/**
 * Ok boss.
 */
struct WorkerBeginResponse
{
    Tid sender;
}

/**
 * Worker has been told to wake up and check for work.
 * This is blocking as only unallocated workers are woken.
 */
struct WorkerWakeMessage
{
    Tid sender;
    /* If blocking, we must reply */
    bool blocking;
}

/**
 * Sent in response to a WorkerWakeMessage
 */
struct WorkerWakeResponse
{
    Tid sender;
}

/**
 * Main thread requires the worker to stop when it can.
 */
struct WorkerStopMessage
{
    Tid sender;
}

/**
 * Worker acknowledges that it has stopped
 */
struct WorkerStopResponse
{
    Tid sender;
}

/**
 * Worker is now requesting something to do.
 */
struct WorkerRequestJobMessage
{
    Tid sender;
}

/**
 * Worker recieves a potentially null job. go back to sleep :P
 */
struct WorkerRequestJobResponse
{
    Tid sender;
    NullableBuildItem item;
}
