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
  import flash.events.OutputProgressEvent;
  import flash.events.ProgressEvent;
  import flash.events.SecurityErrorEvent;
  import flash.events.TimerEvent;
  import flash.net.Socket;
  import flash.utils.ByteArray;
  import flash.utils.getTimer;
  import flash.utils.Timer;
  import mx.resources.ResourceManager;

  /**
   * This class performs the Client-to-Server throughput test.
   */
  public class TestC2S {
    // Valid values for _testStage.
    private static const PREPARE_TEST:int = 0;
    private static const START_TEST:int = 1;
    private static const SEND_DATA:int = 2;
    private static const COMPUTE_THROUGHPUT:int = 3;
    private static const COMPARE_SERVER:int = 4;
    private static const FINALIZE_TEST:int = 5;
    private static const END_TEST:int = 6;

    private var _callerObj:NDTPController;
    private var _c2sTestSuccess:Boolean;
    // Time to send data to server on the C2S socket.
    private var _c2sTestDuration:Number;
    private var _ctlSocket:Socket;
    private var _dataToSend:ByteArray;
    private var _c2sSocket:Socket;
    private var _c2sSendCount:int;
    // Bytes not sent from last send operation on the C2S socket.
    private var _c2sBytesNotSent:int;
    private var _c2sTimer:Timer;
    private var _serverHostname:String;
    private var _testStage:int;


    public function TestC2S(ctlSocket:Socket, serverHostname:String,
                            callerObj:NDTPController) {
      _callerObj = callerObj;
      _ctlSocket = ctlSocket;
      _serverHostname = serverHostname;

      _c2sTestSuccess = true;  // Initially the test has not failed.
      _c2sTestDuration = 0;
      _dataToSend = new ByteArray();
      _c2sSendCount = 0;
      _c2sBytesNotSent = 0;
    }

    public function run():void {
      TestResults.appendDebugMsg(
          ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "startingTest", null, Main.locale) +
          ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "c2sThroughput", null, Main.locale));
      NDTUtils.callExternalFunction("testStarted", "ClientToServerThroughput");

      addCtlSocketOnReceivedDataListener();
      _testStage = PREPARE_TEST;
      // In case data arrived before starting the ProgressEvent.SOCKET_DATA
      // listener.
      if (_ctlSocket.bytesAvailable > 0)
        prepareTest();
    }

    private function addCtlSocketOnReceivedDataListener():void {
      _ctlSocket.addEventListener(ProgressEvent.SOCKET_DATA, onCtlReceivedData);
    }

    private function removeCtlSocketOnReceivedDataListener():void {
      _ctlSocket.removeEventListener(ProgressEvent.SOCKET_DATA,
                                     onCtlReceivedData);
    }

    private function onCtlReceivedData(e:ProgressEvent):void {
      switch (_testStage) {
        case PREPARE_TEST:   prepareTest();
                             break;
        case START_TEST:     startTest();
                             break;
        case COMPARE_SERVER: compareWithServer();
                             break;
        case FINALIZE_TEST:  finalizeTest();
                             break;
        case END_TEST:       endTest();
                             break;
      }
    }

    private function prepareTest():void {
      if (_ctlSocket.bytesAvailable <= NDTConstants.MSG_HEADER_LENGTH)
        return;

      TestResults.appendDebugMsg("C2S test: PREPARE_TEST stage.");
      TestResults.appendDebugMsg(ResourceManager.getInstance().getString(
          NDTConstants.BUNDLE_NAME, "runningOutboundTest", null,
          Main.locale));
      TestResults.ndt_test_results::ndtTestStatus = "runningOutboundTest";

      var msg:Message = new Message();
      if (!msg.receiveMessage(_ctlSocket)) {
        TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(
                NDTConstants.BUNDLE_NAME, "protocolError", null, Main.locale)
          + parseInt(new String(msg.body), 16) + " instead.");
        _c2sTestSuccess = false;
        endTest();
        return;
      }

      if (msg.type != MessageType.TEST_PREPARE) {
        TestResults.appendErrMsg(ResourceManager.getInstance().getString(
            NDTConstants.BUNDLE_NAME, "outboundWrongMessage",null,
            Main.locale));
        if (msg.type == MessageType.MSG_ERROR) {
          TestResults.appendErrMsg(
              "ERROR MSG: " + parseInt(new String(msg.body), 16));
        }
        _c2sTestSuccess = false;
        endTest();
        return;
      }

      // Prepare the data to send to the server.
      for (var i:int = 0; i < NDTConstants.PREDEFINED_BUFFER_SIZE; i++) {
        _dataToSend.writeByte(i);
      }
      TestResults.appendDebugMsg(
          "Each message of the C2S test has " + _dataToSend.length + " bytes.");

      var c2sPort:int = parseInt(new String(msg.body));
      _c2sSocket = new Socket();
      addC2SSocketEventListeners();
      try {
        _c2sSocket.connect(_serverHostname, c2sPort);
      } catch(e:IOError) {
        TestResults.appendErrMsg("C2S socket connect IO error: " + e);
        _c2sTestSuccess = false;
        endTest();
        return;
      } catch(e:SecurityError) {
        TestResults.appendErrMsg("C2S socket connect security error: " + e);
        _c2sTestSuccess = false;
        endTest();
        return;
      }

      _c2sTimer = new Timer(NDTConstants.C2S_DURATION);
      _c2sTimer.addEventListener(TimerEvent.TIMER, onC2STimeout);

      _testStage = START_TEST;
      // If TEST_PREPARE and TEST_START messages arrive together at the client,
      // they trigger a single ProgressEvent.SOCKET_DATA event. In such case,
      // the following condition is needed to move to the next step.
      if (_ctlSocket.bytesAvailable > 0)
        startTest();
    }

    private function addC2SSocketEventListeners():void {
      _c2sSocket.addEventListener(Event.CONNECT, onC2SConnect);
      _c2sSocket.addEventListener(Event.CLOSE, onC2SClose);
      _c2sSocket.addEventListener(IOErrorEvent.IO_ERROR, onC2SIOError);
      _c2sSocket.addEventListener(SecurityErrorEvent.SECURITY_ERROR,
                                  onC2SSecError);
      _c2sSocket.addEventListener(OutputProgressEvent.OUTPUT_PROGRESS,
                                  onC2SProgress);
    }

    private function removeC2SSocketEventListeners():void {
      _c2sSocket.removeEventListener(Event.CONNECT, onC2SConnect);
      _c2sSocket.removeEventListener(Event.CLOSE, onC2SClose);
      _c2sSocket.removeEventListener(IOErrorEvent.IO_ERROR, onC2SIOError);
      _c2sSocket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR,
                                     onC2SSecError);
      _c2sSocket.removeEventListener(OutputProgressEvent.OUTPUT_PROGRESS,
                                     onC2SProgress);
    }

    private function onC2SConnect(e:Event):void {
      TestResults.appendDebugMsg("C2S socket connected.");
    }

    private function onC2SClose(e:Event):void {
      TestResults.appendDebugMsg("C2S socket closed by the server.");
      closeC2SSocket();
    }

    private function onC2SIOError(e:IOErrorEvent):void {
      TestResults.appendErrMsg("IOError on C2S socket: " + e);
      _c2sTestSuccess = false;
      closeC2SSocket();
      endTest();
    }

    private function onC2SSecError(e:SecurityErrorEvent):void {
      TestResults.appendErrMsg("Security error on C2S socket: " + e);
      _c2sTestSuccess = false;
      closeC2SSocket();
      endTest();
    }

    private function onC2SProgress(e:OutputProgressEvent):void {
      if (_c2sSocket.bytesPending == 0)
        _c2sSendCount++;
      if (_c2sSocket.connected) {
        sendData();
      } else {
        closeC2SSocket();
      }
    }

    private function onC2STimeout(e:TimerEvent):void {
      TestResults.appendDebugMsg("Timeout for sending data on C2S socket.");
      closeC2SSocket();
    }

    private function startTest():void {
      if (_ctlSocket.bytesAvailable < NDTConstants.MSG_HEADER_LENGTH)
        return;

      // Remove ctl socket listener so it does not interfere with C2S socket
      // listeners.
      removeCtlSocketOnReceivedDataListener();

      TestResults.appendDebugMsg("C2S test: START_TEST stage.");

      var msg:Message = new Message();
      if (!msg.receiveMessage(_ctlSocket)) {
        TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(
                NDTConstants.BUNDLE_NAME, "protocolError", null, Main.locale)
            + parseInt(new String(msg.body), 16) + " instead.");
        _c2sTestSuccess = false;
        endTest();
        return;
      }

      if (msg.type != MessageType.TEST_START) {
        TestResults.appendErrMsg(ResourceManager.getInstance().getString(
            NDTConstants.BUNDLE_NAME, "outboundWrongMessage", null,
            Main.locale));
        if (msg.type == MessageType.MSG_ERROR) {
          TestResults.appendErrMsg("ERROR MSG: "
                                   + parseInt(new String(msg.body), 16));
        }
        _c2sTestSuccess = false;
        endTest();
        return;
      }

      _c2sTimer.start();
      // Record start time right before it starts sending data, to be as
      // accurate as possible.
      _c2sTestDuration = getTimer();

      _testStage = SEND_DATA;
      TestResults.appendDebugMsg("C2S test: SEND_DATA stage.");
      sendData();
    }

    /**
     * Function that is called repeatedly to send data to the server through the
     * C2S socket.
    */
    private function sendData():void {
      _c2sSocket.writeBytes(_dataToSend, 0, _dataToSend.length);
      _c2sSocket.flush();
    }

    private function closeC2SSocket():void {
      // Record end time right after it stops sending data, to be as accurate as
      // possible.
      _c2sTestDuration = getTimer() - _c2sTestDuration;
      TestResults.appendDebugMsg(
          "C2S test lasted " + _c2sTestDuration + " msec.");
      _c2sTimer.stop();
      _c2sTimer.removeEventListener(TimerEvent.TIMER, onC2STimeout);

      if (_c2sSocket.connected)
        _c2sBytesNotSent = _c2sSocket.bytesPending;

      removeC2SSocketEventListeners();
      try {
        _c2sSocket.close();
      } catch (e:IOError) {
        TestResults.appendErrMsg(
            "IO Error while closing C2S socket: " + e);
      }
      addCtlSocketOnReceivedDataListener();

      _testStage = COMPUTE_THROUGHPUT;
      calculateThroughput();
    }

    private function calculateThroughput():void {
      TestResults.appendDebugMsg("C2S test: COMPUTE_THROUGHPUT stage.");

      var c2sByteSent:Number = (
          _c2sSendCount * NDTConstants.PREDEFINED_BUFFER_SIZE
          + (NDTConstants.PREDEFINED_BUFFER_SIZE - _c2sBytesNotSent));
      TestResults.appendDebugMsg("C2S test sent " + c2sByteSent + " bytes.");

      var c2sSpeed:Number = (
          (c2sByteSent * NDTConstants.BYTES2BITS)
          / _c2sTestDuration);
      TestResults.ndt_test_results::c2sSpeed = c2sSpeed;
      TestResults.appendDebugMsg("C2S throughput computed by client is "
                                 + c2sSpeed.toFixed(2) + " kbps.");

      _testStage = COMPARE_SERVER;
      if (_ctlSocket.bytesAvailable > 0)
        compareWithServer();
    }

    private function compareWithServer():void {
      if (_ctlSocket.bytesAvailable <= NDTConstants.MSG_HEADER_LENGTH)
        return;

      TestResults.appendDebugMsg("C2S test: COMPARE_SERVER stage.");

      var msg:Message = new Message();
      if (!msg.receiveMessage(_ctlSocket)) {
        TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(
                NDTConstants.BUNDLE_NAME, "protocolError", null, Main.locale)
          + parseInt(new String(msg.body), 16) + " instead.");
        _c2sTestSuccess = false;
        endTest();
        return;
      }

      if (msg.type != MessageType.TEST_MSG) {
        TestResults.appendErrMsg(ResourceManager.getInstance().getString(
            NDTConstants.BUNDLE_NAME, "outboundWrongMessage", null,
            Main.locale));
        if(msg.type == MessageType.MSG_ERROR) {
          TestResults.appendErrMsg("ERROR MSG: "
                                   + parseInt(new String(msg.body), 16));
        }
        _c2sTestSuccess = false;
        endTest();
        return;
      }

      var sc2sSpeedStr:String = new String(msg.body);
      var sc2sSpeed:Number = parseFloat(sc2sSpeedStr);
      if (isNaN(sc2sSpeed)) {
        TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(
                NDTConstants.BUNDLE_NAME, "outboundWrongMessage", null,
                Main.locale)
            + "Message received: " + sc2sSpeedStr);
        _c2sTestSuccess = false;
        endTest();
        return;
      }

      TestResults.ndt_test_results::sc2sSpeed = sc2sSpeed;
      TestResults.appendDebugMsg("C2S throughput computed by the server is "
                                 + sc2sSpeed.toFixed(2) + "kbps");

      _testStage = FINALIZE_TEST;
      if(_ctlSocket.bytesAvailable > 0)
        finalizeTest();
    }

    private function finalizeTest():void {
      if (_ctlSocket.bytesAvailable < NDTConstants.MSG_HEADER_LENGTH)
        return;

      TestResults.appendDebugMsg("C2S test: FINALIZE_TEST stage.");

      var msg:Message = new Message();
      if (!msg.receiveMessage(_ctlSocket)) {
        TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(
                NDTConstants.BUNDLE_NAME, "protocolError", null, Main.locale)
            + parseInt(new String(msg.body), 16) + " instead.");
        _c2sTestSuccess = false;
        endTest();
        return;
      }

      if (msg.type != MessageType.TEST_FINALIZE) {
        TestResults.appendErrMsg(ResourceManager.getInstance().getString(
            NDTConstants.BUNDLE_NAME, "outboundWrongMessage", null,
            Main.locale));
        if (msg.type == MessageType.MSG_ERROR) {
          TestResults.appendErrMsg("ERROR MSG: "
                                   + parseInt(new String(msg.body), 16));
        }
        _c2sTestSuccess = false;
        endTest();
        return;
      }

      _c2sTestSuccess = true;
      endTest();
      return;
    }

    private function endTest():void {
      TestResults.appendDebugMsg("C2S test: END_TEST stage.");
      removeCtlSocketOnReceivedDataListener();

      if (_c2sTestSuccess)
        TestResults.appendDebugMsg(
            ResourceManager.getInstance().getString(
                NDTConstants.BUNDLE_NAME, "c2sThroughput", null, Main.locale)
            + " test " + ResourceManager.getInstance().getString(
                NDTConstants.BUNDLE_NAME, "done", null, Main.locale));
      else
        TestResults.appendDebugMsg(ResourceManager.getInstance().getString(
            NDTConstants.BUNDLE_NAME, "c2sThroughputFailed", null,
            Main.locale));
      TestResults.ndt_test_results::c2sTestSuccess = _c2sTestSuccess;
      TestResults.ndt_test_results::ndtTestStatus = "done";
      NDTUtils.callExternalFunction("testCompleted", "ClientToServerThroughput",
                                    (!_c2sTestSuccess).toString());

      _callerObj.runTests();
    }
  }
}

