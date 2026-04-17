FROM mcr.microsoft.com/dotnet/sdk:10.0

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    	systemd \
    	nginx \
    	curl \
    	wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN ln -sf /lib/systemd/systemd /sbin/init && \
    ln -sf /lib/systemd/systemd /bin/systemd

WORKDIR /Zongsoft/hosting

EXPOSE 80
EXPOSE 8080
EXPOSE 8069

CMD ["/sbin/init"]
