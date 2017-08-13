test:
	for script in hcvswitch.sh init.sh ; do \
		echo "Shellchecking $$script" ; \
		docker run -v "$(shell pwd)/$$script:/tmp/FileToBeChecked" chrisdaish/shellcheck ; \
	done
