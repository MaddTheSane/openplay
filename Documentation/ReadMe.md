# OpenPlay ReadMe File


## CONTENTS
________

- Requirements
- What's New
- About OpenPlay
- Project Overview 
- Building OpenPlay
- Getting Started With OpenPlay
- Running the OpenPlay Test app
- Running the MiniPlay app
- Volunteers Needed
- Submitting OpenPlay Modifications



## Requirements

- CW Pro 6.0 or later (MacOS, Windows), VC++ on Windows
- For Mac OS, system 8.6 and CarbonLib 1.3.1 or later is required
- For Mac OS X, Xcode will be needed.

## What's New

- NetSprocket has been merged into OpenPlay.  All functionality remains the same, but now through only one lib(OpenPlay) instead of two.
- Various file organization and cleanup.
- VC projects now exist.

## About OpenPlay/NetSprocket

OpenPlay is an Open Source cross-platform networking API, currently running on Windows and MacOS, with a Posix port quasi-completed. NetSprocket, now part of the OpenPlay library, is a higher-level API that runs on top of OpenPlay, with features such as player and group management. For additional background and information, visit <http://www.darwin.org/projects>.

To join the OpenPlay Development mailing list, visit <http://www.lists.apple.com> and search for "OpenPlay".

## Project Overview

The OpenPlay distribution contains the following core items:

| Directory | Description |
| ------------- | ----------- |
| Documentation	| All core documentation. |
| Project_Files	| All project files. (Metrowerks Codewarrior, VC++ soon) |
| Source		| All source code for the OpenPlay distribution: |

## Building OpenPlay

All project files are found in the Project_Files folder. At the moment, Metrowerks Codewarrior Pro6/Pro7 files and VC project files are being maintained.  Remenants of the Posix build are scattered about, but have not been tended to in a while(Anyone wishing to help us support them or other IDE/version project files are strongly encouraged to step forward.)

For those who wish a "quick and easy" approach to building OpenPlay components, the MasterBuild.mcp codewarrior project file has been added to the release. This file includes all other project files as sub-projects, and can be used to build a complete release with a single click of a button. Choose the target "All" to build debug and release builds for all platforms, or pick a more specialized target.

For the times you need more control over your builds, you can access the sub-projects directly. Note that some projects are dependent on others. (Demo projects require openplay stub libs to have been compiled, etc)

All projects should load and build without complaint (minus a few "errno" linker warnings at compile time.)

After building the projects listed above, the libs and sample applications will be placed in the Targets folder, under the appropriate Release or Debug target folder, based on platform type and IDE version. For example:

"Targets/CWPro7/mac_carbon/release/"

will be a complete, self-contained release folder you can copy to another machine and run as is. 


## Getting Started With OpenPlay

There are currently a few sample applications available to help you understand the workings of OpenPlay/NetSprocket:

* OPExample1 is the best place to start. This example is a complete mini-game for multiple players and demonstrates how to host and join games, as well as sending, receiving data and how to handle various chores related to networking with OpenPlay. This example has both a Protocol and NetSprocket networking example, and can server as a decent learning tool for the APIs as well as a good starting point for your own game. The networking code (nsp_network or op_network) was designed to be fairly easy to bring to another app, so although it is not 100% application independent it should be easy enough to figure out how to make it work in yours.

* OpenPlayTest is a small application that allows you to explore the basic features of OpenPlay, including setting up a client/server connection via the cross-platform GUI, enumerating through a list of available hosts, sending packets and streams between processes, and so forth. The code can be a bit daunting to newcomers, however. 

* OPMiniDemo is a stripped down "bare metal" example of the lowest elements of OpenPlay, using a crude text-based menu to drive a fixed single-connection client/server topology. Its severely limited functionality helps reveal the core workings of an OpenPlay application, however. MiniPlay is meant to be learning tool, not a foundation on which to build your application.

* OPEnumTest is a simple app focusing  on OpenPlay's enumeration routines -functions for creating a list of games currently on the network and joining based on that.

* NSpTestApp is a small application that allows you to explore and test the NetSprocket component of OpenPlay.  You can do pretty much anything in the API here via lists of commands, so it's a good way to orient yourself with the workings of NSp.  In the Documentation folder, you'll find a step by step list of commands to run to ensure NetSprocket is working properly.

* NSpMiniApp is an application encompassing a small, easy to use subset of NSpTestApp. It covers basic functionality such as hosting, joining, and handling messages. If *NSpTestApp* appears a bit daunting at first, start here.


## Running the Example 1 app

The example is very easy to follow, so you can just run it and follow along. Do note that the NetSprocket and Protocol examples do not talk to each other!


## Running the OpenPlay Test app

Be sure you have the OpenPlay Test app, OpenPlayLib and OpenPlay Modules folder together, and that at least one protocol module (TCP_IP, AppleTalk, etc.) is in the OpenPlay Modules folder. If your builds have executed properly, such a populated folder should already exist in your OpenPlay/Build hierarchy (see "Building OpenPlay" above).

Start up OpenPlay Test on two machines. First set up one as the server ("passive") process:

- Select "Open Passive UI" from the pulldown menu.
- Select an appropriate protocol module from the dialog   presented (a module must be present in the "OpenPlay Modules" folder co-located with the app in order to  be listed).
- Select "Use This" in the next dialog to start the server. After a brief pause, a new window will appear containing information on your new server process.
- Select "Accepting Connections" from the other pulldown menu.

The server is now ready. Next, create a client ("active") process on the other machine:

- Select "Open Active UI" from the pulldown menu.
- Select an appropriate protocol module, as above.
- Select a server from the list presented, and click "Join  Selected". (NOTE: If using TCP/IP and the server does not appear, try entering the server's IP address directly.) After a brief pause, a new window should appear containing  information on your new client process, and the server window will clear itself to prepare for traffic.

The client and server are now connected. You can select "Send Packet" and "Send Stream" to pass data between the two processes.


## Running the MiniPlay app

MiniPlay is so basic and limited that it is largely self-documenting. See the notes at the beginning of "MiniPlay.c" for further details.


## Running the OPEnumTest app

OPEnumTest is also rather basic and self-explanatory.


## Running the NSpTest app

See the test procedure currently found in the Testing.rtf file in the Documentation folder for step-by-step instructions on running this app.


## Running the MiniNSp app

MiniNSp is also so basic and limited that it is largely self-documenting.


## Volunteers Needed

- Unix/linux builds
- Sample code (Ongoing)
- Documentation Maintenance (Ongoing)
	- HeaderDoc Comments in Source
	- OP/NSp Programmer's Guide & Reference
	- Content maintenance
	- Formatting (fonts, etc.)
- Test Teams (Ongoing)
	- MacOS (Classic 8/9 and Carbon 8/9/X)
	- Windows 95/98, and NT/2k
	- Posix (Unix, linux, MacOS X, etc)


## Submitting OpenPlay Modifications

These guidelines are meant to be as "lightweight" as possible. Don't want to weigh anyone down with MILSPEC-level requirements, but we do need some basic information to maintain sanity.


Format For Submitting OpenPlay Updates:

A single file (when possible), containing the modifications. For each mod, include:

1. Filename and OpenPlay directory/folder path of where the mod  was applied.
2. Full source of the modified function (or surrounding header  area).
3. Each mod clearly marked by initials or some other comment "tag" (please indicate what you used).
4. Extra comments next to the mod, describing reasoning/motives. Doesn't have to be a thesis, but enough to give the reviewer an idea of why you made the change.

In some cases the changes will be extensive enough to require a different approach, but we can work with those on a case by case basis. For all other submissions, the format above will help speed the process along.

If for some reason you feel the guidelines are too burdensome, please let me know and we can work something out.

All feedback and contributions are greatly appreciated. Thanks for your continued support!


Enjoy!

- Lane Roathe, lane@ideasfromthedeep.com OpenPlay Tech Lead
