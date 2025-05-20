.PHONY = shellcheck test
SHELLCHECK_SCRIPTS = init.sh hcvswitch.sh

test: shellcheck

shellcheck:
	@$(foreach script,$(SHELLCHECK_SCRIPTS),docker run -t --rm \
			-v "$(shell pwd)/$(script):/mnt/$(script)" \
			"koalaman/shellcheck-alpine:stable" \
			"shellcheck" "/mnt/$(script)" || exit;)
