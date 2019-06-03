1.17.0 Release
--------------
* Numerous clean up and formatting fixes
* More porting to Kirigami in preparation for mobile
* Improved initial connection/startup performance
* It's now possible to enable/disable hosts without adding/removing
* Fixed: Handle corrupted/incomplete host config properly
* Fixed: regression to default to playing zone
* Fixed: playback controls sizing craziness when panel grows/shrinks
* Requires Qt 5.12 or later

1.16.0 Release
--------------
* Add next to play and end of list options in Track Detail
* Clean up the logging/debugging stuff
  * Logging can be enabled on Config/Playback Options
* Internal comms clean up; handle failed connections gracefully
* Use MCWS friendlyname instead of host:port for connection display
  * Host:port must still be set up correctly and are used for the connection to MCWS
  * Might require MCWS host to be re-configured (hopefully not)
* More robust track info support for Web Streams
* Updated some controls and config options to better handle QuickControls2-Desktop-Style
* Change the zone view format to bring track pos slider up with playback countdown
* Track pos slider now defaults to "show" on new installs

1.15.1 Release
--------------
* Really work with Qt >= 5.11

1.15.0 Release
--------------
* Fix "highlight playing track" on search (regression)
* Fix resetting view when connection changes (regression)
* Fix Splash import to 2.11 (regression)
* Show zone cover art in background on popup window
* Port away from PlasmaCore.IconItem to Kirigami.Icon
* Fix explicit sizing vs. sizing by zone count for adv panel view
* New install defaults adv panel sizing to size by zone count
* Hiding zones is now smoother when changing connection

1.14 Release
------------
* Update readme for web streams setup
* Major Refactor/rename/cleanup mcws connection interface
* Fix flashing pause indicator on panel view (regression)
* Temporarily removed the Streams page
* Rework the command submission/refresh for faster response to change
* Add debug logger window (Enable with allowDebug=true in main.xml)

1.13 Release
------------
* Requires Qt 5.11+/Kirigami 2.3+
* Add option to disable scrolling track name
* Refactor listview delegates - fixes some scrolling/painting anamolies
* Port away from QQC1 to QQC2/Kirigami
* Port to "helpers", common QML modules for other projects
* Major refactor for the splasher
* Remove transition animations from list views (paint issues)
* Add basic DSP features (currently only Equalizer On)
* Use animatedLoad on Track images, speeds larger searches, scrolling
* Refactor compact view to make L-to-R/R-to-L size properly
* Initial support for streaming sources (SomaFM only, currently)
* Hacks to handle viewing web streams a little nicer
* Numerous performance updates regards animations and cover art
* Much more robust panel view sizing, RTL and LTR
* Add feature to hide zones from the views (does not save across sessions)
* Add config option to hide playback controls completely

1.12 Release
------------
* Clean up Connections Config
* Compact view positioning and sizing works better with Latte and Plasma5 panels
* Fix for Track Positioner crashing MC
* Zone poller uses less CPU resource
* Playback commands are more responsive
* Fix display issue with null artist or album fields
* Issuing many playback commands simultaneously no longer crashes MC
* Marquee track name in compact view

1.11 Release
------------
* Bugfixes and cleanup for null/missing fields from MCWS search
* Add repeat mode/shuffle mode support
* Add Audio Path display
* Add Audio Device selection support
* TrackView option to send list to any other zone
* Add sorting option for all track lists (searches/playlists/playing now)
* Sorting and search fields can now be set up in Config

1.10 Release
------------
* Significant resource reduction (turn off Qt image cache)
* More responsive track view for playing now and searches
* Last search is remembered
* New sizing options (consistent between Plasma panels and Latte)
* Cosmetics clean up for HiDPI in adv panel view
* Fix regressions to the track splash being out-of-sync
* Other fixes and cleanups

1.9 Release
------------
* Better video playback support (fullscreen option)
* Search results shuffle option
* Tooltip for next track in playlist
* Tooltip for track detail
* Startup performance improvement
* Numerous fixes and clean up

1.8 Release
------------
* Optional high/low quality thumbnails
* More optimizations for thumbs and playback status
* Shuffle is available from track detail view
* Track detail view is more responsive
* Cosmetic refinement for playlist view and attribute (artist, album, etc.) searching

1.7 Release
------------
* Fix some playback settings regressions (repeat mode, zone link)
* Better support for video tracks
* Attribute search (artist, genre, etc.) can now search all media types or audio only
* See track details for playlist and attribute searches
* Play a playlist directly from Track Detail View
* Minor cosmetic fixes to titles and formatting

1.60 Release
------------
* Lots of little fixes and polish
* Changes to the host setup options (you will have to re-add your hosts)
* Panel view fonts now scale properly

1.51 Release
------------
* Gui clean-ups
* Minor fixes

1.5 Release
------------
* Add optional track image as playback indicator in compact view
* Refactor track splasher to work with compact view
* Minor optimizations and clean-ups

1.4 Release
------------
* Added option for abbreviated track detail view (defaults on, turn off in options for original behavior)
* Added track duration (min:sec) to track detail view
* Fixed a panel view painting nit
* Advanced Panel view controls are now less aggressive with mouse hover

1.3 Release
------------
* Fix "undefined" playlists
* Add Track to current playing now from track detail view
* Add stop button option to panel view
* Minor cleanup

1.2 Release
------------
* Polish advanced tray view formatting/layout behavior
* Advanced tray view now auto-connects at start up (first host in the list)
* Initial startup/connect more resource-friendly

1.1 Release
------------
* New Feature:  Advanced tray view options
* Bug Fixes:  Various visual update fixes

1.0 Release
------------
* Usability
  * Use Plasma theme/fonts
  * Playlist search

* Track Search
  * Searching tracks is a bit more usable
  * now include track name with Artist Album and Genre
  * search results can be played/queued immediately
  * one character searching defaults to "starts with"
  * more than one character searching defaults to "contains"
