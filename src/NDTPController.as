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
  import flash.errors.IOError;
  import flash.events.Event;
  import flash.events.IOErrorEvent;
  import flash.events.ProgressEvent;
  import flash.events.SecurityErrorEvent;
  import flash.events.TimerEvent;
  import flash.net.Socket;
  import flash.system.Security;
  import flash.utils.Timer;
  import mx.resources.ResourceManager;

  /**
   * Class responsible for establishing the socket connection and initiating
   * communications with the server (NDTP-Control).
   * Calls functions to perform the required tests and to interpret the results.
   */
  public class NDTPController {
    private var _ctlSocket:Socket = null;
    private var _hostname:String;
    private var _readResultsTimer:Timer;
    private var _testsToRun:Array;

    public function NDTPController(hostname:String) {
      _hostname = hostname;
      _readResultsTimer = new Timer(10000);
    }

    // Control socket event listeners.
    private function onConnect(e:Event):void {
      TestResults.appendDebugMsg("Control socket connected");
      startHandshake();
    }

    private function onClose(e:Event):void {
      TestResults.appendDebugMsg("Control socket closed by server");
    }

    private function onIOError(e:IOErrorEvent):void {
      TestResults.appendErrMsg("IOError on control socket: " + e);
      failNDTTest();
    }

    private function onSecurityError(e:SecurityErrorEvent):void {
      TestResults.appendErrMsg("Security error on control socket: " + e);
      failNDTTest();
    }

    private function addSocketEventListeners():void {
      _ctlSocket.addEventListener(Event.CONNECT, onConnect);
      _ctlSocket.addEventListener(Event.CLOSE, onClose);
      _ctlSocket.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
      _ctlSocket.addEventListener(SecurityErrorEvent.SECURITY_ERROR,
                                  onSecurityError);
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

    public function startNDTTest():void {
      TestResults.recordStartTime();
      TestResults.ndt_test_results::ndtTestFailed = false;
      TestResults.appendDebugMsg(ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "connectingTo", null, Main.locale)
          + " " + _hostname + " " + ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "toRunTest", null, Main.locale));

      _ctlSocket = new Socket();
      addSocketEventListeners();
      try {
        _ctlSocket.connect(_hostname, NDTConstants.DEFAULT_CONTROL_PORT);
      } catch(e:IOError) {
        TestResults.appendErrMsg("Control socket connect IO error: " + e);
        failNDTTest();
      } catch(e:SecurityError) {
        TestResults.appendErrMsg("Control socket connect security error: " + e);
        failNDTTest();
      }
    }

    private function startHandshake():void {
      var handshake:Handshake = new Handshake(
          _ctlSocket, NDTConstants.TESTS_REQUESTED_BY_CLIENT, this);
      handshake.run();
    }

    /**
     * This function initializes the array 'tests' with the different tests
     * received in the message from the server.
     */
    public function initiateTests(testsConfirmedByServer:String):void {
      _testsToRun = testsConfirmedByServer.split(" ");
      // TODO(tiziana): Use tests confirmed by the server.
      runTests();
    }

    /**
     * Function that creates objects of the respective classes to run the tests.
     */
    public function runTests():void {
      if (_testsToRun.length > 0) {
       var currentTest:int = parseInt(_testsToRun.shift());
        switch (currentTest) {
          case TestType.C2S:
              var c2s:TestC2S = new TestC2S(_ctlSocket, _hostname, this);
              TestResults.appendDebugMsg(
                  ResourceManager.getInstance().getString(
                      NDTConstants.BUNDLE_NAME, "startingTest", null,
                      Main.locale)
                  + ResourceManager.getInstance().getString(
                      NDTConstants.BUNDLE_NAME, "c2sThroughput"));
              c2s.run();
              break;
          case TestType.S2C:
              var s2c:TestS2C = new TestS2C(_ctlSocket, _hostname, this);
              TestResults.appendDebugMsg(
                  ResourceManager.getInstance().getString(
                      NDTConstants.BUNDLE_NAME, "startingTest", null,
                      Main.locale)
                  + ResourceManager.getInstance().getString(
                      NDTConstants.BUNDLE_NAME, "s2cThroughput"));
              s2c.run();
              break;
          case TestType.META:
              var meta:TestMETA = new TestMETA(_ctlSocket, this);
              TestResults.appendDebugMsg(
                  ResourceManager.getInstance().getString(
                      NDTConstants.BUNDLE_NAME, "startingTest", null,
                      Main.locale)
                  + ResourceManager.getInstance().getString(
                      NDTConstants.BUNDLE_NAME, "meta"));
              meta.run();
              break;
          default:
              TestResults.appendErrMsg(ResourceManager.getInstance().getString(
                  NDTConstants.BUNDLE_NAME, "unknownID", null, Main.locale));
              failNDTTest();
        }
      } else {
        receiveRemoteResults();
      }
    }

    private function onReadTimeout(e:TimerEvent):void {
      _readResultsTimer.stop();
      TestResults.appendErrMsg(ResourceManager.getInstance().getString(
          NDTConstants.BUNDLE_NAME, "resultsTimeout", null, Main.locale));
      failNDTTest();
    }

    private function addOnReadTimeout():void {
      _readResultsTimer.reset();
      _readResultsTimer.addEventListener(TimerEvent.TIMER, onReadTimeout);
      _readResultsTimer.start();
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
      TestResults.ndt_test_results::remoteTestResults =
          TestResults.ndt_test_results::s2cTestResults;

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
          failNDTTest();
          return;
        }
        if (msg.type == MessageType.MSG_RESULTS) {
            TestResults.ndt_test_results::remoteTestResults += new String(
                msg.body);
           continue;
        }
        // All results obtained. LOGOUT message received now.
        if (msg.type == MessageType.MSG_LOGOUT) {
          _readResultsTimer.stop();
          removeOnReceivedDataListener();
          succeedNDTTest();
          return;
        }
        TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(
                NDTConstants.BUNDLE_NAME, "resultsWrongMessage", null,
                Main.locale));
        _readResultsTimer.stop();
        failNDTTest();
        return;
      }
      return;
    }

    public function failNDTTest():void {
      TestResults.ndt_test_results::ndtTestFailed = true;
      NDTUtils.callExternalFunction("fatalErrorOccured");
      TestResults.appendErrMsg("NDT test failed");
      finishNDTTest();
    }

    public function succeedNDTTest():void {
      TestResults.ndt_test_results::ndtTestFailed = false;
      NDTUtils.callExternalFunction("allTestsCompleted");
      TestResults.appendDebugMsg("All the tests completed successfully");
      finishNDTTest();
    }

    /**
     * Function that is called on completion of all the tests and after the
     * retrieval of the last set of results.
     */
    public function finishNDTTest():void {
      TestResults.recordEndTime();
      try {
        _ctlSocket.close();
      } catch (e:IOError) {
        TestResults.appendErrMsg(
            "Client failed to close control socket. Error" + e);
      }
      TestResults.interpretResults();
      if (Main.guiEnabled) {
        Main.gui.displayResults();
      }
    }
  }
}

