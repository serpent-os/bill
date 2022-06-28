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
 * The BuildQueue implements our QueueAPI
 */
public interface QueueAPI
{
    /**
     * Called from each thread to await a work condition
     */
    abstract void awaitWork();
}

/**
 * When a worker is activated, it should notify the main loop
 */
struct WorkerActivatedMessage
{
    Tid sender;
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
