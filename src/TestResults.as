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
  use namespace ndt_test_results;
  import flash.events.ProgressEvent;
  import flash.events.TimerEvent;
  import flash.net.Socket;
  import flash.utils.getTimer;
  import flash.utils.Timer;
  import mx.resources.ResourceManager;
  /**
   * Class that interprets the results of the tests. The results are stored in
   * variables that can be accessed through JavaScript.
   */
  public class TestResults {
    private static var _requestedTests:int;
    private static var _callerObj:NDTPController;
    private static var _ctlSocket:Socket;

    private static var _readResultsTimer:Timer;
    private static var _ndtTestStartTime:Number = 0.0;
    private static var _ndtTestEndTime:Number = 0.0;
    private static var _remoteTestResults:String;  // Results sent by the server

    private static var _resultDetails:String = "";
    private static var _errMsg:String = "";
    private static var _debugMsg:String = "";

    // Variables accessed by other classes to get and/or set values.
    ndt_test_results static var mylink:Number = 0.0;
    ndt_test_results static var accessTech:String = null;
    ndt_test_results static var ndtVariables:Object = new Object();
    ndt_test_results static var userAgent:String;
    // Valid only when ndtTestFailed == false.
    ndt_test_results static var ndtTestStatus:String = null;
    ndt_test_results static var ndtTestFailed:Boolean = false;
    // Never used. TODO: Remove.
    ndt_test_results static var c2sTime:Number = 0.0;
    // Never used. TODO: Remove.
    ndt_test_results static var c2sPktsSent:Number = 0.0;
    ndt_test_results static var c2sSpeed:Number = 0.0;
    ndt_test_results static var s2cSpeed:Number = 0.0;
    ndt_test_results static var s2cTestResults:String;
    ndt_test_results static var sc2sSpeed:Number = 0.0;
    ndt_test_results static var ss2cSpeed:Number = 0.0;

    public static function get jitter():Number {
      return ndtVariables[NDTConstants.MAXRTT] -
             ndtVariables[NDTConstants.MINRTT];
    }

    public static function get duration():Number {
      return _ndtTestEndTime - _ndtTestStartTime;
    }

    // TODO: Move to TestType.
    public static function get testList():String {
       var testSuite:String = "";
       if(_requestedTests & TestType.C2S)
          testSuite += "CLIENT_TO_SERVER_THROUGHPUT\n";
       if(_requestedTests & TestType.S2C)
          testSuite += "SERVER_TO_CLIENT_THROUGHPUT\n";
       if(_requestedTests & TestType.META)
          testSuite += "META_TEST\n";
      return testSuite;
    }

    public static function recordStartTime():void {
      _ndtTestStartTime = getTimer();
    }

    public static function recordEndTime():void {
      _ndtTestEndTime = getTimer();
    }

    public static function appendResultDetails(results:String):void {
      _resultDetails += results  + "\n";
    }

    public static function appendErrMsg(msg:String):void {
      _errMsg += msg + "\n";
      NDTUtils.callExternalFunction("appendErrors", msg);
      appendDebugMsg(msg);
    }

    public static function appendDebugMsg(msg:String):void {
      if (!CONFIG::debug) {
          return;
      }
      _debugMsg += msg + "\n";
      NDTUtils.callExternalFunction("appendDebugOutput", msg);
      // _ndtTestStartTime > 0 ensures the console window has been created.
      // TODO: Verify if there is cleaner alternative.
      if (Main.guiEnabled && _ndtTestStartTime > 0)
        // TODO: Handle the communication with GUI via events, instead of
        // blocking calls.
        GUI.addConsoleOutput(msg + "\n");
    }

    public static function getDebugMsg():String {
      return _debugMsg;
    }

    public static function getResultDetails():String {
      return _resultDetails;
    }

    public static function getErrMsg():String {
      return _errMsg;
    }

    public function TestResults(
        socket:Socket, requestedTests:int, callerObject:NDTPController) {
      _ctlSocket = socket;
      _requestedTests = requestedTests;
      _callerObj = callerObject;
      _readResultsTimer = new Timer(10000);
    }

    private function onReceivedData(e:ProgressEvent):void {
      getRemoteResults();
    }
    private function addOnReceivedDataListener():void {
      _ctlSocket.addEventListener(ProgressEvent.SOCKET_DATA, onReceivedData);
    }
    private function removeOnReceivedDataListener():void {
      _ctlSocket.removeEventListener(ProgressEvent.SOCKET_DATA, onReceivedData);
    }
    private function addOnReadTimeout():void {
      _readResultsTimer.reset();
      _readResultsTimer.addEventListener(TimerEvent.TIMER, onReadTimeout);
      _readResultsTimer.start();
    }
    private function onReadTimeout(e:TimerEvent):void {
      _readResultsTimer.stop();
      TestResults.appendErrMsg("Read timeout while reading results.");
      _callerObj.failNDTTest();
    }


    public function receiveRemoteResults():void {
      addOnReadTimeout();
      addOnReceivedDataListener();
      // In case data arrived before starting the onReceiveData listener.
       if (_ctlSocket.bytesAvailable > 0) {
          getRemoteResults();
       }
      }

   /**
     * Function that reads the rest of the server calculated results and appends
     * them to the test results String for interpretation.
     */
     private function getRemoteResults():void {
      _remoteTestResults = s2cTestResults;

      var msg:Message = new Message();
      while (_ctlSocket.bytesAvailable > 0) {
        if (msg.receiveMessage(_ctlSocket) !=
            NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
          TestResults.appendErrMsg(
              ResourceManager.getInstance().getString(
                  NDTConstants.BUNDLE_NAME, "protocolError", null, Main.locale)
            + parseInt(new String(msg.body), 16)
            + " instead.");
          _readResultsTimer.stop();
	  _callerObj.failNDTTest();
          return;
        }
        // All results obtained. "Log Out" message received now.
        if (msg.type == MessageType.MSG_LOGOUT) {
          _readResultsTimer.stop();
          removeOnReceivedDataListener();
          _callerObj.succeedNDTTest();
          return;
        }
        // Get results in the form of a human-readable string.
        if (msg.type != MessageType.MSG_RESULTS) {
          TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "resultsWrongMessage", null,
	      Main.locale));
          _readResultsTimer.stop();
	  _callerObj.failNDTTest();
          return;
        }
        _remoteTestResults += new String(msg.body);
      }
    }

    public function interpretResults():void {
      TestResultsUtils.parseNDTVariables(_remoteTestResults);

      TestResultsUtils.appendClientInfo();
      if (ndtVariables[NDTConstants.COUNTRTT] > 0) {
	TestResultsUtils.getAccessLinkSpeed();
        TestResultsUtils.appendDuplexMismatchResult(
	  ndtVariables[NDTConstants.MISMATCH]);
	if ((_requestedTests & TestType.C2S) == TestType.C2S)
	  TestResultsUtils.appendC2SPacketQueueingResult();
	if ((_requestedTests & TestType.S2C) == TestType.S2C)
	  TestResultsUtils.appendC2SPacketQueueingResult();
	TestResultsUtils.appendDataRateResults();
	TestResultsUtils.appendDuplexCongestionMismatchResults();
	TestResultsUtils.appendPacketRetrasmissionResults();
	TestResultsUtils.appendPacketQueueingResults(_requestedTests);
        TestResultsUtils.appendOtherConnectionResults();
        TestResultsUtils.appendTCPNegotiatedOptions();
        TestResultsUtils.appendFurtherThroughputInfo();
        NDTUtils.callExternalFunction("resultsProcessed");
      }
      appendResultDetails("=== NDT variables ===");
      for (var key:Object in ndtVariables) {
        appendResultDetails(key + "=" + ndtVariables[key]);
      }
    }
  }
}

