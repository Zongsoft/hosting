# The application address is inferred from --listen and the generated daemon.
server = ~

[name]
host = api.zongsoft.com
bind!legacy = http://*,http://[::]

[port]
bind!legacy = http://*:8080,http://[::]:8080
