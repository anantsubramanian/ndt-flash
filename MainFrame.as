package  {
	
	import flash.text.TextField;
	import flash.text.*;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.net.*;
	import flash.display.DisplayObjectContainer;
	import flash.events.IOErrorEvent;
	import flash.system.Security;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import com.greensock.*;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	
	/*  
		
		This program uses the free TweenLite plugin
		from GreenSock : http://www.greensock.com/tweenlite/
	
	*/
	
	public class MainFrame extends Sprite{
		
		/*
		
			Class responsible for establishing the socket
			connection and initiating communications with the
			server (NDTP-Control).
		
			Calls functions to perform the required tests
			and to interpret the results.
		
		*/
		
		// variables declaration section
		
		private var gui:GUI;
		
		private static var sHostName:String;
		private var pub_host:String;
		public var guiEnabled:Boolean;
		var ctlSocket:Socket = null;
		var tests:Array;
		var testNo:int;
		
		private var _yTests:int =  NDTConstants.TEST_S2C;
									//NDTConstants.TEST_MID | NDTConstants.TEST_C2S 
								//  | NDTConstants.TEST_S2C | NDTConstants.TEST_SFW
								//  | NDTConstants.TEST_STATUS | NDTConstants.TEST_META;
		
		// socket event listener functions
		
		public function onConnect(e:Event):void {
			trace("Socket connected.");
			TestResults.traceOutput += "Socket connected\n";
			protocolStart();
		}
		public function onClose(e:Event):void {
			// have to check what to do
		}
		public function onError(e:IOErrorEvent):void {
			trace("IOError : " + e);
			TestResults.errMsg += "IOError : " + e;
			TestResults._bFailed = true;
			finishedAll();
		}
		public function onSecError(e:SecurityErrorEvent):void {
			trace("Security Error" + e);
			TestResults.errMsg += "Security error : " + e;
			TestResults._bFailed = true;
			finishedAll();
		}
		public function onResponse(e:ProgressEvent):void {
			// nothing as of now
		}
		
		public function addEventListeners():void {
			ctlSocket.addEventListener(Event.CONNECT, onConnect);
			ctlSocket.addEventListener(Event.CLOSE, onClose);
			ctlSocket.addEventListener(IOErrorEvent.IO_ERROR, onError);
			ctlSocket.addEventListener(ProgressEvent.SOCKET_DATA, onResponse);
			ctlSocket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecError);
		}
		
		public function removeResponseListener():void {
			ctlSocket.removeEventListener(ProgressEvent.SOCKET_DATA, onResponse);
		}
		
		public function addResponseListener():void {
			ctlSocket.addEventListener(ProgressEvent.SOCKET_DATA, onResponse);
		}
		
		// protocol functions
		
		/*
		
			Function that creates the Control Socket object
			used to communicate with the server.
			
		*/
		
		public function dottcp():void {			
			pub_host = sHostName;
			
			// default control port used for the NDT tests session. NDT server
			// listens to this port
			var ctlport:int = NDTConstants.CONTROL_PORT_DEFAULT;
			
			Security.allowDomain("*"); // not sure if necessary
			
			TestResults._bFailed = false;  // test result status is false initially
			
			TestResults.consoleOutput += DispMsgs.connectingTo + " " + 
										 sHostName + " " + DispMsgs.toRunTest
										 + "\n";
			
			ctlSocket = new Socket();
			addEventListeners();
			ctlSocket.connect(sHostName, ctlport);			
		}
		
		/*
		
			Function that creates a Handshake object to perform
			the initial pre-test handshake with the server.
			
		*/
		
		public function protocolStart():void {
			
			var protocolObj:Protocol = new Protocol(ctlSocket);
			var msg:Message = new Message();
			
			removeResponseListener();
			
			var handshake:Handshake = new Handshake(ctlSocket, protocolObj, msg, _yTests, this);
		}
		
		/*
		
			This function initializes the array 'tests' with
			the different tests received in the message from
			the server.
			
			@param protocolObj
						The Protocol object used to communicate with the server.
			
			@param msg
						A Message object that contains the test suite.
						
		*/
		
		public function initiateTests(protocolObj:Protocol, msg:Message):void {
			tests = (new String(msg.getBody())).split(" ");
			testNo = 0;
			
			runTests(protocolObj);
		}
		
		/*
		
			Function that creates objects of the respective classes to run
			the tests.
			
			@param protocolObj
						The protocol object used to communicate with the server.
						
		*/
		
		public function runTests(protocolObj:Protocol):void {
			if(testNo < tests.length) {
				var test:int = parseInt(tests[testNo]);
				
				if(guiEnabled) {
					
					// to be removed
					gui.waitMessage();
				}
				
				switch(test) {
					case NDTConstants.TEST_S2C : var S2C:TestS2C = new TestS2C(ctlSocket, protocolObj, sHostName, this);
												 break;
				}
			}
			else {
				
				// temporarily set to view results using GUI
				finishedAll();
			}
			
		}
		
		// temporary function used to view results		
		public function finishedAll():void {
			var interpRes:TestResults = new TestResults(TestS2C._sTestResults, _yTests);
			
			if(guiEnabled) {
				gui.displayResults();
			}
		}
		
		/*
		
			The constructor receives parameters from the Fla file (and thus JavaScript)
			and initializes the tool accordingly.
			
			@param stageW
						The width of the stage to which this object is added.
			
			@param stageH
						The height of the stage to which this object is added.
			
			@param Parent
						The parent Display Container object.
						
			@param hostname
						The hostname of the server passed from JavaScript.
						
			@param clientID
						The ID of this client passed from JavaScript.
						
			@param guiEnabled
						A boolean representing necessity of a Flash based GUI (true=yes, false=no).
		
		*/
		
		public function MainFrame(stageW:int, stageH:int, Parent:DisplayObjectContainer, hostname:String, clientID:String, guiEnabled:Boolean) {
			// constructor code
			
			this.guiEnabled = guiEnabled;
			
			if(guiEnabled) {
				gui = new GUI(stageW, stageH, this);
				this.addChild(gui);
			}
			
			// variables initialization
			sHostName = NDTConstants.HOST_NAME; // need to check if hostname is passed and change accordingly
			pub_host = "unknown";
		}

	}
	
}
