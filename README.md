﻿MCWS Remote Plasmoid
============

Plasmoid with basic search and playback control for [JRiver MediaCenter](http://jriver.com) Servers using MCWS

MediaCenter Remote Control
--------------
* Multi-host/Multi-zone playback control
* Zone link
* Smartlist/playlist searching/playback support
* Control playback on all zones for a MCWS server with just a few clicks
* Show playback controls and current playing track directly in a Plasma panel,
a Latte Dock panel or on the Desktop

Screenshots
--------------
![](screenshots/confighost.png)

![](screenshots/configapp.png)

![](screenshots/zones.png)

![](screenshots/playlist.png)

![](screenshots/lookups.png)

![](screenshots/playlists.png)


Installation
--------------
*  Requires Qt5.11+, Plasma 5.10+

*  Installing from .plasmoid file:
    * `plasmapkg2 -i mcwsplasmoid.plasmoid`

*  Upgrade
    * `plasmapkg2 -u mcwsplasmoid.plasmoid`

*  Installing from source:
    * `git clone https://github.com/noee/mcwsplasmoid`
    * `cd mcwsplasmoid`
    * `plasmapkg2 -i ./plasmoid`

Setup
--------------
*  Add the MCWS Widget to a Panel or the Desktop (works best with horizontal panels)
*  Goto Mcws Remote Options (right-click the icon)
*  Under Connections, enter the host names (or addresses) where your MC Servers reside
*  Click on a host to test the connection
*  Use the "Appearances" tab to change the plasmoid view options
*  Use the "Playback" tab to change MCWS playback options
*  Use the "Search Fields" tab to set MCWS fields sortable or searchable
*  Hit "OK", you're done!

Web Stream Setup
--------------
Currently MediaCenter does not support the web interface to streaming sources, but
it will still play them if set up manually.  When a web streaming source is setup,
MediaCenter will add it to the Web Media Playlist so it's available from the Playlists
page and normal audio searching.

There are some diffences to how MediaCenter handles reporting playback information:

*  SomaFM: Enter 'soma' into the tag 'Web Media Info' for the track once the source is set up

Development
--------------
A .qbs project file is provided and can be used with QtCreator.  Just modify the
project run options to use plasmoidviewer or qmlscene.

The plasmoid has been tested with Plasma5 default themes.
