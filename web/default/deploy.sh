#!/bin/sh

dotnet deploy -host:web -site:default -edition:Debug -framework:net8.0 -architecture:x64