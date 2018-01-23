mcwsplasmoid
============

Plasmoid with basic search and playback control for [JRiver MediaCenter](http://jriver.com) Servers using MCWS

Screenshots
--------------
![](screenshots/confighost.png)

![](screenshots/configapp.png)

![](screenshots/zones.png)

![](screenshots/playlist.png)

![](screenshots/lookups.png)

![](screenshots/playlists.png)

MediaCenter Remote Control
--------------
* Multi-host/Multi-zone playback control
* Host address only, access-key support and https support tbd
* Zone link
* Basic smartlist/playlist searching/playback support
* Basic current playing now control
* Show playback controls and current playing track directly in a Plasma5 Panel or Desktop

Installation
--------------
*  Requires Qt5.7+, Plasma 5.8+

Installing from .plasmoid file:

    plasmapkg2 -i mcwsplasmoid.plasmoid

To upgrade, `plasmapkg2 -u mcwsplasmoid.plasmoid`

Installing from sources:

    git clone https://github.com/noee/mcwsplasmoid
    cd mcwsplasmoid
    plasmapkg2 -i ./plasmoid

To upgrade,  `plasmapkg2 -u ./plasmoid`

Setup
--------------
*  Add the MCWS Widget to a Panel or the Desktop (works best with horizontal panels)
*  Goto Mcws Remote Options (right-click the icon)
*  Under Connections, enter the host names (or addresses) where your MC Servers reside
*  Click on a host to test the connection
*  Use the "Appearances" tab to change the plasmoid view options
*  Hit "OK", you're done!

Development
--------------
A .qbs project file is provided and can be used with QtCreator.  Just modify the
project run options to use plasmoidviewer or qmlscene.

The plasmoid uses the Plasma5 theme and has been tested with Plasma5 default themes.
