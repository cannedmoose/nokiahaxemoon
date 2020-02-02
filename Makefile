PHONY: release
release:
	lime clean html5
	lime build html5
	rm -rf docs/*
	cp -r Export/html5/bin docs/