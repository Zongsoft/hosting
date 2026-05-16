if command -v nginx >/dev/null 2>&1; then
	nginx -t
	nginx -s reload >/dev/null 2>&1 || true
fi
