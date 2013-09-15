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
  import flash.display.DisplayObjectContainer;
  import flash.display.Sprite;
  import flash.errors.IOError;
  import flash.events.Event;
  import flash.events.IOErrorEvent;
  import flash.events.ProgressEvent;
  import flash.events.SecurityErrorEvent;
  import flash.events.TimerEvent;
  import flash.net.Socket;
  import flash.system.Security;
  import flash.text.TextField;
  import flash.utils.Timer;
  import mx.resources.ResourceManager;
  import mx.utils.StringUtil;
    
  /**
   * Class responsible for establishing the socket connection and initiating
   * communications with the server (NDTP-Control).
   * Calls functions to perform the required tests and to interpret the results.
   */
  public class MainFrame {
    private static var sHostName:String = null;
    private static var clientId:String = null;
    private var pub_host:String;
    private var ctlSocket:Socket = null;
    private var protocolObj:Protocol;
    private var msg:Message;
    private var tests:Array;
    private var _sTestResults:String = null;
    public var testNo:int;
    private var readTimer:Timer;
    private var readCount:int;
    private var _yTests:int =  TestType.C2S | TestType.S2C
                               | TestType.META;
    
    // socket event listener functions
    public function onConnect(e:Event):void {
      trace("Socket connected.");
      TestResults.appendTraceOutput("Socket connected\n");
      protocolStart();
    }
    public function onClose(e:Event):void {
      // have to check what to do
    }
    public function onError(e:IOErrorEvent):void {
      trace("IOError : " + e);
      TestResults.appendErrMsg("IOError : " + e);
      TestResults.set_bFailed(true);
      finishedAll();
    }
    public function onSecError(e:SecurityErrorEvent):void {
      trace("Security Error" + e);
      TestResults.appendErrMsg("Security error : " + e);
      TestResults.set_bFailed(true);
      finishedAll();
    }
    public function onResponse(e:ProgressEvent):void {
      readTimer.reset();
      getRemResults();
      readTimer.start();
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
    
    public function onReadTimeout(e:TimerEvent):void {
      readTimer.stop();
      TestResults.appendErrMsg("Read timeout while reading results\n");
      TestResults.set_bFailed(true);
      return;
    }
    
    /**    
     * Function that creates the Control Socket object
     * used to communicate with the server.
     */
    public function dottcp():void {
      pub_host = sHostName;
      // default control port used for the NDT tests session. NDT server
      // listens to this port
      var ctlport:uint = NDTConstants.CONTROL_PORT_DEFAULT;
            
      TestResults.set_bFailed(false);  // test result status is false initially
      TestResults.appendConsoleOutput(
        ResourceManager.getInstance().getString(
          NDTConstants.BUNDLE_NAME, "connectingTo", null, Main.locale)
        + " " + sHostName + " " + 
        ResourceManager.getInstance().getString(
          NDTConstants.BUNDLE_NAME, "toRunTest", null, Main.locale)
        + "\n");
      ctlSocket = new Socket();
      addEventListeners();
      removeResponseListener(); // So it does not interfere with other tests
      ctlSocket.connect(sHostName, ctlport);      
    }
    
    /**
     * Function that creates a Handshake object to perform
     * the initial pre-test handshake with the server. 
     */
    public function protocolStart():void {
      protocolObj =  new Protocol(ctlSocket);
      msg = new Message();
      var handshake:Handshake = new Handshake(ctlSocket, protocolObj, 
                                              msg, _yTests, this);
    }
    
    /**
     * This function initializes the array 'tests' with
     * the different tests received in the message from
     * the server.
     * @param {Protocol} protocolObj The object used to communicate with
     *    the server.
     * @param {Message} msg An object that contains the test suite message.
     */
    public function initiateTests(protocolObj:Protocol, msg:Message):void {
      var tStr:String = new String(msg.body);
      tStr = new String(StringUtil.trim(tStr));
      tests = tStr.split(" ");
      testNo = 0;
      runTests(protocolObj);
    }
    
    /**
     * Function that creates objects of the respective classes to run
     * the tests.
     * @param {Protocol} protocolObj The object used to communicate with
     *    the server.      
     */
    public function runTests(protocolObj:Protocol):void {
      if (testNo < tests.length) {
        var test:int = parseInt(tests[testNo]);
        switch (test) {
          case TestType.C2S: var C2S:TestC2S =
                                      new TestC2S(ctlSocket, protocolObj,
                                                  sHostName, this);
                                      break;
          case TestType.S2C: var S2C:TestS2C =
                                      new TestS2C(ctlSocket, protocolObj, 
                                                  sHostName, this);
                                      break;
          case TestType.META: var META:TestMETA =
                                       new TestMETA(ctlSocket, protocolObj, 
                                                    clientId, this);
                                       break;
        }
      } else {
        _sTestResults = TestS2C.getResultString();
        readTimer = new Timer(10000);
        readTimer.addEventListener(TimerEvent.TIMER, onReadTimeout);
        addResponseListener();
        readTimer.start();
        if (ctlSocket.bytesAvailable > 0)
          getRemResults();
      }
    }
    
    /**
     * Function that reads the rest of the server calculated
     * results and appends them to the test results String
     * for interpretation.
     */
     private function getRemResults():void {
      while (ctlSocket.bytesAvailable > 0) {
        if (protocolObj.recv_msg(msg) != NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
          TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "protocolError", null,Main.locale) 
            + parseInt(new String(msg.body), 16)
            + " instead\n");
          TestResults.set_bFailed(true);
          return;
        }
        // all results obtained. "Log Out" message received now
        if (msg.type == MessageType.MSG_LOGOUT) {
          readTimer.stop();
          removeResponseListener();
          finishedAll();
        }
        // get results in the form of a human-readable string
        if (msg.type != MessageType.MSG_RESULTS) {
          TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "resultsWrongMessage", null,Main.locale)
            + "\n");
          TestResults.set_bFailed(true);
          return;
        }
        _sTestResults += new String(msg.body);
      }
    }
    
    /**
     * Function that is called on completion of all the tests and after the
     * retrieval of the last set of results.
     */
    public function finishedAll():void {
      try {
        ctlSocket.close();
      } catch (e:IOError) {
        TestResults.appendErrMsg("Client failed to close Control Socket Connection\n");
      }
      // temporarily set to view results using GUI
      if (_sTestResults != null)
        var interpRes:TestResults = new TestResults(_sTestResults, _yTests);
      if (Main.guiEnabled) {
        Main.gui.displayResults();
      }
      trace("Console Output:\n" + TestResults.getConsoleOutput() + "\n");
      trace("Statistics Output:\n" + TestResults.getStatsText() + "\n");
      trace("Diagnosis Output:\n" + TestResults.getDiagnosisText() + "\n");
      trace("Errors:\n" + TestResults.getErrMsg() + "\n");
    }
    
    /**
     * The constructor of the MainFrame class which is used to pass initial data
     * from JavaScript.
     * @param {String} hostname The hostname of the server recvd from JavaScript.
     */
    public function MainFrame(hostname:String) {
      // variables initialization
      sHostName = hostname;
      clientId = NDTConstants.CLIENT_ID;
      pub_host = "unknown";
    }
  }
}

