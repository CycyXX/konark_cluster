# konark_cluster

Konark Cluster project integrates the PULP Snitch cluster as a dependency.

## Overview

This project follows the Snitch cluster system integration guidelines to create a new top-level design that instantiates the `snitch_cluster_wrapper`.

## Project Structure

- `Bender.yml` - Dependency management configuration
- `Makefile` - Build system that uses Snitch cluster's make fragments
- `src/konark_cluster.sv` - Top-level module (placeholder for now)
- `cfg/konark.json` - Cluster configuration file

## Dependencies

The project depends on the PULP Snitch cluster repository:
- https://github.com/pulp-platform/snitch_cluster

## Build Instructions

1. Install Bender (dependency manager):
   ```bash
   # Download from https://github.com/pulp-platform/bender/releases
   ```

2. Resolve dependencies:
   ```bash
   bender update
   ```

3. Generate RTL files:
   ```bash
   make sn-rtl
   ```

## Next Steps

- Resolve the AXI dependency issue (requires multicast branch)
- Generate the snitch_cluster_wrapper from the configuration
- Update konark_cluster.sv to instantiate the generated wrapper
- Add proper interface definitions and connections