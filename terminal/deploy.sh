#!/bin/sh

dotnet deploy -site:daemon -cloud:aliyun -scheme:default -edition:Debug -framework:net8.0 -domain:default