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
  import flash.errors.IOError;
  import mx.resources.ResourceManager;
    
  /**
   * Class responsible for establishing the socket connection and initiating
   * communications with the server (NDTP-Control).
   * Calls functions to perform the required tests and to interpret the results.
   */
  public class MainFrame {
    private var hostname_:String;
    private var readResultsTimer_:Timer;
    private var ctlSocket_:Socket = null;
    
    private var msg:Message;
    private var tests:Array;
    private var _sTestResults:String = null;
    public var testNo:int;
    private var readCount:int;
    private var _yTests:int =  TestType.C2S | TestType.S2C
                               | TestType.META;
    
    // Control socket event listeners.
    private function onConnect(e:Event):void {
      TestResults.appendTraceOutput("Control socket connected.");
      startHandshake();
    }
    private function onClose(e:Event):void {
      TestResults.appendTraceOutput("Control socket closed by server.");
      // TODO: Check what to do.
    }
    private function onIOError(e:IOErrorEvent):void {
      TestResults.appendErrMsg("IOError on control socket: " + e);
      failNDTTest();
    }
    private function onSecurityError(e:SecurityErrorEvent):void {
      TestResults.appendErrMsg("Security error on control socket: " + e);
      failNDTTest();
    }
    private function onReceivedData(e:ProgressEvent):void {
      readResultsTimer_.reset();
      getRemoteResults();
      // TODO: Check why the timer is started after getRemoteResults.
      readResultsTimer_.start();
    }
    private function addSocketEventListeners():void {
      ctlSocket_.addEventListener(Event.CONNECT, onConnect);
      ctlSocket_.addEventListener(Event.CLOSE, onClose);
      ctlSocket_.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
      ctlSocket_.addEventListener(SecurityErrorEvent.SECURITY_ERROR,
                                 onSecurityError);
      // Add onReceivedData separately.
      // TODO: Check if also OutputProgressEvents should be handled.
    }
    private function removeOnReceivedDataListener():void {
      ctlSocket_.removeEventListener(ProgressEvent.SOCKET_DATA, onReceivedData);
    }
    private function addOnReceivedDataListener():void {
      ctlSocket_.addEventListener(ProgressEvent.SOCKET_DATA, onReceivedData);
    }
    
    public function startNDTTest():void {
      TestResults.set_StartTime();
      TestResults.appendConsoleOutput(
        ResourceManager.getInstance().getString(
          NDTConstants.BUNDLE_NAME, "connectingTo", null, Main.locale)
        + " " + hostname_ + " " + 
        ResourceManager.getInstance().getString(
          NDTConstants.BUNDLE_NAME, "toRunTest", null, Main.locale)
        + "\n");

      ctlSocket_ = new Socket();
      addSocketEventListeners();
      try {
        ctlSocket_.connect(hostname_, NDTConstants.DEFAULT_CONTROL_PORT);
      } catch(e:IOError) {
        TestResults.appendErrMsg("Control socket connect error: " + e);
        failNDTTest();
      } catch(e:SecurityError) {
        TestResults.appendErrMsg("Control socket connect error: " + e);
        failNDTTest();
      }
    }
    
    private function startHandshake():void {
      var handshake:Handshake = new Handshake(ctlSocket_, _yTests, this);
    }
    
    /**
     * This function initializes the array 'tests' with
     * the different tests received in the message from
     * the server.
     */
    public function initiateTests(confirmedTests:String):void {
      tests = confirmedTests.split(" ");
      testNo = 0;
      runTests();
    }
    
    /**
     * Function that creates objects of the respective classes to run
     * the tests.
     */
    public function runTests():void {
      if (testNo < tests.length) {
        var test:int = parseInt(tests[testNo]);
        switch (test) {
          case TestType.C2S: NDTUtils.callExternalFunction(
                                          "testStarted", "ClientToServerThroughput");
                                      var C2S:TestC2S = new TestC2S(
				          ctlSocket_, hostname_, this);
                                      NDTUtils.callExternalFunction(
                                        "testCompleted", 
                                        "ClientToServerThroughput",
                                        (!TestResults.get_c2sFailed()).toString());  
                                      break;
          case TestType.S2C: NDTUtils.callExternalFunction(
                                        "testStarted", "ServerToClientThroughput");
                                      var S2C:TestS2C = new TestS2C(
				          ctlSocket_, hostname_, this);
                                      NDTUtils.callExternalFunction(
                                        "testCompleted", 
                                        "ServerToClientThroughput",
                                        (!TestResults.get_s2cFailed()).toString());
                                      break;
          case TestType.META: NDTUtils.callExternalFunction(
                                         "testStarted", "Meta");
                                       var META:TestMETA = new TestMETA(
				           ctlSocket_, this);
                                       NDTUtils.callExternalFunction(
                                         "testCompleted", 
                                         "Meta",
                                         (!TestResults.get_metaFailed()).toString());
                                       break;
        }
      } else {
        _sTestResults = TestS2C.getResultString();
        readResultsTimer_ = new Timer(10000);
        readResultsTimer_.addEventListener(TimerEvent.TIMER, onReadTimeout);
        addOnReceivedDataListener();
	readResultsTimer_.start();
        if (ctlSocket_.bytesAvailable > 0)
          getRemoteResults();
      }
    }
    private function onReadTimeout(e:TimerEvent):void {
      readResultsTimer_.stop();
      TestResults.appendErrMsg("Read timeout while reading results.");
      // TODO: Check why calling failNDTTest here fails.
      TestResults.set_bFailed(true);
    }
    
    /**
     * Function that reads the rest of the server calculated
     * results and appends them to the test results String
     * for interpretation.
     */
     private function getRemoteResults():void {
      msg = new Message();
      while (ctlSocket_.bytesAvailable > 0) {
        if (msg.receiveMessage(ctlSocket_) !=
	    NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
          TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "protocolError", null,Main.locale) 
            + parseInt(new String(msg.body), 16)
            + " instead\n");
          TestResults.set_bFailed(true);
          readResultsTimer_.stop();
          return;
        }
        // all results obtained. "Log Out" message received now
        if (msg.type == MessageType.MSG_LOGOUT) {
          readResultsTimer_.stop();
          removeOnReceivedDataListener();
          finishedAll();
        }
        // get results in the form of a human-readable string
        if (msg.type != MessageType.MSG_RESULTS) {
          TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "resultsWrongMessage", null,Main.locale)
            + "\n");
          TestResults.set_bFailed(true);
          readResultsTimer_.stop();
          return;
        }
        _sTestResults += new String(msg.body);
      }
    }

    private function failNDTTest():void {
      TestResults.set_bFailed(true);
      finishedAll();
    }
    /**
     * Function that is called on completion of all the tests and after the
     * retrieval of the last set of results.
     */
    public function finishedAll():void {
      if(TestResults.get_bFailed())
        NDTUtils.callExternalFunction("fatalErrorOccured");
      NDTUtils.callExternalFunction("allTestsCompleted");
      try {
        ctlSocket_.close();
      } catch (e:IOError) {
        TestResults.appendErrMsg("Client failed to close Control Socket Connection\n");
      }
      if (_sTestResults != null)
        var interpRes:TestResults = new TestResults(_sTestResults, _yTests);
      NDTUtils.callExternalFunction("resultsProcessed");
      TestResults.set_EndTime();
      if (Main.guiEnabled) {
        Main.gui.displayResults();
      }
      trace("Console Output:\n" + TestResults.getConsoleOutput() + "\n");
      trace("Statistics Output:\n" + TestResults.getStatsText() + "\n");
      trace("Diagnosis Output:\n" + TestResults.getDiagnosisText() + "\n");
      trace("Errors:\n" + TestResults.getErrMsg() + "\n");
    }
    
    public function MainFrame(hostname:String) {
      hostname_ = hostname;
    }
  }
}

