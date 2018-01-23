# High Availability, Redundant Recursive DNS

## Overview

This Docker stack is designed to run a `dnsdist` server that uses two `knot-resolver` resolver services (each of which have two `knot-resolver` instances) that share a `redis` cache. The intent is that an anycast address will point to and check the `dnsdist` instance.

It is configured to be resilient and allow zero-downtime upgrades and configuration changes.

A backend is composed of a single `knot-resolver` instance. All of the knot-resolver backends are configured to share a single `redis` cache, which allows the cache to persist across backend restarts.

In the event both backends go down, `dnsdist` will continue to serve cached responses for 10 minutes (configurable).

## disdist
`dnsdist` is a highly DNS-, DoS- and abuse-aware loadbalancer. Its goal in
life is to route traffic to the best server, delivering top performance
to legitimate users while shunting or blocking abusive traffic.

`dnsdist` is dynamic, in the sense that its configuration can be changed at
runtime, and that its statistics can be queried from a console-like
interface.

All `dnsdist` features are documented at [dnsdist.org](http://dnsdist.org).

## knot-resolver
Knot DNS Resolver is a caching full resolver implementation written in C and [LuaJIT][luajit], both a resolver library and a daemon. The core architecture is tiny and efficient, and provides a foundation and
a state-machine like API for extensions. There are four of those built-in - *iterator*, *validator* and two caching modules. Most of the [rich features](https://knot-resolver.readthedocs.io/en/latest/modules.html) are written in Lua(JIT) and C. Batteries are included, but optional.

The LuaJIT modules, support DNS privacy and DNSSEC, and persistent cache with low memory footprint make it a great personal DNS resolver or a research tool to tap into DNS data. TL;DR it's the [OpenResty][openresty] of DNS.

Several cache backends (LMDB, Redis and Memcached), strong filtering rules, and auto-configuration with etcd make it a great large-scale resolver solution.

The server adopts a [different scaling strategy][scaling] than the rest of the DNS recursors - no threading, shared-nothing architecture (except MVCC cache that may be shared) that allows you to pin instances on available CPU cores and grow by self-replication. You can start and stop additional nodes depending on the contention without downtime.

It also has strong support for DNS over TCP, notably TCP Fast-Open, query pipelining and deduplication, and response reordering.

