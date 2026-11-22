.PHONY: all appdir appimage clean check

SHELL := /usr/bin/env bash

all: appimage

appimage:
	./build.sh

check: appimage
	@test -x dist/DHLabel-x86_64.AppImage
	file dist/DHLabel-x86_64.AppImage

clean:
	rm -rf build dist
