FROM mcr.microsoft.com/dotnet/sdk:10.0

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
	apt-get install -y --no-install-recommends \
		systemd \
		nginx \
		curl \
		wget && \
	apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p \
	/run/systemd/system \
	/etc/nginx/conf.d \
	/var/lib/systemd/coredump

RUN ln -sf /lib/systemd/systemd /sbin/init && \
	ln -sf /lib/systemd/systemd /bin/systemd

WORKDIR /Zongsoft/hosting

RUN echo '#!/bin/bash\n\
export container=docker\n\
exec /sbin/init --log-target=journal 3>&1\n\
' > /usr/local/bin/start-systemd.sh && chmod +x /usr/local/bin/start-systemd.sh

EXPOSE 80
EXPOSE 8080
EXPOSE 8069

CMD ["/usr/local/bin/start-systemd.sh"]
