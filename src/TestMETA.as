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
  import flash.utils.ByteArray;
  import flash.system.Capabilities;
  import mx.resources.ResourceManager;

  /**
   * This class performs the META test. The META test allows the Client
   * to send additional information to the server that is included with
   * the final set of results.
   */
  public class TestMETA {
    // Valid values for _testStage.
    private static const PREPARE_TEST:int  = 0;
    private static const START_TEST:int    = 1;
    private static const SEND_DATA:int     = 2;
    private static const FINALIZE_TEST:int = 3;
    private static const END_TEST:int  = 4;

    private var _callerObj:NDTPController;
    private var _ctlSocket:Socket;
    private var _metaTestSuccess:Boolean;
    private var _testStage:int;

    public function TestMETA(ctlSocket:Socket, callerObject:NDTPController) {
      _callerObj = callerObject;
      _ctlSocket = ctlSocket;

      _metaTestSuccess = true;  // Initially the test has not failed.
    }

    public function run():void {
      TestResults.appendDebugMsg(
          ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "startingTest", null, Main.locale) +
          ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "meta", null, Main.locale));
      NDTUtils.callExternalFunction("testStarted", "Meta");

      addOnReceivedDataListener();
      _testStage = PREPARE_TEST;
      // In case data arrived before starting the ProgressEvent.SOCKET_DATA
      // listener.
      if(_ctlSocket.bytesAvailable > 0)
        prepareTest();
    }

    private function addOnReceivedDataListener():void {
      _ctlSocket.addEventListener(ProgressEvent.SOCKET_DATA, onReceivedData);
    }

    private function removeResponseListener():void {
      _ctlSocket.removeEventListener(ProgressEvent.SOCKET_DATA, onReceivedData);
    }

    private function onReceivedData(e:ProgressEvent):void {
      switch (_testStage) {
        case PREPARE_TEST:  prepareTest();
                            break;
        case START_TEST:    startTest();
                            break;
        case FINALIZE_TEST: finalizeTest();
                            break;
        case END_TEST:      endTest();
                            break;
      }
    }

    /**
     * Function that reads the TEST_PREPARE message sent by the server.
     */
    private function prepareTest():void {
      if (_ctlSocket.bytesAvailable < NDTConstants.MSG_HEADER_LENGTH)
        return;

      TestResults.appendDebugMsg("META test: PREPARE_TEST stage.");
      TestResults.appendDebugMsg(
          ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "sendingMetaInformation", null,
              Main.locale));
      TestResults.ndt_test_results::ndtTestStatus = "sendingMetaInformation";

      var msg:Message = new Message();
      if (msg.receiveMessage(_ctlSocket)
          != NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
        TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(
                NDTConstants.BUNDLE_NAME, "protocolError", null, Main.locale)
            + parseInt(new String(msg.body), 16) + " instead.");
        _metaTestSuccess = false;
        endTest();
        return;
      }

      if (msg.type != MessageType.TEST_PREPARE) {
        TestResults.appendErrMsg(ResourceManager.getInstance().getString(
            NDTConstants.BUNDLE_NAME, "metaWrongMessage", null, Main.locale));
        if (msg.type == MessageType.MSG_ERROR) {
          TestResults.appendErrMsg("ERROR MSG: "
                                   + parseInt(new String(msg.body), 16));
        }
        _metaTestSuccess = false;
        endTest();
        return;
      }

      _testStage = START_TEST;
      // If TEST_PREPARE and TEST_START messages arrive together at the client,
      // they trigger a single ProgressEvent.SOCKET_DATA event. In such case,
      // the following condition is needed to move to the next step.
      if (_ctlSocket.bytesAvailable > 0)
        startTest();
    }

    /**
     * Function triggered when the server sends the TEST_START message to
     * indicate that the client should start sending META data.
     */
    private function startTest():void {
      if (_ctlSocket.bytesAvailable < NDTConstants.MSG_HEADER_LENGTH)
        return;

      TestResults.appendDebugMsg("META test: START_TEST stage.");

      var msg:Message = new Message();
      if (msg.receiveMessage(_ctlSocket)
          != NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
        TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(
                NDTConstants.BUNDLE_NAME, "protocolError", null, Main.locale)
          + parseInt(new String(msg.body), 16) + " instead.");
        _metaTestSuccess = false;
        endTest();
        return;
      }
      if (msg.type != MessageType.TEST_START) {
        TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(
                NDTConstants.BUNDLE_NAME, "metaWrongMessage", null,
                Main.locale));
        if (msg.type == MessageType.MSG_ERROR) {
          TestResults.appendErrMsg(
              "ERROR MSG: " + parseInt(new String(msg.body), 16));
        }
        _metaTestSuccess = false;
        endTest();
        return;
      }

      _testStage = SEND_DATA;
      sendData();
    }

    /**
     * Function that sends META data to the server.
     */
    private function sendData():void {
      TestResults.appendDebugMsg("META test: SEND_DATA stage.");

      // As a response to the server's TEST_START message, the client responds
      // with TEST_MSG type message.
      var bodyToSend:ByteArray = new ByteArray();

      bodyToSend.writeUTFBytes(new String(
          NDTConstants.META_CLIENT_OS + ":" + Capabilities.os));
      var msg:Message = new Message(MessageType.TEST_MSG, bodyToSend);
      if (!msg.sendMessage(_ctlSocket)) {
        _metaTestSuccess = false;
        endTest();
        return;
      }

      bodyToSend.clear();
      bodyToSend.writeUTFBytes(new String(
          NDTConstants.META_CLIENT_BROWSER + ":" + UserAgentTools.getBrowser(
              TestResults.ndt_test_results::userAgent)[2]));
      msg = new Message(MessageType.TEST_MSG, bodyToSend);
      if (!msg.sendMessage(_ctlSocket)) {
        _metaTestSuccess = false;
        endTest();
        return;
      }

      bodyToSend.clear();
      bodyToSend.writeUTFBytes(new String(
          NDTConstants.META_CLIENT_VERSION + ":"
          + NDTConstants.CLIENT_VERSION));
      msg = new Message(MessageType.TEST_MSG, bodyToSend);
      if (!msg.sendMessage(_ctlSocket)) {
        _metaTestSuccess = false;
        endTest();
        return;
      }

      bodyToSend.clear();
      bodyToSend.writeUTFBytes(new String(
          NDTConstants.META_CLIENT_APPLICATION + ":" + NDTConstants.CLIENT_ID));

      // Client can send any number of such meta data in a TEST_MSG format and
      // signal the send of the transmission using an empty TEST_MSG.
      msg = new Message(MessageType.TEST_MSG, new ByteArray());
      if (!msg.sendMessage(_ctlSocket)) {
        _metaTestSuccess = false;
        endTest();
        return;
      }

      _testStage = FINALIZE_TEST;
      // The following check is probably not necessary. Added anyway, in case
      // the TEST_FINALIZE message does not trigger onReceivedData.
      if (_ctlSocket.bytesAvailable > 0)
        finalizeTest();
    }

    /**
     * Function that is called when all the data to send to the server has been
     * sent.
     */
    private function finalizeTest():void {
      if (_ctlSocket.bytesAvailable < NDTConstants.MSG_HEADER_LENGTH)
        return;

      TestResults.appendDebugMsg("META test: FINALIZE_TEST stage.");

      var msg:Message = new Message();
      if (msg.receiveMessage(_ctlSocket)
          != NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
        TestResults.appendErrMsg(
          ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "protocolError", null, Main.locale)
          + parseInt(new String(msg.body), 16) + " instead.");
        _metaTestSuccess = false;
        endTest();
        return;
      }
      if (msg.type != MessageType.TEST_FINALIZE) {
        TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(
                NDTConstants.BUNDLE_NAME,"metaWrongMessage", null,
                Main.locale));
        if (msg.type == MessageType.MSG_ERROR) {
          TestResults.appendErrMsg(
              "ERROR MSG: " + parseInt(new String(msg.body), 16));
        }
        _metaTestSuccess = false;
        endTest();
        return;
      }
      _metaTestSuccess = true;
      endTest();
      return;
    }

    /**
     * Function triggered when the test is complete, regardless of whether the
     * test completed successfully or not.
     */
    private function endTest():void {
      TestResults.appendDebugMsg("META test: END_TEST stage.");
      removeResponseListener();

      if (_metaTestSuccess)
        TestResults.appendDebugMsg(
             ResourceManager.getInstance().getString(
                 NDTConstants.BUNDLE_NAME, "meta", null, Main.locale)
            + " test " + ResourceManager.getInstance().getString(
                NDTConstants.BUNDLE_NAME, "done", null, Main.locale));
      else
        TestResults.appendDebugMsg(ResourceManager.getInstance().getString(
            NDTConstants.BUNDLE_NAME, "metaFailed", null, Main.locale));

      TestResults.ndt_test_results::ndtTestStatus = "done";
      NDTUtils.callExternalFunction(
          "testCompleted", "Meta", (!_metaTestSuccess).toString());

      _callerObj.runTests();
    }
  }
}

