#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://localhost:8000}"
EMAIL="smoke_$(date +%s)@example.com"
PASSWORD="smoke1234"
TITLE="Smoke post $(date +%s)"
CONTENT="Created by smoke_test.sh"

if command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN="python3"
elif command -v python >/dev/null 2>&1; then
  PYTHON_BIN="python"
else
  echo "FAILED: python3/python is required for JSON parsing."
  exit 1
fi

request() {
  local method="$1"
  local path="$2"
  local data="${3:-}"
  local auth="${4:-}"
  local content_type="${5:-application/json}"

  local args=(
    -sS
    -X "$method"
    "$BASE_URL$path"
    -H "Content-Type: $content_type"
  )

  if [[ -n "$auth" ]]; then
    args+=(-H "Authorization: Bearer $auth")
  fi

  if [[ -n "$data" ]]; then
    args+=(-d "$data")
  fi

  curl "${args[@]}" -w '\n%{http_code}'
}

read_body_and_code() {
  local response="$1"
  BODY="$(printf '%s\n' "$response" | sed '$d')"
  CODE="$(printf '%s\n' "$response" | tail -n1)"
}

assert_code() {
  local expected="$1"
  local step="$2"
  if [[ "$CODE" != "$expected" ]]; then
    echo "FAILED: $step (expected $expected, got $CODE)"
    echo "Response body: $BODY"
    exit 1
  fi
}

echo "Running smoke test against $BASE_URL"

register_payload=$(printf '{"email":"%s","password":"%s"}' "$EMAIL" "$PASSWORD")
register_response="$(request POST /api/v1/auth/register "$register_payload")"
read_body_and_code "$register_response"
assert_code "201" "register"

login_payload="username=$EMAIL&password=$PASSWORD"
login_response="$(request POST /api/v1/auth/login "$login_payload" "" "application/x-www-form-urlencoded")"
read_body_and_code "$login_response"
assert_code "200" "login"
TOKEN="$("$PYTHON_BIN" -c 'import json,sys; print(json.load(sys.stdin)["access_token"])' <<<"$BODY")"

create_payload=$(printf '{"title":"%s","content":"%s"}' "$TITLE" "$CONTENT")
create_response="$(request POST /api/v1/posts "$create_payload" "$TOKEN")"
read_body_and_code "$create_response"
assert_code "201" "create post"

list_response="$(request GET /api/v1/posts)"
read_body_and_code "$list_response"
assert_code "200" "list posts"

printf '%s' "$BODY" | "$PYTHON_BIN" -c 'import json,sys; posts=json.load(sys.stdin); 
if not isinstance(posts, list) or not posts: raise SystemExit("FAILED: list posts returned empty/non-list payload");
print(f"Smoke test passed: {len(posts)} post(s) visible.")'

echo "User: $EMAIL"
echo "Done."
