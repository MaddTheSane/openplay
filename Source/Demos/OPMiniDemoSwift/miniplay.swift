//
//  miniplay.swift
//  MiniPlaySwift
//
//  Created by C.W. Betts on 9/21/23.
//

import Foundation
import OpenPlay
import Darwin.C.stdio
import Darwin.POSIX.unistd

/// Max packets to receive & store.
let  kMaxPackets = 256

// KLUDGE:  Tags stolen from NetModuleIP.h,
// module_config.c, etc. -  See comments in
// Open_Connection() below. Tags used to
// manually build config string when necessary.
private let kIPConfigAddressTag = "IPaddr"
private let kIPConfigPortTag = "IPport"
private let kTypeTag = "type"
private let kVersionTag = "version"
private let kGameIDTag = "gameID"
private let kGameNameTag = "gameName"
private let kModeTag = "mode"

let kLoopBackAddress = "127.0.0.1"

let kGameID: NMType = 0x4D4F4F46
//let kAppleTalk_ProtoTag: NMUInt32 = 0x41746c6b
//let kTCP_ProtoTag: NMUInt32 = 0x496e6574

enum ProtocolType {
	case appleTalk
	case TCP
}

enum EndpointType {
	case client
	case server
}

/// The sample structure that will be sent.
 struct PlayerPacket {
	 /// Stuffed with a generic number.
	 var data: NMUInt32 = 0
	 /// Serialized ID, helps track packets.
	 var id: NMUInt32 = 0

};

// MARK: - Globals -

// Sure, global variables are usually a source
// of evil, but they make this sample app easier
// to follow.

internal var gLocalEndpoint: PEndpointRef? = nil

internal var gPacketCount: Int32 = 0
internal var gPackets = [PlayerPacket](repeating: PlayerPacket(), count: kMaxPackets)

internal var gDone: Bool = false
internal var gInServerMode: Bool = false
internal var gClientConnected: Bool = false

private var gEnumHostID: NMUInt32 = 0
private var gEnumHostName: String = ""


// MARK: - Begin Code -

/// 'Nuff said.
/// @param err Error value to check
private func IsError(_ err: NMErr ) -> Bool {
	// OpenPlay returns negative numbers for all errors.
	
	return (err < 0) ? true : false
}



/// Cheesy little console menu to get user input. Hey,
/// at least it's cross-platform. ;-)
internal func doClientMenu() {
	
	print( "\nSelect:\n" );
	print( "\t1 - Open AppleTalk Connection to Server" );
	print( "\t2 - Open TCP/IP Connection to Server" );
	print( "\t3 - Send Packet" );
	print( "\t4 - Shutdown App (will trigger server to print results...)\n" );

	print( "--> ", terminator: "" )
	fflush(stdout)
	
	var selection: Int32 = 0
	repeat {
		selection = getchar()
	} while selection < 0x31 /* '1' */ || selection > 0x34 /* '4' */
	
	switch selection {
		
	case 0x31 /* '1' */:
		print( "Starting AppleTalk client..." )
		fflush(stdout)
		_=openConnection(endpoint: .client, protocol: .appleTalk, host: nil)

	case 0x32 /* '2' */:
		print( "\nEnter IP Address of host (ex. 254.171.0.2): " );
		fflush(stdout)
		var cHostIPStr = [CChar](repeating: 0, count: Int(BUFSIZ))
		_=cHostIPStr.withUnsafeMutableBufferPointer { umrbp in
			withVaList([umrbp.baseAddress!]) { aPtr in
				vscanf("%s", aPtr)
			}
		}
		let hostIPStr = String(cString: cHostIPStr)
		
		print("\nStarting TCP/IP client, connecting to host \(hostIPStr)...")
		fflush(stdout)
		_=openConnection( endpoint: .client, protocol: .TCP, host: hostIPStr)
		
	case 0x33 /* '3' */:
		print("Sending packet...")
		fflush(stdout)
		sendPacket()

	case 0x34 /* '4' */:
		gDone = true

	default:
		print("Selection out of range, blame society!")
		fflush(stdout)
	}
}

/// Cheesy little console menu to get user input. Hey,
/// at least it's cross-platform. ;-)
func doServerMenu() {
	var success = true
	var selection: Int32 = 0

	print( "\nSelect:\n" );
	print( "\t1 - Open Appletalk Server" );
	print( "\t2 - Open TCP/IP Server" );
	print( "\t3 - Abort\n" );

	print( "--> ", terminator: "" )
	fflush(stdout);

	repeat {
		selection = getchar()
	} while selection < 0x30 /* '0' */ || selection > 0x7A /* 'z' */

	switch selection {
	case 0x31 /* '1' */:
		print("Starting Appletalk server...")
		fflush(stdout);
		success = openConnection(endpoint: .server, protocol: .appleTalk, host: nil)

	case 0x32 /* '2' */:
		print("Starting TCP/IP server...")
		fflush(stdout);
		success = openConnection(endpoint: .server, protocol: .TCP, host: kLoopBackAddress)

	case 0x33 /* '3' */, 0x71 /* 'q' */:
		gDone = true
		
	default:
		print("Selection out of range, blame society!")
		fflush(stdout)
	}
	
	if ( success ) {
		print("Waiting for client to connect... \n")
		fflush(stdout)
	} else {
		gDone = true
	}
}

/// Searches for the desired protocol module.
///
/// Verify the returned `Bool` for success, or risk
/// passing trash into `ProtocolCreateConfig()` when you return
/// to `Open_Connection()`
/// @param type Protocol selected
private func getProtocol(type: inout NMType, target protocolTarget: ProtocolType) -> Bool {
	var err: NMErr = 0
	var protocolFound = false
	var status = false
	var theProtocol = NMProtocol()
	var index: NMSInt16 = 0
	
	theProtocol.version = CURRENT_OPENPLAY_VERSION
	
	while !IsError(err) && !protocolFound {
		// OpenPlay API
		err = GetIndexedProtocol(index, &theProtocol)
		index += 1
		
		if !IsError(err) {
			if (protocolTarget == .appleTalk &&
				theProtocol.type == kAppleTalk_ProtoTag) {
				protocolFound = true
			} else if (protocolTarget == .TCP &&
					   theProtocol.type == kTCP_ProtoTag) {
				protocolFound = true
			}
		}
	}
	
	if !IsError( err ) {

		type = theProtocol.type  // Copy by value, it's safe.
		status = true
	} else {
		print("ERROR: \(err) from GetIndexedProtocol()...")
		fflush(stdout)
	}

	return status
}

/// Sends a packet down the endpoint.
///
/// In MiniPlay, only the client will call `sendPacket()`.
func sendPacket() {
	var  err: NMErr = 0
	var  packetID: NMUInt32 = 0;
	struct InternalPacket {
		static var packet = PlayerPacket()
	}
	
	// Don't try to send data down a NULL endpoint....
	
	if let gLocalEndpoint {
		
		// Stuff some data into the packet.
		InternalPacket.packet.id = packetID // Helps tell packets apart when printed.
		packetID += 1
		InternalPacket.packet.data = 42	    // Because 42 is The Answer....
		
		
		//perform byteswapping on little-endian systems(x86, etc) to put our data in network(big-endian) order
#if _endian(little)
		//		DEBUG_PRINT("we have as 0x%x",packet.id);
		InternalPacket.packet.id = InternalPacket.packet.id.bigEndian
		InternalPacket.packet.data = InternalPacket.packet.data.bigEndian
		//		DEBUG_PRINT("going out as 0x%x",packet.id);
#endif
		// OpenPlay API
		err = ProtocolSendPacket(gLocalEndpoint,
								 &InternalPacket.packet,
								 NMUInt32(MemoryLayout<PlayerPacket>.stride),
								 0)
		
		if IsError(err) {
			print("ERROR: \(err) on ProtocolSendPacket!")
			fflush(stdout)
		}
	} else {
		print("No connection to server yet!")
		fflush(stdout)
	}
}

/// Attempts to open endpoint using config data.
///
/// According to the OpenPlay Programmer's Dox, the 'flag'
/// parameter to `ProtocolOpenEndpoint()` is unused, but from
/// looking at the OpenPlay source and running this app with
/// different flags (well, either `kOpenActive` or `kOpenNone`) it
/// seems `ProtocolOpenEndpoint()` **does use the flags.**
private func Create_Endpoint(config: PConfigRef?, active: Bool) -> PEndpointRef? {
	var flags: NMOpenFlags = []
	guard let config else {
		print("ERROR: NULL PConfigRef parameter in Create_Endpoint()!")
		fflush(stdout)
		return nil
	}
	
	if active {
		flags.formUnion(.openActive)
	} 
	
	
	print("\t\tAttempting to open endpoint...")
	fflush(stdout)

	var newEndpoint: PEndpointRef? = nil
	
	// OpenPlay API
	let err = ProtocolOpenEndpoint(config,
								OpenPlayCallback,
								nil,
								&newEndpoint,
								flags)

	if IsError(err) {
		newEndpoint = nil
		print( "\tERROR: \(err) opening endpoint. (Verify a server is running ")
		print( "\t       and that your network connection is active.) " )
		fflush(stdout)
	}
	
	return newEndpoint
}

/// The callback routine that OpenPlay will call
/// (rather abruptly) when an OpenPlay event occurs.
///
/// Been wondering why all the hassle in OpenPlay Test was made
/// to create '`interrupt_safe_log`' routines? To keep you from
/// going down in flames. But to reduce the code to the barest
/// of essentials, I flirt with disaster using `print()`'s. As
/// long as they don't show up in the `kNMDatagramData` case,
/// all seems to flow smoothly.
private func OpenPlayCallback(endpoint inEndpoint: PEndpointRef?,
							  context inContext: UnsafeMutableRawPointer?,
							  code inCode: NMCallbackCode,
							  error inError: NMErr,
							  cookie inCookie: UnsafeMutableRawPointer?) {
	guard !gDone else {
		return
	}
	
	switch inCode {
	case .connectRequest:
		//printf( "Got a connection request!\n" );
		acceptConnection(endpoint: inEndpoint, cookie: inCookie)
		break

	case .datagramData:
		// According to the OpenPlay Programmer's Dox entry for
		// ProtocolReceivePacket(), when kNMDatagramData is received
		// you should keep calling ProtocolReceivePacket() until a
		// kNMNoDataErr is returned. Of course I quit the loop as
		// soon as ANY error is received, but the point holds. Seems
		// we need to drain the buffer of any backed-up packets.
						   
		var  packet = PlayerPacket()
		var  data_length: UInt32 = UInt32(MemoryLayout<PlayerPacket>.size)
		var flags: NMFlags = 0

		// OpenPlay API
		var err = ProtocolReceivePacket( inEndpoint, &packet, &data_length, &flags );
		
		while !IsError(err) && gPacketCount < kMaxPackets - 1 {

			//perform byteswapping on little-endian systems(x86, etc) to get our data out of network(big-endian) order
#if _endian(little)
			packet.id = packet.id.bigEndian;
			packet.data = packet.data.bigEndian;
#endif

			gPackets[ Int(gPacketCount) ].id = packet.id;
			gPackets[ Int(gPacketCount) ].data = packet.data;
			gPacketCount += 1
			
			print( "We got a new package.");
			fflush(stdout);

			// Evil - since ProtocolReceivePacket() uses my 'data_length'
			// parameter for both input *and* output, need to be sure and
			// reset it each time through. Just in case.
			   
			data_length = UInt32(MemoryLayout<PlayerPacket>.size)

			// OpenPlay API
			err = ProtocolReceivePacket(inEndpoint, &packet, &data_length, &flags)
		}

		break
		
	case .streamData:
		// printf( "Got kNMStreamData message (no action taken).\n" );
		break

	case .flowClear:
		// printf( "Got kNMFlowClear message (no action taken).\n" );
		break

	case .acceptComplete:
		print("Accept complete!")
		// printf( "(Idling, collecting packets until client disconnects...)\n" );
		fflush(stdout)
		gClientConnected = true

	case .handoffComplete:
		print( "Handoff complete!" )
		print( String(format: "Got kHandoffComplete: Cookie: 0x%lx\n", uintptr_t(bitPattern: inCookie)))
		fflush(stdout)

	case .endpointDied:
		//printf( "Endpoint died, closing...\n" );
		gDone = true

	case .closeComplete:
		//printf( "Endpoint successfully closed.\n" );
		gDone = true

	case .updateResponse:
		break
		
	case .nextFreeCallbackCode:
		break
		
	@unknown default:
		//printf( "Got unknown inCode in the callback.\n" );
		break
	}
}

/// Tries to create a config reference.
/// @param endpointType Whether to open active or passive.
/// @param protocolType Protocol desired.
/// @param nmProtocol OpenPlay protocol tag.
/// @param hostIPStr IP address, in case we're using TCP.
/// @param configHandle Pointer to config ref we'll build.
private func createConfig(_ endpointType: EndpointType,
						  _ protocolType: ProtocolType,
						  _ nmProtocol: NMType,
						  _ hostIPStr: String?,
						  _ configHandle: UnsafeMutablePointer<PConfigRef?>) -> Bool {
	
	var result = false
	var err: NMErr = 0
	var configStr = ""

	if protocolType == .TCP {
		// If we're running as a TCP/IP process, we need to feed the target
		// host's IP address into ProtocolCreateConfig. Unfortunately that
		// means building the obtuse config string ourselves.... Note the
		// tab-delineated fields. We need to bring these OpenPlay config
		// string tags to a publicly-accessible level so the user can refer
		// to module-defined constant data types instead of having to
		// hardcode it themselves.

		configStr = String(format: "%@=%d\t%@=%u\t%@=%d\t%@=%@\t%@=%u\t%@=%@\t%@=%u",
						   kTypeTag, nmProtocol,
						   kVersionTag, 0x00000100,
						   kGameIDTag, kGameID,
						   kGameNameTag, "Clarus",
						   kModeTag, 3,
						   kIPConfigAddressTag, hostIPStr!,
						   kIPConfigPortTag, 25710)
	}
	
	var configCStr = configStr.utf8CString
	// OpenPlay API
	err = configCStr.withUnsafeMutableBufferPointer { umbp in
		ProtocolCreateConfig( nmProtocol,    // Which protocol to use (TCP/IP, Appletalk, etc.)
							  kGameID, // 'Key' to find same game type on network.
							  "Clarus",// 'Key' to a particular game of that type.
							  nil,
							  0,
							  umbp.baseAddress,
							  configHandle    // Retrieve your config info with this critter.
		)
	}
	
	if !IsError(err) {
		result = true
	
		print("\nCreated Config Ref.")
		fflush(stdout)
		var configStrLen: NMSInt16 = 0
		
		// OpenPlay API
		ProtocolGetConfigStringLen(configHandle.pointee, &configStrLen )
		var infoStr = [CChar](repeating: 0, count: Int(configStrLen) + 1)
		
		// OpenPlay API
		_=infoStr.withUnsafeMutableBufferPointer { umbp in
			ProtocolGetConfigString(configHandle.pointee, umbp.baseAddress, NMSInt16(umbp.count))
		}
		
		print("\nConfig Info:  \(String(cString: infoStr))")
		fflush(stdout)
	} else {
		print("ERROR: \(err) creating config.")
		fflush(stdout)
	}

	return result
}

/// Tries to open either an active or passive connection.
private func openConnection(endpoint endpointType: EndpointType, protocol protocolType: ProtocolType, host hostIPStr: String?) -> Bool {
	guard gLocalEndpoint == nil else {
		print("Connection already opened, Chumley!")
		fflush(stdout)

		return true
	}
	
	var type: NMType = 0
	var config: PConfigRef? = nil
	var activeConnection = false
	var state = false

	if endpointType == .client {
		activeConnection = true
	}

	// Grab target protocol.
	
	if getProtocol(type: &type, target: protocolType) {
//		printf( "\nProtocol selected: %c%c%c%c\n",
//						(char)((type>>24) & 0xFF),
//						(char)((type>>16) & 0xFF),
//						(char)((type>>8) & 0xFF),
//						(char)(type & 0xFF));
//		fflush(stdout);
		
		if createConfig(endpointType, protocolType, type, hostIPStr, &config) {
			if !gInServerMode && protocolType == .appleTalk {
				doEnumeration(with: config)
			}

			gLocalEndpoint = Create_Endpoint(config: config, active: activeConnection)

			if gLocalEndpoint != nil {
			
				state = true;  // Connection is good.
			
				print( "\nCreated endpoint from Config Ref. \(activeConnection ? "Active (client)" : "Passive (server)")"
							   );
				fflush(stdout);

				if !activeConnection {
					// Passive connection == Server connection for MiniPlay.
					gInServerMode = true
				}
			} else {
				print("ERROR: failed to create endpoint.")
				fflush(stdout);
			}
			
			// OpenPlay API
			let err = ProtocolDisposeConfig(config)
			
			if IsError(err) {
				// Not a fatal error, but need to report it.
				print( "ERROR: \(err) disposing the config.")
				fflush(stdout)
			}

		}
	} else {
		print("ERROR: Unable to find protocol module.")
		fflush(stdout)
	}
	
	return state
}

/// Attempt to complete a connection request.
private func acceptConnection(endpoint inEndpoint: PEndpointRef?, cookie inCookie: UnsafeMutableRawPointer?) {
	var err: NMErr = 0

	// Only accept a single client for this test app...
	if !gClientConnected {
		
		// OpenPlay API
		err = ProtocolAcceptConnection(inEndpoint,
									   inCookie,
									   OpenPlayCallback,
									   nil)
			
		if !IsError( err ) {
			print("Accepting connection...")
			fflush(stdout)
		} else {
			print("ERROR: \(err) Failed connection request!")
			fflush(stdout)
		}
	}
	
	// Else we already have our connection, tell the extra client
	// to go pound sand.
	
	else {
		print( "Connection refused - Server already connected!" )
		fflush(stdout)
		
		// OpenPlay API
		err = ProtocolRejectConnection( inEndpoint, inCookie );
		
		if IsError(err) {
			print("ERROR: \(err) in ProtocolRejectConnection()!\n")
			fflush(stdout)
		}
	}
}

/// Shuts down the endpoint.
func closeConnection() {
	let mPython = "The Comfy Chair!";  // Not actually used in this function.
	// But a mighty fine sketch....
	
	if gLocalEndpoint != nil {
		// Let OpenPlay clean up.
		// OpenPlay API
		let err = ProtocolCloseEndpoint(gLocalEndpoint, 0)
		
		if IsError(err) {
			print("ERROR: \(err) closing endpoint!")
			fflush(stdout)
		}
		
		gLocalEndpoint = nil
	}
}


private func enumerationCallback(inContext: UnsafeMutableRawPointer?,
								 inCommand: NMEnumerationCommand,
								 item: UnsafeMutablePointer<NMEnumerationItem>?) {
	if let item {
		gEnumHostName = String(cString: item.pointee.name)
		gEnumHostID = item.pointee.id
	}
}

private func doEnumeration(with config: PConfigRef?) {
	var err: NMErr = 0
	var c: Int32 = 0
	
	print("\n\nSCANNING FOR AVAILABLE HOSTS")
	fflush(stdout);
	
	ProtocolStartEnumeration(config,
							 enumerationCallback,
							 nil,
							 1)
	
	for _ in 0 ..< 5 {
		err = ProtocolIdleEnumeration(config)
		print( "." )
		fflush(stdout)
		sleep( 1 )
	}
	
	print("\n\tHost Found: \t HostID = \(gEnumHostID), Name = \(gEnumHostName) \n")
	fflush(stdout)
	
	print("Bind to Host \(gEnumHostName) / ID \(gEnumHostID)? (y/n):  ", terminator: "")
	fflush(stdout)
	
	while c != 0x79 /* 'y' */ && c != 0x59 /* 'Y' */ && c != 0x6E /* 'n' */ && c != 0x4E /* 'N' */ {
		c = getchar()
	}
	
	if c == 0x79 /* 'y' */ || c == 0x59 /* 'Y' */ {
		err = ProtocolBindEnumerationToConfig(config, gEnumHostID)
		
		if IsError(err) {
			print("ERROR: Could not bind enumeration item to config.")
			fflush(stdout)
		}
	}
	
	err = ProtocolEndEnumeration(config)
}

/// Prints out any packets that may have been collected
/// before the client disconnected.
internal func printPackets() {
	print("Packets received: \(gPacketCount)\n")
	fflush(stdout)
	
	for x in 0 ..< min(Int(gPacketCount), kMaxPackets) {
		let outStr = String(format: "\tPacket[ %d ]: ID=%u, data=%u", x, gPackets[x].id, gPackets[x].data)
		print(outStr)
		fflush(stdout)
	}
}
