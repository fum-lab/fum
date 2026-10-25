# Извлечённый текст

Источник: <https://developers.google.com/youtube/v3/live/getting-started>

## Содержимое

YouTube Live Streaming API Overview  |  Google for Developers Skip to main content
YouTube
Data API
Live Streaming API
/
English
Deutsch
Español
Español – América Latina
Français
Indonesia
Italiano
Polski
Português – Brasil
Tiếng Việt
Türkçe
Русский
עברית
العربيّة
فارسی
हिंदी
বাংলা
ภาษาไทย
中文 – 简体
中文 – 繁體
日本語
한국어
Sign in
Guides Reference Samples
YouTube
Data API
Live Streaming API
Guides
Reference
Samples
Overview
Client Libraries
Authorize Requests
Overview
Get Auth Credentials
Server-side Web Apps
Client-side Web Apps
Installed Apps
Devices
Guides and Tutorials
Life of a Broadcast
Understanding Broadcasts and Streams
Ingestion Protocol Comparison
Delivering Content via DASH
Delivering Content via HLS
Delivering Content via RTMPS
Streaming Live Chat
Migration guide for default broadcasts and streams
Implementation Guide
Overview
Broadcasts and Streams
Tools
APIs Explorer
Home
Products
YouTube
Data API
Live Streaming API
YouTube Live Streaming API Overview Stay organized with collections Save and categorize content based on your preferences.
Page Summary
outlined_flag
The YouTube Live Streaming API facilitates the creation, updating, and management of live events on YouTube, allowing scheduling, stream linking, and state transitions.
Live events are represented by liveBroadcast resources, each linked to a single liveStream resource, which carries the actual audio-video feed.
The API allows for the insertion of cuepoint resources, which are used to trigger ad breaks during a live broadcast, providing options for immediate or scheduled insertion.
To effectively manage ad displays, content creators should claim their broadcast content via the YouTube Content ID API before the event starts, which is required to participate in the Content ID program.
Partial resources are used for efficiency in data retrieval with the part parameter, and proper troubleshooting involves monitoring stream status, and deleting/recreating broadcasts if they get stuck in intermediate statuses.
The YouTube Live Streaming API lets you create, update, and manage live events on YouTube. Using the API, you can schedule events (broadcasts) and associate them with video streams, which represent the actual broadcast content.
The Live Streaming API is actually comprised of components of the YouTube Data API and the YouTube Content ID API. The Data API enables YouTube users to manage their YouTube accounts, while the YouTube Content ID API enables interactions with YouTube's rights management system. However, all of the resources that make up the Live Streaming API are used only to create and manage live events.
This document is intended for developers who want to write applications to facilitate live broadcasting on YouTube. It explains basic concepts of YouTube and of the API itself. It also provides an overview of the different functions that the API supports.
Core concepts
broadcasts A broadcast represents an event that can be watched on YouTube as it happens. Broadcasts can also be recorded and saved as YouTube videos so that users can watch them after they happen. streams A stream identifies the audio-video content that is being communicated to YouTube. Each broadcast is associated with one video stream. cuepoints A cuepoint represents an ad break that can be inserted into a live broadcast.
API use cases
The list below suggests several ways to use the API in your application:
Schedule broadcasts and define broadcast settings. Your application could enable users to predefine broadcast settings and then select the settings to apply to a particular broadcast.
Associate video streams and broadcasts.
Enable broadcasters to define information about a broadcast and its video (using the YouTube Data API ) at the same time.
Simplify transitions between broadcast states (for example, testing or live ) and enable users to insert cuepoints.
Before you start
You need a Google Account to access the Google Cloud console , request an API key, and register your application.
Register your application with Google so that it can submit API requests.
After registering your application, select the YouTube Data API as one of the services that your application uses:
Go to the Cloud console and select the project that you just registered.
Visit the Enabled APIs page .
In the list of APIs, make sure the status is ON for the YouTube Data API v3 and, if you are a YouTube Content Partner, the YouTube Content ID API.
Familiarize yourself with the core concepts of the JavaScript Object Notation (JSON) data format. JSON is a common, language-independent data format that provides a simple text representation of arbitrary data structures. For more information, see json.org .
Authorizing API requests
As noted above, the Live Streaming API uses functionality that is technically part of either the YouTube Data API or the YouTube Content ID API. You can use the Content ID API to provide YouTube with metadata, ownership information, and policy information for your assets. (A live video broadcast is an example of an asset.) The API also lets you claim videos and set ad policies for your videos.
This section explains the authorization requirements for requests to the Content ID API , which are different from the requirements for authorizing other Live Streaming API requests.
Calling the Data API The API request must be authorized by the Google Account that owns the broadcasting YouTube channel. Calling the Content ID API The API request must be authorized by a Google Account that is linked to the content owner that owns the broadcasting YouTube channel.
Resources and resource types
A resource is an individual data entity with a unique identifier. The table below describes the
different types of resources that you will interact with using the Live Streaming API . Technically, all of these resources are
actually defined as part of either the YouTube Data API or the YouTube Content ID API . However, the liveBroadcast , liveStream , and cuepoint resources are
only used to create and manage live events.
Resources
liveBroadcast Contains information about an event that you are broadcasting on YouTube. A liveBroadcast resource is an extension of a YouTube video resource and sets the
video metadata that would be pertinent to a live broadcast but not to other YouTube videos.
As such, a liveBroadcast resource corresponds to exactly one YouTube video resource.
In fact, the liveBroadcast resource and the video resource share the
same ID. And after creating the broadcast using the Live Streaming API, you can use the
YouTube Data API to provide additional metadata about the video.
liveStream Contains information about the video stream that you are transmitting to YouTube. The stream
provides the content that will be broadcast to YouTube users. Once created, a liveStream resource can be bound to exactly one liveBroadcast resource. Similarly, the liveBroadcast resource can only be bound to one liveStream resource.
cuepoint Inserts a cuepoint in the broadcast video stream, which might trigger an ad break. Use the liveBroadcasts.cuepoint method to insert a cuepoint during a broadcast.
video Represents a single YouTube video. As noted above, a liveBroadcast resource is an extension of a video resource. You can use the YouTube Data API to update metadata about the video, such as the recording location or the regions where the broadcast will be viewable.
videoAdvertisingOptions Defines the advertising settings for a video (or broadcast). You use the YouTube Content ID API to set advertising options.
asset Represents a piece of intellectual property, such as a movie or an episode of a show. In this case, the broadcast video is the asset. You will use the YouTube Content ID API to create and manage asset resources.
claim Links a video to an asset that the video matches. You create a claim, using the YouTube Content ID API , to identify yourself as the owner of the broadcast video.
policy Defines rules that specify the circumstances under which you want your content to be viewable on YouTube or blocked from appearing on YouTube. You need to apply a policy to your broadcast video and can also specify a policy that YouTube will apply to user-uploaded videos that match your broadcast video.
Supported operations
The following table shows the different methods that the API supports:
Operations
list Retrieves ( GET ) a list of zero or more resources.
insert Creates ( POST ) a new resource.
update Modifies ( PUT ) an existing resource to reflect data in your request.
bind Links a liveBroadcast resource with a liveStream resource or removes such a link.
transition Changes the status of a liveBroadcast resource and initiates any processes associated with the new status. For example, when you transition a broadcast's status to testing , YouTube starts to transmit video to that broadcast's monitor stream.
delete Removes ( DELETE ) a specific resource.
The table below identifies the operations that are supported for different types of resources. Operations that insert, update, or delete resources always require user authorization . In some cases, list methods support both authorized and unauthorized requests, where unauthorized requests only retrieve public data while authorized requests can also retrieve information that is restricted to the currently authenticated user.
Supported Operations
list insert update bind transition cuepoint delete
liveBroadcast
liveStream
Partial resources
The API allows, and actually requires, the retrieval of partial resources so that applications avoid transferring, parsing, and storing unneeded data. This approach also ensures that the API uses network, CPU, and memory resources more efficiently.
The part parameter is a required parameter for any API request that retrieves or returns a YouTube Data API resource. The parameter identifies one or more top-level (non-nested) resource properties that should be included in an API response. For example, a liveStream resource has the following parts:
snippet
cdn
status
All of these parts are objects that contain nested properties, and you can think of these objects as groups of metadata fields that the API server might (or might not) retrieve. As such, the part parameter requires you to select the resource components that your application actually uses. This requirement serves two important purposes:
It reduces latency by preventing the API server from spending time retrieving metadata fields that your application doesn't use.
It reduces bandwidth usage by reducing (or eliminating) the amount of unnecessary data that your application might retrieve.
Over time, as resources add more parts, these benefits will only increase since your application will not be requesting newly introduced properties that it doesn't support.
Tips and best practices
Claim your content
If you would like to show ads during your broadcast, you need to claim the broadcast video before the event begins. To claim content, you must be a YouTube Content Partner participating in the Content ID program.
The process for claiming your live broadcast video is different than the normal process for claiming a video. When claiming live video, you need to create your claim before the video actually exists. The API does support this, and the life of a broadcast document explains the YouTube Content ID API calls that enable you to create your claim.
Preview and test your content
Upon receiving your inbound video stream, YouTube can then broadcast that video on two different outbound streams:
The monitor stream enables you to preview (and test) your video broadcast. It is a private stream that is only accessible to you. You can only transition a broadcast to the testing phase if the broadcast's monitor stream is enabled. The monitor stream does not show ad breaks.
The broadcast stream is the stream visible to your audience. You can set the broadcast's privacy status to either public , private , or unlisted . (A private broadcast is only visible to users who have been explicitly invited to watch it, while an unlisted broadcast is visible to anyone with a link to view it.)
You can choose to delay the broadcast stream so that it does not run concurrently with the monitor stream. By delaying the broadcast stream, you can have more fine-grained control over the time that you insert cuepoints into the broadcast.
However, delaying the broadcast stream makes it difficult for your live presenters to interact with your viewing audience. In addition, delaying the broadcast increases the likelihood that viewers will discover key details about the event from sources other than your broadcast. For example, if you are broadcasting a sporting event on a 60-second delay, viewers might learn about critical moments in the event from other real-time news sources before actually seeing them in the broadcast.
YouTube recommends that you enable the monitor stream for your broadcast so that you can test your content. You should choose whether to also delay your broadcast based on your desire to control timing of cuepoints as opposed to your desire to interact with your audience or provide real-time coverage of an event.
Running midroll ads during a broadcast stream
During a broadcast, you can insert a cuepoint to indicate that an ad break should start in
the broadcast as soon as possible or at a specified time. The ad break enables YouTube to run
midroll ads during the broadcast.
Ad breaks have the following characteristics:
It has a predefined length of time, which you set using the cuepoint resource's durationSecs property. After the ad break concludes, viewers return to the live broadcast.
When an ad break happens, an ad only plays in the video player for viewers who are watching
the broadcast when the cuepoint is inserted. An ad does not run when viewers refresh the page
where the broadcast is playing or when visitors start watching the broadcast after the
cuepoint is inserted.
The sequence of steps below reflects the best practice for inserting an ad break during your broadcast:
Set time offsets
When inserting a cuepoint, you can specify that it should be inserted right away or that it
should be inserted at a specific point in the broadcast. Your options depend on whether the
broadcast stream for your video is delayed.
If your broadcast stream is not delayed, then you can insert the cuepoint immediately or use
the walltimeMs property to have the ad break start at a particular time.
To start the ad break immediately, call the liveBroadcasts.cuepoint method. In the
resource in the request body, set the insertionOffsetTimeMs property's
value to 0 or do not specify a value for that property and do not specify
a value for the walltimeMs property.
Important: Note that viewers do not see the resulting ad
content immediately. There may be a delay of around 30 seconds before the ad content is
visible to users. During that delay, your broadcast stream will still be visible to your
viewers, and you need to watch the broadcast stream to determine when the ad content
actually displays instead of your monitor stream.
To start the ad break at a particular time, call the liveBroadcasts.cuepoint method and use the walltimeMs property to specify the desired time. The property value is an integer that represents
an epoch timestamp.
If your broadcast stream is delayed, then you can insert the cuepoint immediately as
described above, specify a clock time as described above, or you can specify a time offset to
determine when the ad break will start. The time offset specifies a point in your broadcast
when viewers should see an ad.
The offset value is measured in milliseconds from the beginning of the monitor stream for
your broadcast. Note that if your broadcast has a testing phase, then the monitor stream
starts when your broadcast transitions to the testing status. Otherwise, your
monitor stream starts when your broadcast transitions to the live status.
When inserting a cuepoint, set the cuepoint resource's insertionOffsetTimeMs property to the desired offset.
Calculate the time offset value
To retrieve the offset value, call the YouTube Player API's getCurrentTime function for the player that is playing the monitor stream. Use the retrieved value to insert the cuepoint in the broadcast stream at that time.
The possible values for the offset time can be calculated as the following range:
[(elapsed_time - broadcast_delay + Δ), (elapsed_time - Δ)]
The Δ is a five-second buffer at the beginning and end of the possible time offsets when YouTube cannot precisely insert a cuepoint. For example:
A broadcast has a five-minute testing phase.
The broadcast stream is delayed 60 seconds after the monitor stream.
The broadcaster is inserting the cuepoint four minutes after the broadcast transitions to live status. (This is three minutes after the broadcast stream becomes visible.)
In this case, the possible range of offset times is [(485,000), (535,000)] .
These times are specified in milliseconds, and are calculated using the following values:
elapsed_time=540000 – The monitor stream has run for nine
minutes (540 seconds, 540000 milliseconds) when the liveBroadcasts.cuepoint method is called.
broadcast_delay=60000 – The broadcast stream is delayed by 60 seconds, or 60000 milliseconds.
Δ=5000 – The five-second buffer when the cuepoint cannot be reliably inserted.
Troubleshooting and error handling
The following guidelines explain how to resolve specific problems that may arise. For the lists
of errors that each API method might return, see YouTube Live Streaming API - Errors .
When a broadcast transitions from one status to another, it may temporarily be assigned with another status while YouTube completes the actions associated with the transition. For example, if you send a liveBroadcasts.transition request to change a broadcast's status from ready to testing , YouTube will set the broadcast's status to testStarting and then complete the actions associated with the status change. When all of those actions have been completed, YouTube will update the broadcast's status to testing , thereby indicating that the transition is complete.
If a broadcast becomes stuck with a testStarting or liveStarting status, you need to call the liveBroadcasts.delete method and delete the broadcast. Then create a new broadcast, bind it to your live stream, and continue with the testing process.
As noted in the liveBroadcasts.transition method's documentation, you should confirm that the value of the status.streamStatus property for the stream bound to your broadcast is active before calling that method.
Except as otherwise noted, the content of this page is licensed under the Creative Commons Attribution 4.0 License , and code samples are licensed under the Apache 2.0 License . For details, see the Google Developers Site Policies . Java is a registered trademark of Oracle and/or its affiliates.
Last updated 2026-09-14 UTC.
Blog
The latest news on the YouTube blog
Issue Tracker
Something wrong? Send us a bug report!
YouTube Researcher Program
For researchers interested in using data from YouTube's global API
Tools
Google APIs Explorer
YouTube Player Demo
Configure a Subscribe Button
Issue Tracker
File a bug
Request a feature
See open issues
Product Info
Terms of Service
Developer Policies
Required Minimum Functionality
Branding Guidelines
Android
Chrome
Firebase
Google Cloud Platform
Google AI
All products
Terms
Privacy
Manage cookies
English
Deutsch
Español
Español – América Latina
Français
Indonesia
Italiano
Polski
Português – Brasil
Tiếng Việt
Türkçe
Русский
עברית
العربيّة
فارسی
हिंदी
বাংলা
ภาษาไทย
中文 – 简体
中文 – 繁體
日本語
한국어

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 22:09:58 MSK -->
<!-- content-sha256: sha256:d0541a42903237e1b8c5198e50f429c0e3c804b845fa2486527408ae62d05d87 -->
<!-- FUM-MD-RECENCY:END -->
