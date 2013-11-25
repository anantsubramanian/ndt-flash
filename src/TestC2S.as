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
  import flash.events.Event;
  import flash.events.IOErrorEvent;
  import flash.events.OutputProgressEvent;
  import flash.events.ProgressEvent;
  import flash.events.SecurityErrorEvent;
  import flash.events.TimerEvent;
  import flash.errors.IOError;
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
    private static const CALC_THROUGHPUT:int = 3;
    private static const CMP_SERVER:int = 4;
    private static const FINALIZE_TEST:int = 5;
    private static const END_TEST:int = 6;

    private var _callerObj:NDTPController;
    private var _c2sTestSuccess:Boolean;
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
      _c2sTestDuration = 0.0;
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
        testPrepare();
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
        case PREPARE_TEST:  testPrepare();
                            break;
        case START_TEST:    testStart();
                            break;
        case CMP_SERVER:    compareWithServer();
                            break;
        case FINALIZE_TEST: finalizeTest();
                            break;
        case END_TEST:      endTest();
                            break;
      }
    }

    /**
     * Function that handles the TEST_PREPARE message sent by the server.
     * It fills the buffer ByteArray with data and creates a new Socket object
     * to connect to the port specified by the server.
     */
    private function testPrepare():void {
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

      var c2sPort:int = parseInt(new String(msg.body));
      _outSocket = new Socket(_serverHostname, c2sPort);
      addOutSocketEventListeners();

      _testStage = START_TEST;
      // If TEST_PREPARE and TEST_START messages arrive together at the client,
      // they trigger a single ProgressEvent.SOCKET_DATA event. In such case,
      // the following condition is needed to move to the next step.
      if (_ctlSocket.bytesAvailable > 0)
        testStart();
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
      TestResults.appendDebugMsg("C2S socket closed.");
      closeOutSocket();
    }

    private function onOutIOError(e:IOErrorEvent):void {
      TestResults.appendErrMsg("IOError on C2S socket: " + e);
      _c2sTestSuccess = false;
      removeOutSocketEventListeners();
      removeCtlSocketOnReceivedDataListener();
      endTest();
    }

    private function onOutSecError(e:SecurityErrorEvent):void {
      TestResults.appendErrMsg("Security error on C2S socket: " + e);
      _c2sTestSuccess = false;
      removeOutSocketEventListeners();
      removeCtlSocketOnReceivedDataListener();
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
     * Function triggered when the server sends the TEST_START message to
     * indicate to the client that it should start sending data.
     */
    private function testStart():void {
      // Remove ctl socket listener so it does not interfere with the out socket
      // listeners.
      removeCtlSocketOnReceivedDataListener();

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

      // Prepare the data to send to the server.
      for (var i:int = 0; i < NDTConstants.PREDEFINED_BUFFER_SIZE; i++) {
        _dataToSend.writeByte(i);
      }
      TestResults.appendDebugMsg(
          "Each message of the C2S test has " + _dataToSend.length + " bytes.");

      // Mark the start time of the test.
      _c2sTestDuration = getTimer();
      _outTimer = new Timer(NDTConstants.C2S_DURATION, 0);
      _outTimer.addEventListener(TimerEvent.TIMER, onOutTimeout);
      _outTimer.start();

      _outSendCount = 0;
      _testStage = SEND_DATA;
      sendData();
    }

    /**
     * Function triggered when 10 sec of writing to the socket is complete.
     */
    private function onOutTimeout(e:TimerEvent):void {
      closeOutSocket();
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
      _c2sTestDuration = getTimer() - _c2sTestDuration;
      TestResults.appendDebugMsg(
          "C2S test lasted " + _c2sTestDuration + " milliseconds.");

      _outBytesNotSent = _outSocket.bytesPending;
      // TODO(tiziana): Verify if the commented check is necessary.
      //if (_outSocket.connected)
      //    _outBytesNotSent = _outSocket.bytesPending;
      //else
      //    _outBytesNotSent = 0;

      removeOutSocketEventListeners();
      try {
        _outSocket.close();
      } catch (e:IOError) {
        TestResults.appendErrMsg(
            "IO Error while closing C2S Test socket : " + e);
      }
      addCtlSocketOnReceivedDataListener();

      _testStage = CALC_THROUGHPUT;
      calculateThroughput();
    }

    /**
     * Function that is called to calculate the throughput once all data is sent
     * to the server
     */
    private function calculateThroughput():void {
      var outByteSent:Number = (
          _outSendCount * NDTConstants.PREDEFINED_BUFFER_SIZE
          + (NDTConstants.PREDEFINED_BUFFER_SIZE - _outBytesNotSent));
      TestResults.appendDebugMsg("C2S test sent " + outByteSent + " bytes.");

      if (_c2sTestDuration == 0)
        _c2sTestDuration = 1;

      // Calculate C2S throughput (in kbps).
      var c2sSpeed:Number = (
          outByteSent * NDTConstants.BYTES2BITS / NDTConstants.SEC2MSEC
          / _c2sTestDuration);
      TestResults.ndt_test_results::c2sSpeed = c2sSpeed;
      TestResults.appendDebugMsg(
          "C2S throughput computed by client is " + c2sSpeed + " kbps.");

      _testStage = CMP_SERVER;
      if (_ctlSocket.bytesAvailable > 0)
        compareWithServer();
    }

    /**
     * Function that receives the server computed value of the throughput and
     * stores it in the corresponding field.
     */
    private function compareWithServer():void {
      var msg:Message = new Message();
      // TODO(tiziana): Check
      var PKT_WAIT_SIZE:int = 5;
      if (_ctlSocket.bytesAvailable <= PKT_WAIT_SIZE)
        return;

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

      // Get throughput calculated by the server
      var sc2sSpeedStr:String = new String(msg.body);
      var sc2sSpeed:Number = parseFloat(sc2sSpeedStr) / NDTConstants.SEC2MSEC;
      TestResults.ndt_test_results::sc2sSpeed = sc2sSpeed;

      TestResults.appendDebugMsg(
          "C2S throughput computed by client is "
          + (sc2sSpeed * NDTConstants.KBITS2BITS).toFixed(2) + "kb/s");

      _testStage = FINALIZE_TEST;
      if(_ctlSocket.bytesAvailable > 0)
        finalizeTest();
    }

    /**
     * Function that adds the results to the output to be displayed and removes
     * all local Event Listeners.
     */
    private function finalizeTest():void {
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

      removeCtlSocketOnReceivedDataListener();
      endTest();
    }

    /**
     * Function triggered when the test is complete, regardless of whether the
     * test completed successfully or not.
     */
    private function endTest():void {
      if (_c2sTestSuccess)
        TestResults.appendDebugMsg(ResourceManager.getInstance().getString(
            NDTConstants.BUNDLE_NAME, "done", null, Main.locale));
      else
        TestResults.appendDebugMsg(ResourceManager.getInstance().getString(
            NDTConstants.BUNDLE_NAME, "c2sThroughputFailed", null,
            Main.locale));

      NDTUtils.callExternalFunction("testCompleted", "ClientToServerThroughput",
                                    (!_c2sTestSuccess).toString());

      _callerObj.runTests();
    }
  }
}

