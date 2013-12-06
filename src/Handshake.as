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
  import flash.events.ProgressEvent;
  import flash.net.Socket;
  import flash.utils.ByteArray;
  import mx.resources.ResourceManager;
  import mx.utils.StringUtil;

  /**
   * This class handles the initial communication with the server before
   * starting the measurement tests.
   */
  public class Handshake {
    // Valid values for _testStage.
    private const KICK_CLIENTS:int = 0;
    private const SRV_QUEUE:int = 1;
    private const VERIFY_VERSION:int = 2;
    private const VERIFY_SUITE:int = 3;

    private var _callerObj:NDTPController;
    private var _ctlSocket:Socket;
    private var _testStage:int;
    private var _testsRequestByClient:int;
    // Has the client already received a wait message?
    private var _isNotFirstWaitFlag:Boolean;

    public function Handshake(ctlSocket:Socket, testsRequestByClient:int,
                              callerObject:NDTPController) {
      _callerObj = callerObject;
      _ctlSocket = ctlSocket;
      _testsRequestByClient = testsRequestByClient;

      _isNotFirstWaitFlag = false;  // No wait messages received yet.
    }

    public function run():void {
      addOnReceivedDataListener();

      var msgBody:ByteArray = new ByteArray();
      msgBody.writeByte(_testsRequestByClient);
      var msg:Message = new Message(MessageType.MSG_LOGIN, msgBody);
      if (!msg.sendMessage(_ctlSocket)) {
        failHandshake();
      }

      _testStage = KICK_CLIENTS;
      if (_ctlSocket.bytesAvailable > 0)
        kickOldClients();
    }

    private function addOnReceivedDataListener():void {
      _ctlSocket.addEventListener(ProgressEvent.SOCKET_DATA, onReceivedData);
    }

    private function removeOnReceivedDataListener():void {
      _ctlSocket.removeEventListener(ProgressEvent.SOCKET_DATA, onReceivedData);
    }

    private function onReceivedData(e:ProgressEvent):void {
      switch (_testStage) {
        case KICK_CLIENTS:    kickOldClients();
                              break;
        case SRV_QUEUE:       srvQueue();
                              break;
        case VERIFY_VERSION:  verifyVersion();
                              break;
        case VERIFY_SUITE:    verifySuite();
                              break;
      }
    }

    private function kickOldClients():void {
      if (_ctlSocket.bytesAvailable < NDTConstants.KICK_OLD_CLIENTS_MSG_LENGTH)
        return;

      TestResults.appendDebugMsg("Handshake: KICK_CLIENTS stage.");

      var msg:Message = new Message();
      if (!msg.receiveMessage(_ctlSocket, true)) {
        TestResults.appendErrMsg(ResourceManager.getInstance().getString(
            NDTConstants.BUNDLE_NAME, "unsupportedClient", null, Main.locale));
        failHandshake();
      }

      _testStage = SRV_QUEUE;
      // If KICK_CLIENTS and SRV_QUEUE messages arrive together at the client,
      // they trigger a single ProgressEvent.SOCKET_DATA event. In such case,
      // the following condition is needed to move to the next step.
      if (_ctlSocket.bytesAvailable > 0) {
        srvQueue();
      }
    }

    private function srvQueue():void {
      if (_ctlSocket.bytesAvailable < NDTConstants.SRV_QUEUE_MSG_LENGTH)
        return;

      TestResults.appendDebugMsg("Handshake: SRV_QUEUE stage.");

      // See https://code.google.com/p/ndt/issues/detail?id=101.
      var msg:Message = new Message();
      if (!msg.receiveMessage(_ctlSocket)) {
        TestResults.appendErrMsg(ResourceManager.getInstance().getString(
            NDTConstants.BUNDLE_NAME, "protocolError", null, Main.locale)
          + parseInt(new String(msg.body), 16) + " instead.");
        failHandshake();
      }
      if (msg.type != MessageType.SRV_QUEUE) {
        TestResults.appendErrMsg(ResourceManager.getInstance().getString(
            NDTConstants.BUNDLE_NAME, "loggingWrongMessage", null,
            Main.locale));
        failHandshake();
      }

      var waitFlagString:String = new String(msg.body);
      TestResults.appendDebugMsg("Wait flag received = " + waitFlagString);
      var waitFlag:int = parseInt(waitFlagString);

      // Handling different queued-client cases.
      switch(waitFlag) {
        case NDTConstants.SRV_QUEUE_TEST_STARTS_NOW:
          // No more waiting. Proceed.
          TestResults.appendDebugMsg("Finished waiting.");
          _testStage = VERIFY_VERSION;

          // If SRV_QUEUE and VERIFY_VERSION messages arrive together at the
          // client, they trigger a single ProgressEvent.SOCKET_DATA event. In
          // such case, the following condition is needed to move to the next
          // step.
          if(_ctlSocket.bytesAvailable > 0)
            verifyVersion();
          return;

        case NDTConstants.SRV_QUEUE_SERVER_FAULT:
          // Server fault. Fail.
          // TODO(tiziana): Change when issue #102 is fixed.
          // See https://code.google.com/p/ndt/issues/detail?id=102.
          TestResults.appendErrMsg(ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "serverFault", null, Main.locale));
          failHandshake();
          return;

        case NDTConstants.SRV_QUEUE_SERVER_BUSY:
          if (!_isNotFirstWaitFlag) {
            // Server busy. Fail.
            // TODO(tiziana): Change when issue #102 is fixed.
            // See https://code.google.com/p/ndt/issues/detail?id=102.
            TestResults.appendErrMsg(ResourceManager.getInstance().getString(
                NDTConstants.BUNDLE_NAME, "serverBusy",null, Main.locale));
            failHandshake();
          } else {
            // Server fault. Fail.
            // TODO(tiziana): Change when issue #102 is fixed.
            // See https://code.google.com/p/ndt/issues/detail?id=102.
            TestResults.appendErrMsg(ResourceManager.getInstance().getString(
                NDTConstants.BUNDLE_NAME, "serverFault", null, Main.locale));
            failHandshake();
          }
          return;

        case NDTConstants.SRV_QUEUE_SERVER_BUSY_60s:
          // Server busy for 60s. Fail.
          // TODO(tiziana): Change when issue #102 is fixed.
          // See https://code.google.com/p/ndt/issues/detail?id=102.
          TestResults.appendErrMsg(ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "serverBusy60s", null, Main.locale));
          failHandshake();
          return;

        case NDTConstants.SRV_QUEUE_HEARTBEAT:
          // Server sends signal to see if client is still alive.
          // Client should respond with a MSG_WAITING message.
          var msgBody:ByteArray = new ByteArray();
          msgBody.writeByte(_testsRequestByClient);
          msg = new Message(MessageType.MSG_WAITING, msgBody);
          if (!msg.sendMessage(_ctlSocket)) {
            failHandshake();
          }

        default:
          // Server sends the number of queued clients (== number of minutes
          // to wait before starting tests).
          // See https://code.google.com/p/ndt/issues/detail?id=103.
          TestResults.appendDebugMsg(
              ResourceManager.getInstance().getString(
                  NDTConstants.BUNDLE_NAME, "otherClient", null, Main.locale)
              + (waitFlag * 60)
              + ResourceManager.getInstance().getString(
                  NDTConstants.BUNDLE_NAME, "seconds", null, Main.locale));
          _isNotFirstWaitFlag = false;  // First message from server received.
      }
    }

    private function verifyVersion():void {
      if (_ctlSocket.bytesAvailable <= NDTConstants.MSG_HEADER_LENGTH)
        return;

      TestResults.appendDebugMsg("Handshake: VERIFY_VERSION stage.");

      var msg:Message = new Message();
      if (!msg.receiveMessage(_ctlSocket)) {
        TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(
                NDTConstants.BUNDLE_NAME, "protocolError", null, Main.locale)
            + parseInt(new String(msg.body), 16) + " instead.");
        failHandshake();
        return;
      }
      if (msg.type != MessageType.MSG_LOGIN) {
        TestResults.appendErrMsg(ResourceManager.getInstance().getString(
            NDTConstants.BUNDLE_NAME, "versionWrongMessage", null,
            Main.locale));
        failHandshake();
        return;
      }
      var receivedServerVersion:String = new String(msg.body);
      TestResults.appendDebugMsg("Server version: " + receivedServerVersion);
      // See https://code.google.com/p/ndt/issues/detail?id=104.
      if (receivedServerVersion != NDTConstants.EXPECTED_SERVER_VERSION)
        TestResults.appendDebugMsg(
            "The server version sent by the server is: "
            + receivedServerVersion
            + ", while the client expects: "
            + NDTConstants.EXPECTED_SERVER_VERSION);
      if (receivedServerVersion < NDTConstants.LAST_VALID_SERVER_VERSION) {
        TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(
                NDTConstants.BUNDLE_NAME, "incompatibleVersion",null,
                Main.locale));
        failHandshake();
        return;
      }

      _testStage = VERIFY_SUITE;
      // If VERIFY_VERSION and VERIFY_SUITE messages arrive together at the
      // client, they trigger a single ProgressEvent.SOCKET_DATA event. In such
      // case, the following condition is needed to move to the next step.
      if (_ctlSocket.bytesAvailable > 0) {
        verifySuite();
      }
    }

    private function verifySuite():void {
      if (_ctlSocket.bytesAvailable <= NDTConstants.MSG_HEADER_LENGTH)
        return;

      TestResults.appendDebugMsg("Handshake: VERIFY_SUITE stage.");

      var msg:Message = new Message();
      if (!msg.receiveMessage(_ctlSocket)) {
        TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(
                NDTConstants.BUNDLE_NAME, "protocolError", null, Main.locale)
            + parseInt(new String(msg.body), 16) + " instead");
        failHandshake();
        return;
      }
      if (msg.type != MessageType.MSG_LOGIN) {
        TestResults.appendErrMsg(ResourceManager.getInstance().getString(
            NDTConstants.BUNDLE_NAME, "testsuiteWrongMessage", null,
            Main.locale));
        return;
      }

      var confirmedTests:String = new String(msg.body);
      TestResults.ndt_test_results::testsConfirmedByServer =
          TestType.listToBitwiseOR(confirmedTests);

      TestResults.appendDebugMsg("Test suite: " + confirmedTests);
      endHandshake(StringUtil.trim(confirmedTests));
    }

    private function failHandshake():void {
      TestResults.appendDebugMsg("Handshake: FAIL.");

      removeOnReceivedDataListener();
      _callerObj.failNDTTest();
    }

    private function endHandshake(confirmedTests:String):void {
      TestResults.appendDebugMsg("Handshake: END.");

      removeOnReceivedDataListener();
      _callerObj.initiateTests(confirmedTests);
    }
  }
}

