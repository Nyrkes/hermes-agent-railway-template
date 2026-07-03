#!/bin/bash
set -euo pipefail

mkdir -p /data/.hermes/sessions
mkdir -p /data/.hermes/skills
mkdir -p /data/.hermes/workspace
mkdir -p /data/.hermes/pairing

cd /data/.hermes/workspace

exec hermes gateway run console
