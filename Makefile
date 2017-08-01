test:
	for script in hcvswitch.sh init.sh ; do \
	    docker run -v "$(shell pwd)/$$script:/tmp/FileToBeChecked" chrisdaish/shellcheck ; \
	done
