#!/bin/sh
set -eu

swift build
swift run ClockWidgetCoreBehaviorTests
