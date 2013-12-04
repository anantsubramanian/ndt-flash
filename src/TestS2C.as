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
  import flash.utils.ByteArray;
  import flash.utils.getTimer;
  import flash.utils.Timer;
  import mx.resources.ResourceManager;

  /**
   * This class performs the Server-to-Client throughput test.
   */
  public class TestS2C {
    // Timer for single read operation.
    private const READ_TIMEOUT:int = 15000; // 15sec

    // Valid values for _testStage.
    private static const PREPARE_TEST:int = 0;
    private static const START_TEST:int = 1;
    private static const RECEIVE_DATA:int = 2;
    private static const COMPARE_SERVER:int = 3;
    private static const COMPUTE_THROUGHPUT:int = 4;
    private static const GET_WEB100:int = 5;
    private static const END_TEST:int = 6;

    private var _callerObj:NDTPController;
    private var _ctlSocket:Socket;
    private var _s2cByteCount:int;
    private var _s2cSocket:Socket;
    private var _s2cTimer:Timer;
    private var _readTimer:Timer;
    private var _receivedData:ByteArray;
      // Time to send data to client on the S2C socket.
    private var _s2cTestDuration:Number;
    private var _s2cTestSuccess:Boolean;
    private var _serverHostname:String;
    private var _testStage:int;
    private var _web100VarResult:String;


    public function TestS2C(ctlSocket:Socket, serverHostname:String,
                            callerObj:NDTPController) {
      _callerObj = callerObj;
      _ctlSocket = ctlSocket;
      _serverHostname = serverHostname;

      _s2cTestSuccess = true;  // Initially the test has not failed.
      _s2cTestDuration = 0;
      _s2cByteCount = 0;
      _receivedData = new ByteArray();
      _web100VarResult = "";
    }

    public function run():void {
      TestResults.appendDebugMsg(
          ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "startingTest", null, Main.locale) +
          ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "s2cThroughput", null, Main.locale))
      NDTUtils.callExternalFunction("startTested", "ServerToClientThroughput");

      addCtlSocketOnReceivedDataListener();
      _testStage = PREPARE_TEST;
      // In case data arrived before starting the ProgressEvent.SOCKET_DATA
      // listener.
      if (_ctlSocket.bytesAvailable > 0) {
        prepareTest();
      }
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
        case GET_WEB100:     getWeb100Vars();
                             break;
        case END_TEST:       endTest();
                             break;
      }
    }

    private function prepareTest():void {
      if (_ctlSocket.bytesAvailable <= NDTConstants.MSG_HEADER_LENGTH)
        return;

      TestResults.appendDebugMsg("S2C test: PREPARE_TEST stage.");
      TestResults.appendDebugMsg(
        ResourceManager.getInstance().getString(
            NDTConstants.BUNDLE_NAME, "runningInboundTest", null, Main.locale));
      TestResults.ndt_test_results::ndtTestStatus = "runningInboundTest";

      var msg:Message = new Message();
      if (msg.receiveMessage(_ctlSocket)
          != NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
        TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(
                NDTConstants.BUNDLE_NAME, "protocolError", null, Main.locale)
            + parseInt(new String(msg.body), 16) + " instead.");
        _s2cTestSuccess = false;
        endTest();
        return;
      }

      if (msg.type != MessageType.TEST_PREPARE) {
        TestResults.appendErrMsg(ResourceManager.getInstance().getString(
            NDTConstants.BUNDLE_NAME, "inboundWrongMessage", null,
            Main.locale));
        if (msg.type == MessageType.MSG_ERROR) {
          TestResults.appendErrMsg(
              "ERROR MESSAGE : " + parseInt(new String(msg.body), 16));
        }
        _s2cTestSuccess = false;
        endTest();
        return;
      }

      var s2cPort:int = parseInt(new String(msg.body));
      _s2cSocket = new Socket();
      addS2CSocketEventListeners();
      try {
        _s2cSocket.connect(_serverHostname, s2cPort);
      } catch(e:IOError) {
        TestResults.appendErrMsg("S2C socket connect IO error: " + e);
        _s2cTestSuccess = false;
        endTest();
        return;
      } catch(e:SecurityError) {
        TestResults.appendErrMsg("S2C socket connect security error: " + e);
        _s2cTestSuccess = false;
        endTest();
        return;
      }
      _readTimer = new Timer(READ_TIMEOUT);
      _readTimer.addEventListener(TimerEvent.TIMER, onS2CTimeout);
      _s2cTimer = new Timer(NDTConstants.S2C_DURATION);
      _s2cTimer.addEventListener(TimerEvent.TIMER, onS2CTimeout);

      _testStage = START_TEST;
      // If TEST_PREPARE and TEST_START messages arrive together at the client,
      // they trigger a single ProgressEvent.SOCKET_DATA event. In such case,
      // the following condition is needed to move to the next step.
      if (_ctlSocket.bytesAvailable > 0)
        startTest();
    }

    private function addS2CSocketEventListeners():void {
      _s2cSocket.addEventListener(Event.CONNECT, onS2CConnect);
      _s2cSocket.addEventListener(Event.CLOSE, onS2CClose);
      _s2cSocket.addEventListener(IOErrorEvent.IO_ERROR, onS2CError);
      _s2cSocket.addEventListener(SecurityErrorEvent.SECURITY_ERROR,
                                 onS2CSecError);
      _s2cSocket.addEventListener(ProgressEvent.SOCKET_DATA, onS2CReceivedData);
    }

    private function removeS2CSocketEventListeners():void {
      _s2cSocket.removeEventListener(Event.CONNECT, onS2CConnect);
      _s2cSocket.removeEventListener(Event.CLOSE, onS2CClose);
      _s2cSocket.removeEventListener(IOErrorEvent.IO_ERROR, onS2CError);
      _s2cSocket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR,
                                    onS2CSecError);
      _s2cSocket.removeEventListener(ProgressEvent.SOCKET_DATA,
                                    onS2CReceivedData);
    }

    private function onS2CConnect(e:Event):void {
      TestResults.appendDebugMsg("S2C socket connected.");
    }

    private function onS2CClose(e:Event):void {
      TestResults.appendDebugMsg("S2C socket closed by the server.");
      closeS2CSocket();
    }

    private function onS2CError(e:IOErrorEvent):void {
      TestResults.appendErrMsg("IOError on S2C socket: : " + e);
      _s2cTestSuccess = false;
      closeS2CSocket();
      endTest();
    }

    private function onS2CSecError(e:SecurityErrorEvent):void {
      TestResults.appendErrMsg("Security error on S2C socket: " + e);
      _s2cTestSuccess = false;
      closeS2CSocket();
      endTest();
    }

    private function onS2CReceivedData(e:ProgressEvent):void {
      _readTimer.stop();
      _readTimer.reset();
      _readTimer.start();
      receiveData();
    }

    private function startTest():void {
      if (_ctlSocket.bytesAvailable < NDTConstants.MSG_HEADER_LENGTH)
        return;

      TestResults.appendDebugMsg("S2C test: START_TEST stage.");
      // Remove Control socket listener so it does not interfere with the S2C
      // socket listeners.
      removeCtlSocketOnReceivedDataListener();

      var msg:Message = new Message();
      if (msg.receiveMessage(_ctlSocket)
          != NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
        // See https://code.google.com/p/ndt/issues/detail?id=105
        TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(
                NDTConstants.BUNDLE_NAME, "protocolError", null, Main.locale)
            + parseInt(new String(msg.body), 16) + " instead");
        _s2cTestSuccess = false;
        endTest();
        return;
      }
      if (msg.type != MessageType.TEST_START) {
        // See https://code.google.com/p/ndt/issues/detail?id=105
        TestResults.appendErrMsg(ResourceManager.getInstance().getString(
            NDTConstants.BUNDLE_NAME, "inboundWrongMessage", null, Main.locale));
        if (msg.type == MessageType.MSG_ERROR) {
          TestResults.appendErrMsg("ERROR MSG : "
                                   + parseInt(new String(msg.body), 16));
        }
        _s2cTestSuccess = false;
        endTest();
        return;
      }

      // Mark the start time of the test.
      _s2cTestDuration = getTimer();
      _readTimer.start();
      _s2cTimer.start();

      _testStage = RECEIVE_DATA;
      TestResults.appendDebugMsg("S2C test: RECEIVE_DATA stage.");
      if (_s2cSocket.bytesAvailable > 0)
        receiveData();
    }

    private function onS2CTimeout(e:TimerEvent):void {
      TestResults.appendDebugMsg("Timeout for receiving data on S2C socket.");
      closeS2CSocket();
    }

    /**
     * Function that is called repeatedly by the S2C socket response listener
     * for the duration of the test. It processes and keeps track of the total
     * bytes received from the server. The test only goes past this stage if:
     * 1. All data was successfully received.
     * 2. A read timeout (15s) occured on S2C socket.
     * 3. More than 14.5 seconds have passed since the beginning of the test.
     */
    private function receiveData():void {
      var readBytes:int = 0;
      while ((readBytes = NDTUtils.readBytes(
          _s2cSocket, _receivedData, 0, NDTConstants.PREDEFINED_BUFFER_SIZE))
          > 0) {
        _s2cByteCount += readBytes;
      }
    }

    private function closeS2CSocket():void {
      _s2cTimer.stop();
      _readTimer.stop();
      _readTimer.removeEventListener(TimerEvent.TIMER, onS2CTimeout);
      _s2cTimer.removeEventListener(TimerEvent.TIMER, onS2CTimeout);
      _s2cTestDuration = getTimer() - _s2cTestDuration;
      TestResults.appendDebugMsg(
          "S2C test lasted " + _s2cTestDuration + " msec.");

      removeCtlSocketOnReceivedDataListener();
      try {
        _s2cSocket.close();
        TestResults.appendDebugMsg("S2C socket closed by the client.");

      } catch (e:IOError) {
        TestResults.appendErrMsg(
            "IO Error while closing S2C socket: " + e);
      }
      addCtlSocketOnReceivedDataListener();

      _testStage = COMPARE_SERVER;
      if (_ctlSocket.bytesAvailable > 0)
        compareWithServer();
    }

    private function compareWithServer():void {
      if (_ctlSocket.bytesAvailable <= NDTConstants.MSG_HEADER_LENGTH)
        return;

      TestResults.appendDebugMsg("S2C test: COMPARE_SERVER stage.");

      var msg:Message = new Message();
      if (msg.receiveMessage(_ctlSocket)
          != NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
        TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(
                NDTConstants.BUNDLE_NAME, "protocolError", null, Main.locale)
          + parseInt(new String(msg.body), 16) + " instead.");
        _s2cTestSuccess = false;
        endTest();
        return;
      }

      if (msg.type != MessageType.TEST_MSG) {
        TestResults.appendErrMsg(ResourceManager.getInstance().getString(
            NDTConstants.BUNDLE_NAME, "inboundWrongMessage", null,
            Main.locale));
        if (msg.type == MessageType.MSG_ERROR) {
          TestResults.appendErrMsg("ERROR MSG : "
                                   + parseInt(new String(msg.body), 16));
        }
        _s2cTestSuccess = false;
        endTest();
        return;
      }

      var msgBody:String = new String(msg.body);
      var msgFields:Array = msgBody.split(" ");
      if (msgFields.length != 3) {
        TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(
                NDTConstants.BUNDLE_NAME, "inboundWrongMessage", null,
                Main.locale)
            + "Message received: " + msgBody);
        _s2cTestSuccess = false;
        endTest();
        return;
      }

      var sc2sSpeed:Number = parseFloat(msgFields[0]);
      var sSendQueue:int = parseInt(msgFields[1]);
      var sBytes:Number = parseFloat(msgFields[2]);
      if (isNaN(sc2sSpeed) || isNaN(sSendQueue) || isNaN(sBytes)) {
        TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(
                NDTConstants.BUNDLE_NAME, "inboundWrongMessage", null,
                Main.locale)
            + "Message received: " + msgBody);
        _s2cTestSuccess = false;
        endTest();
        return;
      }

      sc2sSpeed = sc2sSpeed / NDTConstants.SEC2MSEC * NDTConstants.KBITS2BITS;
      TestResults.ndt_test_results::ss2cSpeed = sc2sSpeed;
      TestResults.appendDebugMsg("S2C throughput computed by the server is "
                                 + sc2sSpeed.toFixed(2) + "kbps");

      _testStage = COMPUTE_THROUGHPUT;
      calculateThroughput();
    }

    private function calculateThroughput():void {
      TestResults.appendDebugMsg("S2C test: COMPUTE_THROUGHPUT stage.");

      var s2cSpeed:Number = (
          ( _s2cByteCount * NDTConstants.BYTES2BITS)
          / _s2cTestDuration);
      TestResults.ndt_test_results::s2cSpeed = s2cSpeed;
      TestResults.appendDebugMsg("S2C throughput computed by the client is "
                                 + s2cSpeed.toFixed(2) + " kbps.");

      var sendData:ByteArray = new ByteArray();
      sendData.writeFloat(s2cSpeed);
      TestResults.appendDebugMsg(
          "Sending '" + s2cSpeed + "' back to the server.");

      var msgToSend:Message = new Message(MessageType.TEST_MSG, _receivedData);
      if (!msgToSend.sendMessage(_ctlSocket)) {
        _s2cTestSuccess = false;
        endTest();
        return;
      }

      _readTimer = new Timer(READ_TIMEOUT);
      _readTimer.addEventListener(TimerEvent.TIMER, onWeb100ReadTimeout);
      _readTimer.start();
      _testStage = GET_WEB100;
      TestResults.appendDebugMsg("S2C test: GET_WEB100 stage.");
      if (_ctlSocket.bytesAvailable > 0) {
        getWeb100Vars();
      }
    }

    private function onWeb100ReadTimeout(e:TimerEvent):void {
      TestResults.appendErrMsg("Timeout when reading web100 variables.");
      _readTimer.removeEventListener(TimerEvent.TIMER, onWeb100ReadTimeout);

      _testStage = END_TEST;
      if (_ctlSocket.bytesAvailable > 0) {
        endTest();
      }
    }

    /**
     * Function that gets all the web100 variables as name-value string pairs.
     * It is called multiple times by the response listener of the Control
     * socket and adds more data to _web100VarResult every call.
     */
    private function getWeb100Vars():void {
      if (_ctlSocket.bytesAvailable < NDTConstants.MSG_HEADER_LENGTH)
        return;

      var msg:Message = new Message();
      while (_ctlSocket.bytesAvailable > 0) {
        if (msg.receiveMessage(_ctlSocket)
            != NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
          TestResults.appendErrMsg(
              ResourceManager.getInstance().getString(
                  NDTConstants.BUNDLE_NAME, "protocolError", null, Main.locale)
              + parseInt(new String(msg.body), 16) + " instead.");
          _s2cTestSuccess = false;
          endTest();
          return;
        }

        if (msg.type == MessageType.TEST_FINALIZE) {
          // All web100 variables have been sent by the server.
          _readTimer.stop();
          _readTimer.removeEventListener(TimerEvent.TIMER, onWeb100ReadTimeout);
          _s2cTestSuccess = true;
          endTest();
          return;
        }

        if (msg.type != MessageType.TEST_MSG) {
          TestResults.appendErrMsg(ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "inboundWrongMessage", null,
              Main.locale));
          if (msg.type == MessageType.MSG_ERROR) {
            TestResults.appendErrMsg("ERROR MSG : "
                                     + parseInt(new String(msg.body), 16));
          }
          _readTimer.stop();
          _readTimer.removeEventListener(TimerEvent.TIMER, onWeb100ReadTimeout);
          _s2cTestSuccess = false;
          endTest();
          return;
        }
        _web100VarResult += new String(msg.body);
      }
    }

    private function endTest():void {
      TestResults.ndt_test_results::s2cTestResults = _web100VarResult;
      removeCtlSocketOnReceivedDataListener();

      TestResults.appendDebugMsg("S2C test: END_TEST stage.");

      if (_s2cTestSuccess)
         TestResults.appendDebugMsg(
             ResourceManager.getInstance().getString(
                 NDTConstants.BUNDLE_NAME, "s2cThroughput", null, Main.locale)
             + " test " + ResourceManager.getInstance().getString(
                 NDTConstants.BUNDLE_NAME, "done", null, Main.locale));
      else
        TestResults.appendDebugMsg(ResourceManager.getInstance().getString(
            NDTConstants.BUNDLE_NAME, "s2cThroughputFailed", null,
            Main.locale));

      TestResults.ndt_test_results::s2cTestSuccess = _s2cTestSuccess;
      TestResults.ndt_test_results::ndtTestStatus = "done";
      NDTUtils.callExternalFunction(
          "testCompleted", "ServerToClientThroughput",
          (!_s2cTestSuccess).toString());

      _callerObj.runTests();
    }
  }
}

