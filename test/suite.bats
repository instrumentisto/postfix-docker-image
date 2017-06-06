#!/usr/bin/env bats


@test "post_push hook is up-to-date" {
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


@test "postfix runs ok" {
  run docker run --rm --entrypoint sh $IMAGE -c '/usr/lib/postfix/master -d -t'
  [ "$status" -eq 0 ]
}


@test "removed documentation dirs are fixed in default configuration" {
  run docker run --rm --entrypoint sh $IMAGE -c \
    'postconf | grep -Fx "manpage_directory = no"'
  [ "$status" -eq 0 ]

  run docker run --rm --entrypoint sh $IMAGE -c \
    'postconf | grep -Fx "readme_directory = no"'
  [ "$status" -eq 0 ]

  run docker run --rm --entrypoint sh $IMAGE -c \
    'postconf | grep -Fx "html_directory = no"'
  [ "$status" -eq 0 ]
}


@test "main.cf drop-in files are applied" {
  run docker run --rm \
    -v $(pwd)/test/resources/main.cf.d:/etc/postfix/main.cf.d:ro \
      $IMAGE sh -c 'postconf | grep -Fx "readme_directory = /some/dir"'
  [ "$status" -eq 0 ]

  run docker run --rm \
    -v $(pwd)/test/resources/main.cf.d:/etc/postfix/main.cf.d:ro \
      $IMAGE sh -c 'postconf | grep -Fx "data_directory = /data/my/postfix"'
  [ "$status" -eq 0 ]
}

@test "master.cf drop-in files are applied" {
  run docker run --rm \
    -v $(pwd)/test/resources/master.cf.d:/etc/postfix/master.cf.d:ro \
      $IMAGE sh -c 'postconf -M | grep -Fx \
        "verify     unix  -       -       y       -       1       verify"'
  [ "$status" -eq 0 ]

  run docker run --rm \
    -v $(pwd)/test/resources/master.cf.d:/etc/postfix/master.cf.d:ro \
      $IMAGE sh -c 'postconf -M | grep -Fx \
        "smtp-amavis unix -       -       n       -       2       smtp -o smtp_data_done_timeout=1200 -o smtp_send_xforward_command=yes -o disable_dns_lookups=yes -o max_use=20 -o smtp_tls_security_level=none"'
  [ "$status" -eq 0 ]

  run docker run --rm \
    -v $(pwd)/test/resources/master.cf.d:/etc/postfix/master.cf.d:ro \
      $IMAGE sh -c 'postconf -M | grep -Fx \
        "127.0.0.1:10025 inet n   -       n       -       -       smtpd -o content_filter= -o local_recipient_maps="'
  [ "$status" -eq 0 ]

  run docker run --rm \
    -v $(pwd)/test/resources/master.cf.d:/etc/postfix/master.cf.d:ro \
      $IMAGE sh -c 'postconf -M | grep -Fx \
        "policyd-spf unix -       n       n       -       0       spawn user=policyd-spf argv=/usr/bin/policyd-spf"'
  [ "$status" -eq 0 ]
}


@test "only A grade TLS ciphers are used" {
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

@test "nmap produces no warnings on TLS ciphers verifying" {
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
