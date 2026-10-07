DYLIB = libNoWindowButtons.dylib

$(DYLIB): NoButtons.m
	xcrun clang -arch arm64 -arch x86_64 -mmacosx-version-min=11.0 \
		-dynamiclib -fobjc-arc -O2 -framework AppKit \
		-Wl,-reexport-lSystem -compatibility_version 1.0 -current_version 1.0 \
		-install_name @executable_path/../Frameworks/$(DYLIB) \
		-o $@ $<
	codesign --force --sign - $@

clean:
	rm -f $(DYLIB)

.PHONY: clean
