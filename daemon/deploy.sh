#!/bin/sh

dotnet deploy -host:daemon -site:daemon -scheme:default -edition:Debug -framework:net10.0 -architecture:x64