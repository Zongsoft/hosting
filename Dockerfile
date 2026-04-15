FROM mcr.microsoft.com/dotnet/sdk:10.0

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
            systemd \
            nginx \
            curl \
            wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/*


RUN mkdir -p /etc/nginx/conf.d \
             /etc/systemd/multi-user.target.wants

WORKDIR /Zongsoft/hosting

CMD ["tail", "-f", "/dev/null"]
