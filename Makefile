APP_NAME  := Boya
BUNDLE_ID := com.local.boya
CONFIG    ?= debug
APP       := $(APP_NAME).app
ICONSET   := /tmp/$(APP_NAME)-AppIcon.iconset

BIN_PATH  := $(shell swift build -c $(CONFIG) --show-bin-path 2>/dev/null)

.PHONY: all build app run clean icon stop

all: app

## Compile the Swift package.
build:
	swift build -c $(CONFIG)

## Compile + wrap the binary into a launchable, ad-hoc signed .app bundle.
app: build
	rm -rf "$(APP)"
	mkdir -p "$(APP)/Contents/MacOS" "$(APP)/Contents/Resources"
	cp "$(BIN_PATH)/$(APP_NAME)" "$(APP)/Contents/MacOS/$(APP_NAME)"
	cp Resources/Info.plist "$(APP)/Contents/Info.plist"
	cp Resources/AppIcon.icns "$(APP)/Contents/Resources/AppIcon.icns"
	codesign --force --deep --sign - "$(APP)"
	@echo "Built $(APP)"

## Build (if needed) and launch the app.
run: app
	open "$(APP)"

## Kill a running instance.
stop:
	-pkill -f "$(APP)/Contents/MacOS/$(APP_NAME)"

## Regenerate Resources/AppIcon.icns from icon.svg.
## Requires rsvg-convert (brew install librsvg) and iconutil (bundled with macOS).
icon:
	rm -rf "$(ICONSET)" && mkdir -p "$(ICONSET)"
	rsvg-convert -w 16    -h 16    icon.svg -o "$(ICONSET)/icon_16x16.png"
	rsvg-convert -w 32    -h 32    icon.svg -o "$(ICONSET)/icon_16x16@2x.png"
	rsvg-convert -w 32    -h 32    icon.svg -o "$(ICONSET)/icon_32x32.png"
	rsvg-convert -w 64    -h 64    icon.svg -o "$(ICONSET)/icon_32x32@2x.png"
	rsvg-convert -w 128   -h 128   icon.svg -o "$(ICONSET)/icon_128x128.png"
	rsvg-convert -w 256   -h 256   icon.svg -o "$(ICONSET)/icon_128x128@2x.png"
	rsvg-convert -w 256   -h 256   icon.svg -o "$(ICONSET)/icon_256x256.png"
	rsvg-convert -w 512   -h 512   icon.svg -o "$(ICONSET)/icon_256x256@2x.png"
	rsvg-convert -w 512   -h 512   icon.svg -o "$(ICONSET)/icon_512x512.png"
	rsvg-convert -w 1024  -h 1024  icon.svg -o "$(ICONSET)/icon_512x512@2x.png"
	iconutil -c icns "$(ICONSET)" -o Resources/AppIcon.icns
	rm -rf "$(ICONSET)"
	@echo "Regenerated Resources/AppIcon.icns"

## Remove build artifacts.
clean: stop
	rm -rf .build "$(APP)"
