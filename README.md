# mcwsplasmoid
Plasmoid with basic playback support for JRiver MediaCenter Servers using MCWS

Screenshots
===========

![](screenshots/zones.png)

![](screenshots/playlist.png)

![](screenshots/playlists.png)

Player Management
====================
* Multi-host/Multi-zone playback control (audio only)
* Host address only, access-key support and https support tbd
* Zone link
* Basic smartlist/playlist playback support (to be updated)
* Basic current playing now management

Installation
============

Installing from .plasmoid file:
````Shell
plasmapkg2 -i mcwsplasmoid.plasmoid
````
For upgrade, run `plasmapkg2 -u mcwsplasmoid.plasmoid` instead.

Installing from sources:
````Shell
git clone https://github.com/noee/mcwsplasmoid
cd mcwsplasmoid
plasmapkg2 -i ./plasmoid
````
For upgrade, run `plasmapkg2 -u ./plasmoid` instead.

Development
===========

A .qbs project file is provided and can be used with QtCreator.  Just modify the
project run options to use plasmoidviewer or qmlscene.

The plasmoid uses the built-in Plasma5 icons and has been tested with Oxygen and Breeze themes.
