#!/usr/bin/env bats


@test "post_push: hook is up-to-date" {
  run sh -c "cat Makefile | grep $DOCKERFILE: \
                          | cut -d ':' -f 2 \
                          | cut -d '\\' -f 1 \
                          | tr -d ' '"
  [ "$status" -eq 0 ]
  [ "$output" != '' ]
  expected="$output"

  run sh -c "cat '$DOCKERFILE/hooks/post_push' \
               | grep 'for tag in' \
               | cut -d '{' -f 2 \
               | cut -d '}' -f 1"
  [ "$status" -eq 0 ]
  [ "$output" != '' ]
  actual="$output"

  [ "$actual" == "$expected" ]
}


@test "syslogd: runs ok" {
  run docker run --rm --entrypoint sh $IMAGE -c 'syslogd --help'
  [ "$status" -eq 0 ]
}


@test "postfix: runs ok" {
  run docker run --rm --entrypoint sh $IMAGE -c '/usr/lib/postfix/master -d -t'
  [ "$status" -eq 0 ]
}


@test "main.cf: documentation dirs are fixed in default configuration" {
  run docker run --rm --entrypoint sh $IMAGE -c \
    'postconf | grep -Fx "manpage_directory = /dev/null"'
  [ "$status" -eq 0 ]

  run docker run --rm --entrypoint sh $IMAGE -c \
    'postconf | grep -Fx "readme_directory = /dev/null"'
  [ "$status" -eq 0 ]

  run docker run --rm --entrypoint sh $IMAGE -c \
    'postconf | grep -Fx "html_directory = /dev/null"'
  [ "$status" -eq 0 ]
}


@test "main.cf drop-in: readme_directory is changed correctly" {
  run docker run --rm \
    -v $(pwd)/test/resources/main.cf.d:/etc/postfix/main.cf.d:ro \
      $IMAGE sh -c 'postconf | grep -Fx "readme_directory = /some/dir"'
  [ "$status" -eq 0 ]
}

@test "main.cf drop-in: data_directory is changed correctly" {
  run docker run --rm \
    -v $(pwd)/test/resources/main.cf.d:/etc/postfix/main.cf.d:ro \
      $IMAGE sh -c 'postconf | grep -Fx "data_directory = /data/my/postfix"'
  [ "$status" -eq 0 ]
}


@test "master.cf drop-in: verify/unix service is changed correctly" {
  run docker run --rm \
    -v $(pwd)/test/resources/master.cf.d:/etc/postfix/master.cf.d:ro \
      $IMAGE sh -c 'postconf -M | grep -Fx \
        "verify     unix  -       -       y       -       1       verify"'
  [ "$status" -eq 0 ]
}

@test "master.cf drop-in: smtp-amavis/unix service is added correctly" {
  run docker run --rm \
    -v $(pwd)/test/resources/master.cf.d:/etc/postfix/master.cf.d:ro \
      $IMAGE sh -c 'postconf -M | grep -Fx \
        "smtp-amavis unix -       -       n       -       2       smtp -o smtp_data_done_timeout=1200 -o smtp_send_xforward_command=yes -o disable_dns_lookups=yes -o max_use=20 -o smtp_tls_security_level=none"'
  [ "$status" -eq 0 ]
}

@test "master.cf drop-in: 127.0.0.1:10025/inet service is added correctly" {
  run docker run --rm \
    -v $(pwd)/test/resources/master.cf.d:/etc/postfix/master.cf.d:ro \
      $IMAGE sh -c 'postconf -M | grep -Fx \
        "127.0.0.1:10025 inet n   -       n       -       -       smtpd -o content_filter= -o local_recipient_maps="'
  [ "$status" -eq 0 ]
}

@test "master.cf drop-in: policyd-spf/unix service is added correctly" {
  run docker run --rm \
    -v $(pwd)/test/resources/master.cf.d:/etc/postfix/master.cf.d:ro \
      $IMAGE sh -c 'postconf -M | grep -Fx \
        "policyd-spf unix -       n       n       -       0       spawn user=policyd-spf argv=/usr/bin/policyd-spf"'
  [ "$status" -eq 0 ]
}

@test "master.cf drop-in: pickup/unix service is replaced with pickup/fifo" {
  # pickup/fifo service is added
  run docker run --rm \
    -v $(pwd)/test/resources/master.cf.d:/etc/postfix/master.cf.d:ro \
      $IMAGE sh -c 'postconf -M | grep -Fx \
        "pickup     fifo  n       -       n       60      1       pickup -o content_filter= -o receive_override_options=no_header_body_checks"'
  [ "$status" -eq 0 ]

  # pickup/unix service is removed
  run docker run --rm \
    -v $(pwd)/test/resources/master.cf.d:/etc/postfix/master.cf.d:ro \
      $IMAGE sh -c 'test $(postconf -M | grep pickup | wc -l) -eq 1'
  [ "$status" -eq 0 ]
}

@test "master.cf drop-in: lmtp/unix service is changed correctly" {
  # lmtp/unix service is chrooted
  run docker run --rm \
    -v $(pwd)/test/resources/master.cf.d:/etc/postfix/master.cf.d:ro \
      $IMAGE sh -c 'postconf -M | grep -Fx \
        "lmtp       unix  -       -       y       -       -       lmtp"'
  [ "$status" -eq 0 ]

  # lmtp/unix service is defined only once
  run docker run --rm \
    -v $(pwd)/test/resources/master.cf.d:/etc/postfix/master.cf.d:ro \
      $IMAGE sh -c 'test $(postconf -M | grep lmtp | wc -l) -eq 1'
  [ "$status" -eq 0 ]
}


@test "chroot: nothing is chrooted by default" {
  run docker run --rm --entrypoint sh $IMAGE -c \
    "postconf -M | awk '{ print \$5 }' \
                 | tr -d '\n' \
                 | grep -xE '^n+$'"
  [ "$status" -eq 0 ]
}


@test "tls: only A grade ciphers are used" {
  run docker rm -f test-postfix
  run docker run -d --name test-postfix -p 25:25 $IMAGE
  [ "$status" -eq 0 ]
  run sleep 10

  run docker run --rm -i --link test-postfix:postfix \
    --entrypoint sh instrumentisto/nmap -c \
      'nmap --script ssl-enum-ciphers -p 25 postfix | grep "least strength: A"'
  [ "$status" -eq 0 ]

  run docker rm -f test-postfix
}

@test "tls: nmap produces no warnings on ciphers verifying" {
  run docker rm -f test-postfix
  run docker run -d --name test-postfix -p 25:25 $IMAGE
  [ "$status" -eq 0 ]
  run sleep 5

  run docker run --rm -i --link test-postfix:postfix \
    --entrypoint sh instrumentisto/nmap -c \
      'nmap --script ssl-enum-ciphers -p 25 postfix | grep "warnings" | wc -l'
  [ "$status" -eq 0 ]
  [ "$output" == "0" ]

  run docker rm -f test-postfix
}


@test "volume: postfix queue dirs are recreated for empty volumes" {
  run docker run --rm --tmpfs /var/spool/postfix/ $IMAGE sh -c \
    'test "$(ls /var/spool/postfix/ | tr -d "\n ")" = "activebouncecorruptdeferdeferredflushholdincomingmaildroppidprivatepublicsavedtrace"'
  [ "$status" -eq 0 ]
}
