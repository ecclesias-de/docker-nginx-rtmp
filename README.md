# live.ecclesias.net streaming adjusted setup
This branch has been adapted for operation in a specific environment. 

The conditions are as follows:
Incoming traffic is managed by a HaProxy with TLS/SSL termination. It routes all traffic to the host on port 8443 and the routed to the container on port 80. The build process of the Dockerfile no longer takes place after manual triggering on the server but this is now controlled via Gitlab and the .gitlab-ci.yml. The build is realized with Kaniko. The built Docker image is then pushed into the internal registry. The kubernetes runners are managed via Helm.


## Changes
## Nginx TLS/SSL removed: 
* Server listen 443 ssl removed. Listen on http 80 and rtmp 1935 only 
* SSL/TLS settings commented out.
* Variable substitution for ports via Dockerfile


## nginx-rtmp directives
* https://github.com/JIEgOKOJI/nginx-rtmp/blob/master/directives.md

## live.ecclesias.net streaming setup

This is a compilation of various open-source tools to enable an easy-to-use streaming setup on [live.ecclesias.net](https://live.ecclesias.net).

We looked at dozens of great projects here on github and other web resources to compile our needed tools. Below are some links you might findhelpful.

The lua-scripts listed below were created by us. Please feel free to use them, just note that the terms of the MIT license apply.

A huge thank you to the [Erzbistum Hamburg](https://www.erzbistum-hamburg.de/) and their great support. They made this possible and permittedus to publish it. We really appreciate their belief that public money (like church taxes) should be invested in public code! If you work for other religious organizations, please inform them about this [campaign](https://publiccode.eu/de/).

## Resources
* https://github.com/ut0mt8/nginx-rtmp-module
* https://github.com/sergey-dryabzhinsky/nginx-rtmp-module
* https://github.com/arut/nginx-rtmp-module
* https://github.com/alfg/docker-nginx-rtmp
* https://github.com/bitpodio/k8s-openresty-streaming
* http://nginx.org
* https://luajit.org/
* https://luarocks.org/
* https://www.ffmpeg.org
* https://obsproject.com
* https://github.com/videojs/http-streaming
* https://isrv.pw/html5-live-streaming-with-mpeg-dash


