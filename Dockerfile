ARG NGINX_VERSION=1.19.7
ARG NGINX_RTMP_VARIANT=ut0mt8
ARG NGINX_RTMP_VERSION=1.2.0
ARG LUAJIT_VERSION='2.0.5'
ARG LUAJIT_MAJOR_VERSION='2.0'
ARG NGX_DEVEL_KIT_VERSION='0.3.1'
ARG LUA_NGINX_MODULE_VERSION='0.10.15'
#ARG LUA_CJSON_VERSION='2.1.0'
ARG FFMPEG_VERSION=4.4
ARG LUAROCKS_VERSION=2.4.3

##############################
# Build the NGINX-build image.
FROM alpine:3.13 as build-nginx
ARG NGINX_VERSION
ARG NGINX_RTMP_VARIANT
ARG NGINX_RTMP_VERSION
ARG LUAJIT_VERSION
ARG LUAJIT_MAJOR_VERSION
ARG NGX_DEVEL_KIT_VERSION
ARG LUA_NGINX_MODULE_VERSION
ARG LUAROCKS_VERSION
#ARG LUA_CJSON_VERSION

# Build dependencies.
RUN apk add --update \
  build-base \
  ca-certificates \
  curl \
  gcc \
  libc-dev \
  libgcc \
  linux-headers \
  make \
  musl-dev \
  openssl \
  openssl-dev \
  pcre \
  pcre-dev \
  pkgconf \
  pkgconfig \
  zlib-dev

# Get nginx source.
RUN cd /tmp && \
  wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
  tar zxf nginx-${NGINX_VERSION}.tar.gz && \
  rm nginx-${NGINX_VERSION}.tar.gz

# Get nginx-rtmp module.
RUN cd /tmp && \
  wget https://github.com/${NGINX_RTMP_VARIANT}/nginx-rtmp-module/archive/refs/tags/v${NGINX_RTMP_VERSION}.tar.gz && \
  tar zxf v${NGINX_RTMP_VERSION}.tar.gz && rm v${NGINX_RTMP_VERSION}.tar.gz

RUN cd /tmp && \
  wget http://luajit.org/download/LuaJIT-${LUAJIT_VERSION}.tar.gz && \
  tar zxf LuaJIT-${LUAJIT_VERSION}.tar.gz && rm LuaJIT-${LUAJIT_VERSION}.tar.gz

RUN cd /tmp && \
  wget https://github.com/simpl/ngx_devel_kit/archive/v${NGX_DEVEL_KIT_VERSION}.tar.gz \
    -O ngx_devel_kit-${NGX_DEVEL_KIT_VERSION}.tar.gz && \
  tar zxf ngx_devel_kit-${NGX_DEVEL_KIT_VERSION}.tar.gz && rm ngx_devel_kit-${NGX_DEVEL_KIT_VERSION}.tar.gz

RUN cd /tmp && \
  wget https://github.com/openresty/lua-nginx-module/archive/v${LUA_NGINX_MODULE_VERSION}.tar.gz \
    -O lua-nginx-module-${LUA_NGINX_MODULE_VERSION}.tar.gz && \
  tar zxf lua-nginx-module-${LUA_NGINX_MODULE_VERSION}.tar.gz && rm lua-nginx-module-${LUA_NGINX_MODULE_VERSION}.tar.gz

#RUN cd /tmp && \
#  wget https://www.kyne.com.au/%7Emark/software/download/lua-cjson-${LUA_CJSON_VERSION}.tar.gz \
#    -O lua-cjson-${LUA_CJSON_VERSION}.tar.gz && \
#  tar zxf lua-cjson-${LUA_CJSON_VERSION}.tar.gz && rm lua-cjson-${LUA_CJSON_VERSION}.tar.gz

# Install luajit
RUN cd /tmp/LuaJIT-${LUAJIT_VERSION} && \
  make install

RUN echo curl -fSL https://github.com/luarocks/luarocks/archive/v${LUAROCKS_VERSION}.tar.gz -o luarocks-${LUAROCKS_VERSION}.tar.gz \
    && curl -fSL https://github.com/luarocks/luarocks/archive/v${LUAROCKS_VERSION}.tar.gz -o luarocks-${LUAROCKS_VERSION}.tar.gz \
    && tar xzf luarocks-${LUAROCKS_VERSION}.tar.gz \
    && cd luarocks-${LUAROCKS_VERSION} \
    && ./configure \
        --prefix=/usr/local \
        --with-lua=/usr/local \
        --lua-suffix=jit-2.0.5 \
        --with-lua-include=/usr/local/include/luajit-2.0/ \
    && make build \
    && make install

RUN /usr/local/bin/luarocks install lua-resty-core && \
 /usr/local/bin/luarocks install lua-resty-upload && \
 /usr/local/bin/luarocks install lua-resty-reqargs && \
 /usr/local/bin/luarocks install lua-cjson
# /usr/local/bin/luarocks install json4lua

#RUN cd /tmp/lua-cjson-${LUA_CJSON_VERSION} && \
#  ln -s /usr/local/include/luajit-2.0 /usr/local/include/lua && \
#  /usr/local/include/luajit-2.0 && \
#  make install

# Compile nginx with nginx-rtmp module.
RUN cd /tmp/nginx-${NGINX_VERSION} && \
  NGX_DEVEL_KIT_PATH=/tmp/ngx_devel_kit-${NGX_DEVEL_KIT_VERSION} \
  LUA_NGINX_MODULE_PATH=/tmp/lua-nginx-module-${LUA_NGINX_MODULE_VERSION} \
  LUAJIT_LIB=/usr/local/lib/lua LUAJIT_INC=/usr/local/include/luajit-${LUAJIT_MAJOR_VERSION} \
  ./configure \
  --prefix=/usr/local/nginx \
  --add-module=/tmp/nginx-rtmp-module-${NGINX_RTMP_VERSION} \
  --add-module=/tmp/ngx_devel_kit-${NGX_DEVEL_KIT_VERSION} \
  --add-module=/tmp/lua-nginx-module-${LUA_NGINX_MODULE_VERSION} \
#  --add-module=${NGX_DEVEL_KIT_PATH} \
#  --add-module=${LUA_NGINX_MODULE_PATH} \
  --conf-path=/etc/nginx/nginx.conf \
  --with-threads \
  --with-file-aio \
  --with-http_ssl_module \
  --with-debug \
  --with-ld-opt='-Wl,-rpath,/usr/local/lib' \
  --with-cc-opt="-Wimplicit-fallthrough=0" && \
  cd /tmp/nginx-${NGINX_VERSION} && make && make install

###############################
# Build the FFmpeg-build image.
FROM alpine:3.13 as build-ffmpeg
ARG FFMPEG_VERSION
ARG PREFIX=/usr/local
ARG MAKEFLAGS="-j4"

# FFmpeg build dependencies.
RUN apk add --update \
  build-base \
  coreutils \
  freetype-dev \
  lame-dev \
  libogg-dev \
  libass \
  libass-dev \
  libvpx-dev \
  libvorbis-dev \
  libwebp-dev \
  libtheora-dev \
  openssl-dev \
  opus-dev \
  pkgconf \
  pkgconfig \
  rtmpdump-dev \
  wget \
  x264-dev \
  x265-dev \
  yasm

RUN echo http://dl-cdn.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories
RUN apk add --update fdk-aac-dev

# Get FFmpeg source.
RUN cd /tmp/ && \
  wget http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz && \
  tar zxf ffmpeg-${FFMPEG_VERSION}.tar.gz && rm ffmpeg-${FFMPEG_VERSION}.tar.gz

# Compile ffmpeg.
RUN cd /tmp/ffmpeg-${FFMPEG_VERSION} && \
  ./configure \
  --prefix=${PREFIX} \
  --enable-version3 \
  --enable-gpl \
  --enable-nonfree \
  --enable-small \
  --enable-libmp3lame \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libvpx \
  --enable-libtheora \
  --enable-libvorbis \
  --enable-libopus \
  --enable-libfdk-aac \
  --enable-libass \
  --enable-libwebp \
  --enable-postproc \
  --enable-avresample \
  --enable-libfreetype \
  --enable-openssl \
  --disable-debug \
  --disable-doc \
  --disable-ffplay \
  --extra-libs="-lpthread -lm" && \
  make && make install && make distclean

# Cleanup.
RUN rm -rf /var/cache/* /tmp/*

##########################
# Build the release image.
FROM alpine:3.13
LABEL MAINTAINER Alfred Gutierrez <alf.g.jr@gmail.com>

ARG LUAJIT_VERSION
#ARG LUA_CJSON_VERSION

# Set default ports.
ENV HTTP_PORT 80
ENV HTTPS_PORT 443
ENV RTMP_PORT 1935

RUN apk add --update \
  ca-certificates \
  gettext \
  openssl \
  pcre \
  lame \
  libogg \
  libass \
  libvpx \
  libvorbis \
  libwebp \
  libtheora \
  opus \
  rtmpdump \
  x264-dev \
  x265-dev

COPY --from=build-nginx /usr/local/nginx /usr/local/nginx
COPY --from=build-nginx /usr/local/lib /usr/local/lib
COPY --from=build-nginx /usr/local/share/lua /usr/local/share/lua
COPY --from=build-nginx /usr/local/include/luajit-2.0 /usr/local/include/luajit-2.0/
COPY --from=build-nginx /usr/local/share/lua* /usr/local/share/
COPY --from=build-ffmpeg /usr/local /usr/local
COPY --from=build-ffmpeg /usr/lib/libfdk-aac.so.2.0.1 /usr/lib/libfdk-aac.so.2

# Add NGINX path, config and static files.
ENV PATH "${PATH}:/usr/local/nginx/sbin"
ADD nginx.conf /etc/nginx/nginx.conf.template
RUN mkdir -p /opt/data/hls && mkdir /opt/data/dash && chown -R nobody:nobody /opt/data &&  mkdir /www
ADD static /www/static

EXPOSE 1935
EXPOSE 80

CMD /bin/sh -c nginx
