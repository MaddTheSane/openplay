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
		Do_Client_Menu()
	} else if gLocalEndpoint == nil {
		Do_Server_Menu()
	}
}

print("Closing connection, exiting...\n" )
fflush(stdout);

Close_Connection();

if gInServerMode {
	Print_Packets()
}

print("\nDone!")
fflush(stdout)

exit(EXIT_SUCCESS)
