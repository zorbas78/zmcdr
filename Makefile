APP_NAME := zcmdr
VERSION := 0.1.0
APP_BUNDLE := $(APP_NAME).app
DMG_FILE := $(APP_NAME)-$(VERSION).dmg

SWIFT := swift
SWIFT_FLAGS := -c release
SWIFT_BIN := .build/release/$(APP_NAME)

.PHONY: all build release app dmg run clean

all: dmg

build:
	$(SWIFT) build

release:
	$(SWIFT) build $(SWIFT_FLAGS)

app: release
	rm -rf "$(APP_BUNDLE)"
	mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	cp "$(SWIFT_BIN)" "$(APP_BUNDLE)/Contents/MacOS/"
	cp Resources/Info.plist "$(APP_BUNDLE)/Contents/Info.plist"
	cp Resources/icon.icns "$(APP_BUNDLE)/Contents/Resources/"
	cp Resources/splash.png "$(APP_BUNDLE)/Contents/Resources/"
	codesign --force --deep --sign - "$(APP_BUNDLE)"
	@echo "Created $(APP_BUNDLE)"

dmg: app
	rm -f "$(DMG_FILE)"
	hdiutil create -volname "$(APP_NAME) $(VERSION)" \
		-srcfolder "$(APP_BUNDLE)" \
		-ov \
		-format UDZO \
		"$(DMG_FILE)"
	@echo "Created $(DMG_FILE)"

run: build
	open "$(SWIFT_BIN)"

clean:
	rm -rf "$(APP_BUNDLE)"
	rm -f "$(DMG_FILE)"
	$(SWIFT) package clean
