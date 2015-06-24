# Saguaro Connect - Beta

<a href="https://developer.apple.com/swift/"><img src="http://raincitysoftware.com/swift-logo.png" alt="swift" width="64" height="64" border="0" /></a>

_A swift 2.0 HTTP Session connection wrapper for iOS/OSX applications_

<a href="https://developer.apple.com/swift/"><img src="http://raincitysoftware.com/swift2-badge.png" alt="" width="65" height="20" border="0" /></a>
[![Build Status](https://travis-ci.org/darrylwest/saguaro-logger.svg?branch=master)](https://travis-ci.org/darrylwest/saguaro-logger)

## Features

* provides head, get, post, put, delete, patch
* asynchronous or synchronous
* simple request / response objects
* cookies
* multipart upload

## Installation

* cocoapods (unpublished, so pull from repo)
* git subproject/framework (from repo)

## How to use

### Simple synchronous use:
```
let connect = SAConnect()
let request = SARequest(url:"http://httpbin.org/get")
let response = connect.get( request )

print("response: \( response.json )") // dumps the json response
```

## License: MIT

Use as you wish.  Please fork and help out if you can.

- - -
darryl.west@raincitysoftware.com | Version 00.90.10
