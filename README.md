Postfix Docker Image
====================

[![Build Status](https://travis-ci.org/instrumentisto/postfix-docker-image.svg?branch=master)](https://travis-ci.org/instrumentisto/postfix-docker-image) [![Docker Pulls](https://img.shields.io/docker/pulls/instrumentisto/postfix.svg)](https://hub.docker.com/r/instrumentisto/postfix) [![Uses](https://img.shields.io/badge/uses-s6--overlay-blue.svg)][21]




## Supported tags and respective `Dockerfile` links

- `3.3.1`, `3.3`, `3`, `latest` [(debian/Dockerfile)][101]
- `3.3.1-alpine`, `3.3-alpine`, `3-alpine`, `alpine` [(alpine/Dockerfile)][102]




## What is Postfix?

[Postfix][13] is a free and open-source mail transfer agent (MTA) that routes and delivers electronic mail, intended as an alternative to [Sendmail MTA][12].

It is [Wietse Venema][10]'s mail server that started life at [IBM research][11] as an alternative to the widely-used [Sendmail][12] program. Now at Google, Wietse continues to support Postfix.

Postfix attempts to be fast, easy to administer, and secure. The outside has a definite Sendmail-ish flavor, but the inside is completely different.

> [www.postfix.org](http://www.postfix.org)

![Postfix Logo](http://www.postfix.org/mysza.gif)




## How to use this image

To run Postfix just mount your configuration files and start the container: 
```bash
docker run -d -p 25:25 -v /my/main.cf:/etc/postfix/main.cf instrumentisto/postfix
```


### Configuration

To configure Postfix you may use one of the following ways (but __not both at the same time__):

1.  __Drop-in files__.  
    Put your configuration files (must end with `.cf`) in `/etc/postfix/main.cf.d/` and `/etc/postfix/master.cf.d/` directories. These files will be applied to default Postfix configuration when container starts.
    
    ```bash
    docker run -d -p 25:25 \
               -v /my/main.cf:/etc/postfix/main.cf.d/10-custom.cf:ro \
               -v /my/master.cf:/etc/postfix/master.cf.d/10-custom.cf:ro \
           instrumentisto/postfix
    ```
    
    This way is convenient if you need only few changes to default configuration, or you want to keep different parts of configuration in different files.

2.  Specify __whole configuration__.  
    Put your configuration files (`main.cf` and `master.cf`) in `/etc/postfix/` directory, so fully replace the default configuration files provided by image.
    
    ```bash
    docker run -d -p 25:25 \
               -v /my/main.cf:/etc/postfix/main.cf:ro \
               -v /my/master.cf:/etc/postfix/master.cf:ro \
           instrumentisto/postfix
    ```
    
    This way is convenient when it's easier to specify the whole configuration at once, rather than reconfigure default options.

#### Default configuration

To see default Postfix configuration of this Docker image just run:
```bash
# for main.cf
docker run --rm instrumentisto/postfix postconf

# for master.cf
docker run --rm instrumentisto/postfix postconf -M
```




## Image versions


### `X`

Latest version of `X` Postfix major version.


### `X.Y`

Latest version of `X.Y` Postfix minor version.


### `X.Y.Z`

Concrete `X.Y.Z` version of Postfix.


### `alpine`

This image is based on the popular [Alpine Linux project][1], available in [the alpine official image][2].
Alpine Linux is much smaller than most distribution base images (~5MB), and thus leads to much slimmer images in general.

This variant is highly recommended when final image size being as small as possible is desired. The main caveat to note is that it does use [musl libc][4] instead of [glibc and friends][5], so certain software might run into issues depending on the depth of their libc requirements. However, most software doesn't have an issue with this, so this variant is usually a very safe choice. See [this Hacker News comment thread][6] for more discussion of the issues that might arise and some pro/con comparisons of using Alpine-based images.




## Important tips

As far as Postfix writes its logs only to `syslog`, the `syslogd` process runs inside container as second side-process and is supervised with [`s6` supervisor][20] provided by [`s6-overlay` project][21].


### Logs

The `syslogd` process of this image is configured to write everything to `/dev/stdout`.

To change this behaviour just mount your own `/etc/syslog.conf` file with desired log rules.


### s6-overlay

This image contains [`s6-overlay`][21] inside. So you may use all the [features it provides][22] if you need to.




## License

Postfix itself is licensed under [IPL-1 license][91].

Postfix Docker image is licensed under [MIT license][92].




## Issues

We can't notice comments in the DockerHub so don't use them for reporting issue or asking question.

If you have any problems with or questions about this image, please contact us through a [GitHub issue][3].





[1]: http://alpinelinux.org
[2]: https://hub.docker.com/_/alpine
[3]: https://github.com/instrumentisto/postfix-docker-image/issues
[4]: http://www.musl-libc.org
[5]: http://www.etalabs.net/compare_libcs.html
[6]: https://news.ycombinator.com/item?id=10782897
[10]: http://www.porcupine.org/wietse
[11]: http://www.research.ibm.com
[12]: http://www.sendmail.org
[13]: https://en.wikipedia.org/wiki/Postfix_(software)
[20]: http://skarnet.org/software/s6/overview.html
[21]: https://github.com/just-containers/s6-overlay
[22]: https://github.com/just-containers/s6-overlay#usage
[91]: http://www.postfix.org/IBM-Public-License-1.0.txt
[92]: https://github.com/instrumentisto/postfix-docker-image/blob/master/LICENSE.md
[101]: https://github.com/instrumentisto/postfix-docker-image/blob/master/debian/Dockerfile
[102]: https://github.com/instrumentisto/postfix-docker-image/blob/master/alpine/Dockerfile
