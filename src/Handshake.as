// Copyright 2013 M-Lab
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package  {
	import flash.net.Socket;
	import flash.events.ProgressEvent;
	
	public class Handshake {
		
		/*
		
			This class handles the initial communication with
			the server before the tests. It has an event handler
			that call functions to handle the different stages of 
			communication with the server.
			
		*/
		
		// constants used within the class
		
		private const KICK_CLIENTS:int 	 = 0;
		private const SRV_QUEUE:int    	 = 1;
		private const VERIFY_VERSION:int = 2;
		private const VERIFY_SUITE:int	 = 3;
		
		// variables declaration section
		
		private var ctlSocket:Socket;
		private var protocolObj:Protocol;
		private var msg:Message;
		private var _yTests:int;
		private var callerObj:MainFrame;
		
		private var comStage:int;	// variable representing the stage of communication
									// with the server.
		
		var i:int, wait:int;
		var iServerWaitFlag:int; // flag indicating whether wait message
										 // was already received once
										 
		// event handler functions
		
		public function onResponse(e:ProgressEvent):void {
			
			switch(comStage) {
				case KICK_CLIENTS 	: kickOldClients();
									  break;
				case SRV_QUEUE	  	: srvQueue();
									  break;
				case VERIFY_VERSION : verifyVersion();
									  break;
				case VERIFY_SUITE	: verifySuite();
									  break;
			}
			
			if(TestResults._bFailed) {
				removeResponseListener();
				callerObj.finishedAll();
			}
		}
		
		private function addResponseListener():void {
			ctlSocket.addEventListener(ProgressEvent.SOCKET_DATA, onResponse);
		}
		
		private function removeResponseListener():void {
			ctlSocket.removeEventListener(ProgressEvent.SOCKET_DATA, onResponse);
		}
		
		// response handler functions
		
		/*
		
			Function that reads and processes the message from the
			server to kick old and unsupported clients.
			
		*/
		
		public function kickOldClients():void {
			
			// read the message that kicks old clients
			if(protocolObj.readn(msg, 13) != 13) {
				trace(DispMsgs.unsupportedClient);
				TestResults.errMsg += DispMsgs.unsupportedClient + "\n";
				TestResults._bFailed = true;
				return;
			}
			
			comStage = SRV_QUEUE;
			
			if(ctlSocket.bytesAvailable > 0) {
				srvQueue();
			}
			
		}
		
		/*
		
			Function that handles the queue responses from the server.
			The onResponse function will continue to loop here until 
			comStage is changed to indicate that the waiting period is
			over.
			
		*/
		
		public function srvQueue():void {
			// will loop wait here from onResonse until comStage value is changed
			
			// If SRV_QUEUE message sent by the server does not indicate
			// that the test session starts now, return
			if(protocolObj.recv_msg(msg) != NDTConstants.SRV_QUEUE_TEST_STARTS_NOW) {
				TestResults.errMsg += DispMsgs.protocolError
									  + parseInt(new String(msg.getBody()), 16)
									  + " instead\n";
				TestResults._bFailed = true;
				return;
			}
			
			// If message is not of SRV_QUEUE type, it is incorrect at this stage.
			if(msg.getType() != MessageType.SRV_QUEUE) {
				TestResults.errMsg += DispMsgs.loggingWrongMessage + "\n";
				TestResults._bFailed = true;
				return;
			}
			
			// Handling different queued-client cases below
		
			// Get wait flag value
			var tmpstr:String = new String(msg.getBody());
			wait = parseInt(tmpstr);
			trace("Wait flag received = " + String(wait));
			TestResults.traceOutput += "Wait flag received = " + String(wait) + "\n";
				
			if(wait == 0) {
				// SRV_QUEUE message indicates tests should start,
				// so proceed to next stage.
				trace("Finished waiting");
				TestResults.traceOutput += "Finished waiting" + "\n";
				
				comStage = VERIFY_VERSION;
				
				if(ctlSocket.bytesAvailable > 0) {
					verifyVersion();
					return;
				}
				
				return;
			}
				
			if(wait == NDTConstants.SRV_QUEUE_SERVER_BUSY) {
				if(iServerWaitFlag == 0) {								// Message indicating server is busy,
					TestResults.errMsg += DispMsgs.serverBusy + "\n";	// return
					TestResults._bFailed = true;
					return;
				}
				else {
					TestResults.errMsg += DispMsgs.serverFault + "\n";	// Server fault, return
					TestResults._bFailed = true;
					return;
				}
			}
				
			// server busy for 60s, wait for previous test to finish
			if(wait == NDTConstants.SRV_QUEUE_SERVER_BUSY_60s) {
				TestResults.errMsg += DispMsgs.serverBusy60s + "\n";
				TestResults._bFailed = true;
				return;
			}
				
			// server sends signal to see if client is still alive
			// client should respond with a MSG_WAITING message
			if(wait == NDTConstants.SRV_QUEUE_HEARTBEAT) {
				protocolObj.send_msg(MessageType.MSG_WAITING, _yTests);
				return;
			}
				
			// Each test should take less than 30s, so tell them 45 sec * number of
			// test suites waiting in the queue. Server sends a number equal to number
			// of queued clients == number of minutes to wait before starting tests.
			// wait = minutes to wait = number of queued clients.
			wait = (wait * 45);
			TestResults.consoleOutput += DispMsgs.otherClient + wait
										 + DispMsgs.seconds + ".\n";
			iServerWaitFlag = 1; // first message from server now already encountered
		}
		
		/*
		
			Function that verifies version compatibility between the server
			and the client.
			
		*/
		
		public function verifyVersion():void {
			
			// The server must send a message to verify version,
			// and this is a MSG_LOGIN type message.
			if(protocolObj.recv_msg(msg) != NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
				// there is a protocol error so return
				TestResults.errMsg += DispMsgs.protocolError +
									  parseInt(new String(msg.getBody()), 16) + 
									  " instead\n";
				TestResults._bFailed = true;
				return;
			}
			
			if(msg.getType() != MessageType.MSG_LOGIN) {
				// only this type of message should be received at this stage.
				// every other message is wrong.
				TestResults.errMsg += DispMsgs.versionWrongMessage + "\n";
				TestResults._bFailed = true;
				return;
			}
			
			// version compatibility between server and client must be verified.
			var vVersion:String = new String(msg.getBody());
			if(!(vVersion.indexOf("v") == 0)) {
				TestResults.errMsg += DispMsgs.incompatibleVersion + "\n";
				TestResults._bFailed = true;
				return;
			}
			trace("Server version : " + vVersion.substring(1));
			TestResults.traceOutput += "Server Version : " + vVersion.substring(1) + "\n";
			
			comStage = VERIFY_SUITE;
			
			if(ctlSocket.bytesAvailable > 0) {
				verifySuite();
			}
		}
		
		/*
		
			Function that verifies that the suite previously requested
			by the client is the same as the one the server has sent.
			If successfully completed, the function calls allComplete
			that initiates the tests requested in the test suite.
			
		*/
		
		public function verifySuite():void {
			
			// Read server message again. Server must send a MSG_LOGIN message to negotiate
			// the test suite and this should be the same set of tests requested by the client
			// earlier.
			if(protocolObj.recv_msg(msg) != NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
				TestResults.errMsg += DispMsgs.protocolError +
									  parseInt(new String(msg.getBody()), 16) + 
									  " instead\n";
				TestResults._bFailed = true;
				return;
			}
			if(msg.getType() != MessageType.MSG_LOGIN) {
				// only tests negotiation message expected at this point.
				// any other type is wrong.
				TestResults.errMsg += DispMsgs.testsuiteWrongMessage + "\n";
				TestResults._bFailed = true;
				return;
			}
			allComplete();
		}
		
		/*
		
			Function that removes the local event handler for 
			the Control Socket responses and passes control back
			to the caller object.
			
		*/
		
		public function allComplete():void {
			removeResponseListener();
			callerObj.initiateTests(protocolObj, msg);
		}
		
		/*
		
			Constructor for the class. Initializes local variables to the ones
			obtained from MainFrame. Starts the handshake process by sending a
			MSG_LOGIN type of message.
			
			@param socket
						The socket object used for communication
			
			@param proOb
						The Protocol object of ctlSocket
			
			@param messg
						A Message object used to receive messages
			
			@param testPack
						The integer represting the tests requested
			
			@param callerObject
						Used to call functions of the caller object
		*/

		public function Handshake(socket:Socket, proOb:Protocol, messg:Message, testPack:int, callerObject:MainFrame) {
			// constructor code
			
			ctlSocket = socket;
			protocolObj = proOb;
			msg = messg;
			_yTests =  testPack;
			callerObj = callerObject;
			
			iServerWaitFlag = 0;
			comStage = KICK_CLIENTS;
			TestResults._bFailed = false;
			
			addResponseListener();
			
			// The beginning of the protocol
			
			// write out test suite request by sending a login message
			// _yTests indicates the requested test-suite
			protocolObj.send_msg(MessageType.MSG_LOGIN, _yTests);			
		}

	}
	
}
