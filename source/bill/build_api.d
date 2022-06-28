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
