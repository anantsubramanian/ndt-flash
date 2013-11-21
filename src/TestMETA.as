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
    private static const TEST_PREPARE:int  = 0;
    private static const TEST_START:int    = 1;
    private static const SEND_DATA:int     = 2;
    private static const FINALIZE_TEST:int = 3;
    private static const ALL_COMPLETE:int  = 4;

    private var _callerObj:NDTPController;
    private var _ctlSocket:Socket;
    private var _metaTestSuccess:Boolean;
    private var _testStage:int;

    public function TestMETA(socket:Socket, callerObject:NDTPController) {
      _callerObj = callerObject;
      _ctlSocket = socket;
      _metaTestSuccess = true;  // Initially the test hasn't failed.
    }

    /**
     * Constructor that initializes local variables to their appropriate values
     * and triggers the testPrepare method if data is waiting to be read at the
     * socket.
     */
    public function run():void {
      _testStage = TEST_PREPARE;
      TestResults.appendDebugMsg(
          ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "startingTest", null, Main.locale) +
          ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "meta", null, Main.locale));
      NDTUtils.callExternalFunction("testStarted", "Meta");
      addResponseListener();
      // In case data arrived before starting the onReceiveData listener.
      if(_ctlSocket.bytesAvailable > 0)
        testPrepare();
    }

    private function addResponseListener():void {
      _ctlSocket.addEventListener(ProgressEvent.SOCKET_DATA, onResponse);
    }

    private function removeResponseListener():void {
      _ctlSocket.removeEventListener(ProgressEvent.SOCKET_DATA, onResponse);
    }

    private function onResponse(e:ProgressEvent):void {
      switch (_testStage) {
        case TEST_PREPARE:  testPrepare();
                            break;
        case TEST_START:    testStart();
                            break;
        case FINALIZE_TEST: finalizeTest();
                            break;
        case ALL_COMPLETE:  onComplete();
                            break;
      }
    }

    /**
     * Function that reads the TEST_PREPARE message sent by the server.
     */
    private function testPrepare():void {
      // TODO(tiziana): Check if it's necessary to call removeResponseListener()
      // at this point and if it's necessary to call addResponseListener() after
      // _testStage = TEST_START.
      TestResults.appendDebugMsg(
          ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "sendingMetaInformation", null,
              Main.locale));
      TestResults.ndt_test_results::ndtTestStatus = "sendingMetaInformation";

      var msg:Message = new Message();
      if (msg.receiveMessage(_ctlSocket) !=
          NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
        TestResults.appendErrMsg(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "protocolError", null, Main.locale)
          + parseInt(new String(msg.body), 16) + " instead.");
        _metaTestSuccess = false;
        onComplete();
        return;
      }

      // Server must start with a TEST_PREPARE message.
      if (msg.type != MessageType.TEST_PREPARE) {
        TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(
                NDTConstants.BUNDLE_NAME, "metaWrongMessage", null,
                Main.locale));
        if (msg.type == MessageType.MSG_ERROR) {
          TestResults.appendErrMsg("ERROR MSG: "
                                   + parseInt(new String(msg.body), 16));
        }
        _metaTestSuccess = false;
        onComplete();
        return;
      }
      _testStage = TEST_START;
      // In case data arrived before starting the onReceiveData listener.
      if (_ctlSocket.bytesAvailable > 0)
        testStart();
    }

    /**
     * Function triggered when the server sends the TEST_START message to
     * indicate that the client should start sending META data.
     */
    private function testStart():void {
      // TODO(tiziana): Check if it's necessary to call removeResponseListener()
      // at this point and if it's necessary to call addResponseListener() after
      // _testStage = FINALIZE_TEST.
      var msg:Message = new Message();
      if (msg.receiveMessage(_ctlSocket) !=
          NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
        TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(
                NDTConstants.BUNDLE_NAME, "protocolError", null, Main.locale)
          + parseInt(new String(msg.body), 16) + " instead.");
        _metaTestSuccess = false;
        return onComplete();
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
        onComplete();
        return;
      }
      _testStage = SEND_DATA;
      sendData();
    }

    /**
     * Function that sends META data to the server.
     */
    private function sendData():void {
      // As a response to the server's TEST_START message, the client responds
      // with TEST_MSG type message.
      var bodyToSend:ByteArray = new ByteArray();

      bodyToSend.writeUTFBytes(new String(
          NDTConstants.META_CLIENT_OS + ":" + Capabilities.os));
      Message.sendMessage(_ctlSocket, MessageType.TEST_MSG, bodyToSend);

      bodyToSend.clear();
      bodyToSend.writeUTFBytes(new String(
          NDTConstants.META_CLIENT_BROWSER + ":" + UserAgentTools.getBrowser(
              TestResults.ndt_test_results::userAgent)[2]));
      Message.sendMessage(_ctlSocket, MessageType.TEST_MSG, bodyToSend);

      bodyToSend.clear();
      bodyToSend.writeUTFBytes(new String(
          NDTConstants.META_CLIENT_VERSION + ":"
          + NDTConstants.CLIENT_VERSION));
      Message.sendMessage(_ctlSocket, MessageType.TEST_MSG, bodyToSend);

      bodyToSend.clear();
      bodyToSend.writeUTFBytes(new String(
          NDTConstants.META_CLIENT_APPLICATION + ":" + NDTConstants.CLIENT_ID));

      // Client can send any number of such meta data in a TEST_MSG format and
      // signal the send of the transmission using an empty TEST_MSG.
      Message.sendMessage(_ctlSocket, MessageType.TEST_MSG, new ByteArray());

      _testStage = FINALIZE_TEST;
      if (_ctlSocket.bytesAvailable > 0)
        finalizeTest();
    }

    /**
     * Function that is called when all the data to send to the server has been
     * sent.
     */
    private function finalizeTest():void {
      // Server closes the META test session by sending a TEST_FINALIZE message.
      var msg:Message = new Message();
      if (msg.receiveMessage(_ctlSocket) !=
          NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
        TestResults.appendErrMsg(
          ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "protocolError", null, Main.locale)
          + parseInt(new String(msg.body), 16) + " instead.");
        _metaTestSuccess = false;
        onComplete();
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
        onComplete();
        return;
      }
      _metaTestSuccess = true;
      onComplete();
      return;
    }

    /**
     * Function triggered when the test is complete, regardless of whether the
     * test completed successfully or not.
     */
    private function onComplete():void {
      // Display status as "complete" and assign status.
      if (_metaTestSuccess)
        TestResults.appendDebugMsg(ResourceManager.getInstance().getString(
            NDTConstants.BUNDLE_NAME, "done", null, Main.locale));
      else
        TestResults.appendDebugMsg(ResourceManager.getInstance().getString(
            NDTConstants.BUNDLE_NAME, "metaFailed", null, Main.locale));

      TestResults.ndt_test_results::ndtTestStatus = "done";

      removeResponseListener();
      NDTUtils.callExternalFunction(
          "testCompleted", "Meta", (!_metaTestSuccess).toString());
      _callerObj.runTests();
    }
  }
}

