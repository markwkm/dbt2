.PHONY: appimage clean debug package release test

default:
	@echo "targets: appimage (Linux only), clean, debug, package, release, test"

appimage:
	cmake -H. -Bbuild/appimage -DCMAKE_INSTALL_PREFIX=/usr
	cd build/appimage && make install DESTDIR=../AppDir
	cd build/appimage && make appimage

clean:
	-rm -rf build

debug:
	cmake -H. -Bbuild/debug -DCMAKE_BUILD_TYPE=Debug
	cd build/debug && make

package:
	git checkout-index --prefix=build/source/ -a
	cmake -Hbuild/source -Bbuild/package
	cd build/package && make package_source

release:
	cmake -H. -Bbuild/release
	cd build/release && make

test: debug
	cd build/debug && make test
