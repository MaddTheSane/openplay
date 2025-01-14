# Outstanding Issues
This file serves as an updated list of what areas are not yet working correctly as of this release.  Use this to steer clear of danger zones or to "choose your enemy" for bug-fixing. Please report any issues not mentioned here to the OpenPlay mailing list
 and to:

	Eric Froemling <froemling@ricore.idevgames.com>
	Lane Roathe <lane@ideasfromthedeep.com>

## General & Test/Example Apps

- [ ] OPExample1 seems to have one or more elusive bugs in the interrupt-time code that can cause crashes. Argh. (only in the Protocol example, the NetSprocket example is fine.)
- [ ] OPExample1 does not get input on Windows or linux builds; if someone knows how to scan for a keypress when not using a GUI please forward this to us!
- [ ] The Project-Builder targets aren't made in the Targets directory like all the others. Trying to have them put there seems to cause an error during building.
- [ ] Active enumeration is not functional in the windows OpenPlayTest, as its list functions are incomplete. Turning it on via the menu and then opening a dialog triggers a halt. (note that enumeration in general works fine on windows)
- [ ] In the Mac OS X mach-o builds, none of the libraries are able to load their resources. This prevents dialogs from functioning correctly. We need to know how to determine the position of our mach-o libs at runtime. Also, we need to figure out what to do about dialog functionality in cocoa apps.
- [ ] A good, interrupt-safe debug-message(DEBUG_PRINT,etc) displaying functionality for the Classic MacOS builds would be nice. The current choices are DebugStr(), which is a hindrance for large amounts of messages, and also routing messages to Sioux, which is most likely flirting with disaster, as many of our messages are at interrupt-time.


## Protocol API

- [ ] The OpenTransport Mac OS netmodules seem to announce "success" creating an endpoint before its actually  ready to send data in some cases (possibly just netsprocket-mode). NetSprocket currently has a small Delay() implemented (*NSpGameSlave.cpp* line *161*) as a workaround due to this issue. Also, in OPExample1's Protocol version, a datagram containing the player's name is sent immediately upon a successful endpoint creation, which often doesn't go through with the OT module. Datagrams are, of course, unreliable, but it seems like this might be related to the same issue.
- [ ] On the posix builds, modules are searched for using a directory specified by an environment variable, `"OPENPLAY_LIB"`. It would be good if they could be searched for relative to the openplay library like on other systems. Would be good to support packages on Mac OS X too, so modules can bring resources with them.
- [ ] Connection rejecting doesn't always work quite as expected. Sometimes getting rejected will result in succeess in making an endpoint, which will then be closed momentarily thereafter.  A "proper" rejection mechanism may prove impossible to implement correctly in some modules, so its generally a good idea to accept all connections and then send them an application-defined acceptance or rejection message.
- [ ] A rejected connection attempt using the Open Transport mac netmodules will return `kNMOpenFailedErr` instead of the proper kNMAcceptFailedErr.
- [ ] When opening the tcpip dialog in OpenPlayTest on MacOS-9, the address field is blank, but actually contains "localhost", which annoyingly shows up when the user starts typing something else.
- [ ] Running 640x480, the tcpip dialog in OpenPlayTest is displayed off-center, partially off the right side of the screen.
- [ ] Enter or Return keys in Mac TCPIP Dialogs in OpenPlayTest inserts a carriage return.
- [ ] When using the Carbon IP module on Mac OS X, enumeration doesn't seem to locate games on the local machine.
- [ ] Non-orderly disconnects aren't implemented anywhere it seems, and are not well described in the documentation
- [ ] Appletalk module enumeration locates new games fine, but when a game is no longer available, it is not removed from the list.

## NetSprocket API

- [ ] NSpGame_GetInfo run from a client returns an empty game name, and other fields are also not filled in.
- [ ] See _Testing.rtf_ for other issues related to NetSprocket's use of **OpenPlay** and **NetSprocket** under Windows.
- [ ] hosting NSpTest on linux doesnt work for me.  This might be a firewall issue though.
