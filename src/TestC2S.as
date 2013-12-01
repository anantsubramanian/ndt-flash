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
   * Class that contains functions that perform the Client-to-Server throughput
   * test. It is a 10 second memory-to-memory data transfer to test achievable
   * network bandwidth.
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
    // Time to send data to server on out socket.
    private var _c2sTestDuration:Number;
    private var _ctlSocket:Socket;
    private var _dataToSend:ByteArray;
    private var _outSocket:Socket;
    private var _outSendCount:int;
    // Bytes not sent from last send operation on out socket.
    private var _outBytesNotSent:int;
    private var _outTimer:Timer;
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
      _outSendCount = 0;
      _outBytesNotSent = 0;
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

    /**
     * Function that handles the TEST_PREPARE message sent by the server.
     * It fills the buffer ByteArray with data and creates a new Socket object
     * to connect to the port specified by the server.
     */
    private function prepareTest():void {
      if (_ctlSocket.bytesAvailable <= NDTConstants.MSG_HEADER_LENGTH)
        return;

      TestResults.appendDebugMsg("C2S test: PREPARE_TEST stage.");
      TestResults.appendDebugMsg(ResourceManager.getInstance().getString(
          NDTConstants.BUNDLE_NAME, "runningOutboundTest", null,
          Main.locale));
      TestResults.ndt_test_results::ndtTestStatus = "runningOutboundTest";

      var msg:Message = new Message();
      if (msg.receiveMessage(_ctlSocket)
          != NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
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
      _outSocket = new Socket();
      addOutSocketEventListeners();
      try {
        _outSocket.connect(_serverHostname, c2sPort);
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
      _outTimer = new Timer(NDTConstants.C2S_DURATION);
      _outTimer.addEventListener(TimerEvent.TIMER, onOutTimeout);

      _testStage = START_TEST;
      // If TEST_PREPARE and TEST_START messages arrive together at the client,
      // they trigger a single ProgressEvent.SOCKET_DATA event. In such case,
      // the following condition is needed to move to the next step.
      if (_ctlSocket.bytesAvailable > 0)
        startTest();
    }

    private function addOutSocketEventListeners():void {
      _outSocket.addEventListener(Event.CONNECT, onOutConnect);
      _outSocket.addEventListener(Event.CLOSE, onOutClose);
      _outSocket.addEventListener(IOErrorEvent.IO_ERROR, onOutIOError);
      _outSocket.addEventListener(SecurityErrorEvent.SECURITY_ERROR,
                                  onOutSecError);
      _outSocket.addEventListener(OutputProgressEvent.OUTPUT_PROGRESS,
                                  onOutProgress);
    }

    private function removeOutSocketEventListeners():void {
      _outSocket.removeEventListener(Event.CONNECT, onOutConnect);
      _outSocket.removeEventListener(Event.CLOSE, onOutClose);
      _outSocket.removeEventListener(IOErrorEvent.IO_ERROR, onOutIOError);
      _outSocket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR,
                                     onOutSecError);
      _outSocket.removeEventListener(OutputProgressEvent.OUTPUT_PROGRESS,
                                     onOutProgress);
    }

    private function onOutConnect(e:Event):void {
      TestResults.appendDebugMsg("C2S socket connected.");
    }

    private function onOutClose(e:Event):void {
      TestResults.appendDebugMsg("C2S socket closed closed by the server.");
      closeOutSocket();
    }

    private function onOutIOError(e:IOErrorEvent):void {
      TestResults.appendErrMsg("IOError on C2S socket: " + e);
      _c2sTestSuccess = false;
      closeOutSocket();
      endTest();
    }

    private function onOutSecError(e:SecurityErrorEvent):void {
      TestResults.appendErrMsg("Security error on C2S socket: " + e);
      _c2sTestSuccess = false;
      closeOutSocket();
      endTest();
    }

    private function onOutProgress(e:OutputProgressEvent):void {
      if (_outSocket.bytesPending == 0) {
        _outSendCount++;
        if (_outSocket.connected) {
          sendData();
          return;
        } else {
          closeOutSocket();
        }
      }
    }

    /**
     * Function triggered when 10 sec of writing to the socket is complete.
     */
    private function onOutTimeout(e:TimerEvent):void {
      TestResults.appendDebugMsg("Timeout for sending data on C2S socket.");
      closeOutSocket();
    }

    /**
     * Function triggered when the server sends the TEST_START message to
     * indicate to the client that it should start sending data.
     */
    private function startTest():void {
      if (_ctlSocket.bytesAvailable < NDTConstants.MSG_HEADER_LENGTH)
        return;

      // Remove ctl socket listener so it does not interfere with the out socket
      // listeners.
      removeCtlSocketOnReceivedDataListener();

      TestResults.appendDebugMsg("C2S test: START_TEST stage.");

      // The server tells the client to start pumping out data.
      var msg:Message = new Message();
      if (msg.receiveMessage(_ctlSocket)
          != NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
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

      // Mark the start time of the test.
      _c2sTestDuration = getTimer();
      _outTimer.start();

      _testStage = SEND_DATA;
      TestResults.appendDebugMsg("C2S test: SEND_DATA stage.");
      sendData();
    }

    /**
     * Function that is called repeatedly to send data to the server through the
     * C2S socket.
    */
    private function sendData():void {
      _outSocket.writeBytes(_dataToSend, 0, _dataToSend.length);
      _outSocket.flush();
    }

    private function closeOutSocket():void {
      _outTimer.stop();
      _outTimer.removeEventListener(TimerEvent.TIMER, onOutTimeout);
      _c2sTestDuration = getTimer() - _c2sTestDuration;
      TestResults.appendDebugMsg(
          "C2S test lasted " + _c2sTestDuration + " msec.");

      _outBytesNotSent = _outSocket.bytesPending;
      // TODO(tiziana): Verify if it's necessary to check if the socket is
      // connected and to use the following commented code:
      //if (_outSocket.connected)
      //    _outBytesNotSent = _outSocket.bytesPending;
      //else
      //    _outBytesNotSent = 0;

      removeOutSocketEventListeners();
      try {
        _outSocket.close();
      } catch (e:IOError) {
        TestResults.appendErrMsg(
            "IO Error while closing C2S out socket: " + e);
      }
      addCtlSocketOnReceivedDataListener();

      _testStage = COMPUTE_THROUGHPUT;
      calculateThroughput();
    }

    /**
     * Function that is called to calculate the throughput once all data is sent
     * to the server
     */
    private function calculateThroughput():void {
      TestResults.appendDebugMsg("C2S test: COMPUTE_THROUGHPUT stage.");

      var outByteSent:Number = (
          _outSendCount * NDTConstants.PREDEFINED_BUFFER_SIZE
          + (NDTConstants.PREDEFINED_BUFFER_SIZE - _outBytesNotSent));
      TestResults.appendDebugMsg("C2S test sent " + outByteSent + " bytes.");

      var c2sSpeed:Number = (
          (outByteSent * NDTConstants.BYTES2BITS)
          / _c2sTestDuration);
      TestResults.ndt_test_results::c2sSpeed = c2sSpeed;
      TestResults.appendDebugMsg("C2S throughput computed by client is "
                                 + c2sSpeed.toFixed(2) + " kbps.");

      _testStage = COMPARE_SERVER;
      if (_ctlSocket.bytesAvailable > 0)
        compareWithServer();
    }

    /**
     * Function that receives the server computed value of the throughput and
     * stores it in the corresponding field.
     */
    private function compareWithServer():void {
      if (_ctlSocket.bytesAvailable <= NDTConstants.MSG_HEADER_LENGTH)
        return;

      TestResults.appendDebugMsg("C2S test: COMPARE_SERVER stage.");

      var msg:Message = new Message();
      if (msg.receiveMessage(_ctlSocket)
          != NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
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

      // Get throughput calculated by the server.
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

    /**
     * Function that adds the results to the output to be displayed and removes
     * all local Event Listeners.
     */
    private function finalizeTest():void {
      if (_ctlSocket.bytesAvailable < NDTConstants.MSG_HEADER_LENGTH)
        return;

      TestResults.appendDebugMsg("C2S test: FINALIZE_TEST stage.");

      var msg:Message = new Message();
      if (msg.receiveMessage(_ctlSocket)
          != NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
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

    /**
     * Function triggered when the test is complete, regardless of whether the
     * test completed successfully or not.
     */
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

