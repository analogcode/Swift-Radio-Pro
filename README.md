#Swift Radio

Swift Radio is an open source radio station app with robust and professional features. This is a fully realized Radio App built entirely in Swift 2. This is the Xcode 7 branch. There is an Xcode 8 / Swift 2.3 branch [here](https://github.com/swiftcodex/Swift-Radio-Pro/tree/xcode8).

![alt text](http://matthewfecher.com/wp-content/uploads/2015/09/screen-1.jpg "Swift Radio")

##Video
View this [**GETTING STARTED VIDEO**](https://youtu.be/m7jiajCHFvc).
It's short & sweet to give you a quick overview.  
Give it a quick watch.

##Features

- LastFM API and iTunes API Integration to automatically download Album Art
- Parses metadata from streams (Track & Artist information)
- Ability to update Stations from server or locally. (Update stations anytime without resubmitting to app store!)
- Displays Artist, Track & Album Art on Lock Screen
- Custom views optimized for iPhone 4s, 5, 6 and 6+ for backwards compatibility
- Compiles with Xcode 7 & Swift 2.0
- Background audio performance
- Search Bar that can be turned on or off to search stations
- Supports local or hosted station images
- "About" screen with ability to send email & visit website
- Uses industry standard SwiftyJSON library for easy JSON manipulation
- Pull to Refresh stations

##Important Notes
- 9.08.16 Update: An Xcode 8 / Swift 2.3 branch as been added. It needs some fine-tuning. Feel free to dive in with PRs. It might be a few weeks until I have time to smooth it out: [https://github.com/swiftcodex/Swift-Radio-Pro/tree/xcode8](https://github.com/swiftcodex/Swift-Radio-Pro/tree/xcode8)
- 7.26.16 Update: AVPlayer development branch added, thanks [@kusikusa](https://github.com/kusikusa). Plus, this branch includes the Spotify API for downloading artwork: [AVPlayer/Spotify Branch](https://github.com/swiftcodex/Swift-Radio-Pro/tree/avplayer)
- 6.5.16 Update: Bluetooth streaming added, thanks [@fethica](https://github.com/fethica)
- 3.27.16 Update: Google handoff added, thanks [@GraemeHarrison](https://github.com/GraemeHarrison)
- 2.24.16 Update: Share icon added, thanks [@SuperChloe](https://github.com/SuperChloe).  
- 12.30.15 Update: UISearchBar added, thanks [@fethica](https://github.com/fethica). Turn it on/off in the "SwiftRadio-Settings" file.  
- 12.16.15 Update: New branch added using a single radio station.
- 12.14.15 Update: LastFM has reopened their API signups. Get one at [last.fm/api](http://www.last.fm/api).
- 10.21.15 Update: Added option to use iTunes API to download album art. (See FAQ below). iTunes art is 100px x 100px. i.e. It is smaller than LastFM artwork. So, if you use this API instead, you will want to adjust the UI of your app.
- Volume slider works great in devices, not simulator. This is an Xcode simulator issue.  
- Radio stations in demo are for demonstration purposes only. 
- For a production product, you may want to swap out the MPMoviePlayerController for a more robust streaming library/SDK (with stream stitching, interruption handling, etc).
- Uses Meng To's [Spring](https://github.com/MengTo/Spring) library for animation, making it easy experiment with different UI/UX animations
- SwiftyJSON & Spring are included in the repo to get you up & running quickly. It's on the roadmap to utilize CocoaPods in the future. 

##Credits
*Created by [Matthew Fecher](http://matthewfecher.com), Twitter: [@goFecher](http://twitter.com/goFecher)*  
*Thanks to Basel Farag, from [Denver Swift Heads](http://www.meetup.com/Denver-Swift-Heads/) for the code review.*  

##Requirements

- iOS 8.0+ / Mac OS X 10.9+
- Xcode 7

##Setup

The "SwiftRadio-Settings.swift" file contains some project settings to get you started. If you use LastFM, please enter your own LastFM Key.  
Watch this [Getting Started Video](https://youtu.be/m7jiajCHFvc) to get up & running quickly.

##Integration

Includes full Xcode Project to jumpstart development.

##Stations 

Includes an example "stations.json" file. You may upload the JSON file to a server, so that you can update the stations in the app without resubmitting to the app store. The following fields are supported in the app:

- **name**: The name of the station as you want it displayed (e.g. "Sub Pop Radio")

- **streamURL**: The url of the actual stream

- **imageURL**: Station image url. Station images in demo are 350x206. Image can be local or hosted. Leave out the "http" to use a local image (You can use either: "station-subpop" or "http://myurl.com/images/station-subpop.jpg")

- **desc**: Short 2 or 3 word description of the station as you want it displayed (e.g. "Outlaw Country")

- **longDesc**: Long description of the station to be used on the "info screen". This is optional.

##Contributions

Contributions are very welcome. Please create a separate branch (e.g. features/3dtouch). Please do not commit on master.

## Custom Work & Consulting

We have recent experience building iOS apps for both independent and high-profile clients (brand names and apps we can't discuss here, but, you would instantly recognize!) Additionally, we've built advanced versions of this open-source radio player for amazing independent clients (such as this one):

![RadioInformer](http://matthewfecher.com/wp-content/uploads/2016/08/SideBySide.jpg)

[Get in Touch](http://matthewfecher.com/contact/) to see what we can do for you!

##FAQ

Q: Do I have to pay you anything if I make an app with this code?  
A: Nope. This is completely open source, you can do whatever you want with it. It's usually cool to thank the project if you use the code. Go build stuff. Enjoy.

Summer 2016 Update: There's now dozens of apps in the app store successfully using this code! That's awesome. If you do use the code, you may want to change the graphics (reskin it) and make it your own. There's no fun in just resubmitting someone else's app to the app store "as is", add something to it! :)

Q: How do I use the iTunes API instead of LastFM?  
A: In the SwiftRadio-Settings.swift file, set the "useLastFM" key to "false". You do not need an API key to use the iTunes API. It is free.

Q: The LastFM site isn't working properly? I can't create an API key.  
A: LastFM will sometimes put API signups on hold. You can check back later or try a different API.

Q: It looks like your LastFM api key and secret might have been left in the code?  
A: Yes, people may use it for small amounts of testing. However, I ask that you change it before submitting to the app store. (Plus, it would be self-defeating for someone to submit it to the app store with the testing keys, as it would quickly throttle out and their album art downloads would stop working!)

Q: Is there another API to get album/track information besides LastFM and iTunes?  
A: Rovi has a pretty sweet [music API](http://prod-doc.rovicorp.com/mashery/index.php/Data/APIs/Rovi-Music). The [Echo Nest](http://developer.echonest.com/) has all kinds of APIs that are fun to play with. 

Q: I updated the album art size in the Storyboard, and now the sizing is acting funny?  
A: There is an albumArt constraint modified in the code. See the "optimizeForDeviceSize()" method in the NowPlayingVC.

Q: My radio station isn't playing?  
A: Paste your stream URL into a browser to see if it will play there. The stream may be offline or have a weak connection.

Q: Can you help me add a feature? Can you help me understand the code? Can you help with a problem I'm having?  
A: While I have a full-time job and other project obligations, I'd highly recommend you find a developer or mentor in your area to help. The code is well-documented and most developers should be able to help you rather quickly. While I am sometimes available for paid freelance work, **I am not able to provide any free support or modifications.** Thank you for understanding!

Q: The song names aren't appearing for my station?  
A: Check with your stream provider to make sure they are sending Metadata properly. If a station sends data in a unique way, you can modify the way the app parses the metadata in the "metadataUpdated" method in the NowPlayingViewController.

##Single Station Branch
There's now a branch without the StationsViewController. This is so you can use this code as a starting place for an app for just one radio station. View that [Branch Here](https://github.com/swiftcodex/Swift-Radio-Pro/tree/single-station).

##RadioKit SDK Example 

![alt text](http://matthewfecher.com/wp-content/uploads/2015/11/radiokit.jpg "RadioKit Example")

- You can use this Swift code as a front-end for a more robust streaming backend.
- Brian Stormont, creator of RadioKit, has created a branch with the professional [RadioKit](http://stormyprods.com/products/radiokit.php) SDK already integrated. **Plus, his branch adds rewind & fast forward stream playback.** This is an excellent learning tool for those who are interested in seeing how a streaming library integrates with Swift Radio Pro. View the [branch here](https://github.com/MostTornBrain/Swift-Radio-Pro/tree/RadioKit).

##Get Creative
Here's a branch of the code that plays streaming TV Stations instead of radio stations. https://github.com/msahins/myTV

![alt text](http://matthewfecher.com/wp-content/uploads/2015/11/myTV.png "Swift TV")

If you create an app with the code, or interesting project inspired by the code, shoot me an email: matthew.fecher@gmail.com. Note: As per the FAQ above, I am unable to offer any free support or modifications. Thanks!
