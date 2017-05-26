#!/usr/bin/env bats


@test "postfix runs ok" {
  run docker run --rm --entrypoint sh $IMAGE -c '/usr/lib/postfix/master -d -t'
  [ "$status" -eq 0 ]
}
