#Swift Radio

Swift Radio is an open source radio station player with robust and professional features. This is a fully realized Radio App built entirely in Swift 2. 

![alt text](http://matthewfecher.com/wp-content/uploads/2015/09/screen-1.jpg "Swift Radio")

##Video
View this [Getting started video](https://youtu.be/qi_F5epEpdM).

##Features

- LastFM API Integration to automatically download Album Art
- Loads and parses metadata (track & artist information)
- Current artist & track displayed on Stations page
- Displays Artist, Track and Album art on Lock Screen
- Ability to update playlist from server or locally. (Update stations anytime without resubmitting to app store!)
- Custom views optimized for iPhone 4s, 5, 6 and 6+ for backwards compatibility
- Compiles with Xcode 7 & Swift 2.0
- Background audio performance
- Supports local or hosted station images
- "About" page with ability to send email & visit website
- Uses industry standard SwiftyJSON library for easy JSON manipulation
- Pull to Refresh Stations
- Volume slider adjusted by volume +/- buttons on phone

##Important Notes

- Volume slider does not show up in Xcode simulator, only in device. Hopefully Apple fixes soon. 
- Radio stations in demo are for demonstration purposes only. 
- For a production product, you may want to swap out the MPMoviePlayerController for a more robust streaming library/SDK (with stream stitching, interruption handling, etc).
- Uses Meng To's [Spring](https://github.com/MengTo/Spring) library for animation, making it easy experiment with different UI/UX animations

##Credits
*Created by [Matthew Fecher](http://matthewfecher.com), Twitter: [@goFecher](http://twitter.com/goFecher)*
*Thanks to Basel Farag, from [Denver Swift Heads](http://www.meetup.com/Denver-Swift-Heads/) for the code review. Twitter: [@kacheflowe](http://twitter.com/kacheflowe)*

##Requirements

- iOS 8.0+ / Mac OS X 10.9+
- Xcode 7

##Setup

The "SwiftRadio-Settings.swift" file contains some project settings to get you started. Please enter your own LastFM Key. Watch this [Getting started video](https://youtu.be/LFvBU0odV4A) to get up and running quickly.

##Integration

Includes full Xcode Project that will jumpstart development.

##Stations 

Includes an example "stations.json" file. You may upload the JSON file to a server, so that you can update the stations in the app without resubmitting to the app store. The following fields are supported in the app:

- **name**: The name of the station as you want it displayed (e.g. "Sub Pop Radio")

- **streamURL**: The url of the actual stream

- **imageURL**: Station image url. Station images in demo are 350x206. Image can be local or hosted. Leave out the "http" to use a local image (You can use either: "station-subpop" or "http://myurl.com/images/station-subpop.jpg")

- **desc**: Short 2 or 3 world description of the station as you want it displayed (e.g. "Outlaw Country")

- **longDesc**: Long description of the station to be used on the "info screen". This is optional.

##Streaming Libraries

- You can use this Swift code as a front-end for a more robust streaming backend.
- In addition to the MPMoviePlayer, I've briefly tested it with the following two streaming libraries (and it works rather nicely): [Radio](https://github.com/hamedh/Radio) & [RadioKit](http://stormyprods.com/products/radiokit.php) 
- If you test it with a library, let me know!
