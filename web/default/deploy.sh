#!/bin/sh

dotnet deploy -host:web -site:default -edition:Debug -framework:net9.0 -architecture:x64