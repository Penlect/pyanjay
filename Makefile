
# VERSION = $(shell git describe --tags --always)
VERSION = 0.1.0
TAG = $(shell git describe --tags --abbrev=0)
SDIST = pyanjay-$(VERSION).tar.gz

all:

build: dist/$(SDIST)


dist/$(SDIST): src/*.c include/*.h pyanjay/*.pyx pyanjay/*.pxd setup.py
	python3 setup.py build_ext --inplace
	python3 -m cython -a -3 pyanjay/*.pyx
	python3 setup.py sdist

clean:
	-rm -rf dist/
	-rm -rf build/
	-rm -rf pyanjay.egg-info/
	-rm pyanjay/*.so
	-rm pyanjay/*.c
	-rm pyanjay/*.html
	-rm -rf pyanjay/__pycache__/
	-rm -rf wheelhouse/

.PHONY: all build clean
