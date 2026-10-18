APP_NAME := PresenceKeeper
LABEL := io.github.presencekeeper
BUILD_APP := build/$(APP_NAME).app
INSTALL_APP := $(HOME)/Applications/$(APP_NAME).app
AGENT := $(HOME)/Library/LaunchAgents/$(LABEL).plist
DOMAIN := gui/$(shell id -u)

.PHONY: build install uninstall clean

build:
	mkdir -p $(BUILD_APP)/Contents/MacOS
	cp Resources/Info.plist $(BUILD_APP)/Contents/Info.plist
	swiftc -O Sources/main.swift -o $(BUILD_APP)/Contents/MacOS/$(APP_NAME)
	codesign --force --sign - $(BUILD_APP)

install: build
	@launchctl bootout $(DOMAIN)/$(LABEL) 2>/dev/null || true
	mkdir -p $(HOME)/Applications $(HOME)/Library/LaunchAgents
	rm -rf $(INSTALL_APP)
	cp -R $(BUILD_APP) $(INSTALL_APP)
	sed 's|__EXECUTABLE__|$(INSTALL_APP)/Contents/MacOS/$(APP_NAME)|' Resources/$(LABEL).plist > $(AGENT)
	launchctl bootstrap $(DOMAIN) $(AGENT)

uninstall:
	@launchctl bootout $(DOMAIN)/$(LABEL) 2>/dev/null || true
	rm -f $(AGENT)
	rm -rf $(INSTALL_APP)

clean:
	rm -rf build
