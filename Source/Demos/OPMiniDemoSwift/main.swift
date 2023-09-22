//
//  main.swift
//  MiniPlaySwift
//
//  Created by C.W. Betts on 9/21/23.
//

import Foundation
import OpenPlay
import Darwin.C.stdio
import Darwin.POSIX.unistd

var  event =  NMEvent()
var  gotEvent: NMBoolean = 0

print("Server or Client Mode? (s/c) --> ", terminator: "")
fflush(stdout);

var mode = getchar();

if mode == 0x73 || mode == 0x53 {
	gInServerMode = true
	print( "\nSERVER MODE ACTIVE." )
	fflush(stdout)
}

while !gDone {
	   
	if !gInServerMode {
		doClientMenu()
	} else if gLocalEndpoint == nil {
		doServerMenu()
	}
}

print("Closing connection, exiting...\n" )
fflush(stdout);

closeConnection();

if gInServerMode {
	printPackets()
}

print("\nDone!")
fflush(stdout)

exit(EXIT_SUCCESS)
