
PROJECT = SaguaroConnect
PLATFORM = 'platform=iOS Simulator,name=iPad 2,OS=9.3'

all:
	@make test

clean:
	xcodebuild -workspace $(PROJECT).xcworkspace -scheme "$(PROJECT)" clean

test:
	xcodebuild -workspace $(PROJECT).xcworkspace -scheme "$(PROJECT)" -sdk iphonesimulator -destination $(PLATFORM) test | xcpretty -c
	@( pod lib lint --quick )

build:
	xcodebuild -workspace $(PROJECT).xcworkspace -scheme "$(PROJECT)" -sdk iphonesimulator -destination $(PLATFORM) build

watch:
	@( ./watcher.js )

version:
	@( pod lib lint --quick )

.PHONY:	test
.PHONY:	build
.PHONY:	version
.PHONY:	publish

