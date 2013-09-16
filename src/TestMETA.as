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
    // constants declaration section
    private static const MIN_MSG_SIZE:int  = 1;
    private static const TEST_PREPARE:int  = 0;
    private static const TEST_START:int    = 1;
    private static const SEND_DATA:int     = 2;
    private static const FINALIZE_TEST:int = 3;
    private static const ALL_COMPLETE:int  = 4;
        
    // variables declaration section
    private var ctlSocket:Socket;
    private var protocolObj:Protocol;
    private var msg:Message;
    private var callerObj:MainFrame;
    private var clientId:String;
    private static var comStage:int;
    private static var metaTest:Boolean;
    
    // Event listener function
    private function onResponse(e:ProgressEvent):void {
      switch (comStage) {
        
        case TEST_PREPARE:  testPrepare();
                            break;
        case TEST_START:    testStart();
                            break;
        case FINALIZE_TEST: finalizeTest();
                            break;
      }
      if(comStage == ALL_COMPLETE)
        onComplete();
    }
    
    private function addResponseListener():void {
      ctlSocket.addEventListener(ProgressEvent.SOCKET_DATA, onResponse);
    }
    
    private function removeResponseListener():void {
      ctlSocket.removeEventListener(ProgressEvent.SOCKET_DATA, onResponse);
    }
    
    /**
     * Function triggered when the test is complete, regardless of whether the
     * test completed successfully or not.
     */
    private function onComplete():void {
      removeResponseListener();
      callerObj.testNo++;
      callerObj.runTests(protocolObj);
    }
    
    /** 
     * Function that reads the TEST_PREPARE message sent by the server.
     */    
    private function testPrepare():void {
      TestResults.appendConsoleOutput(
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                        "sendingMetaInformation",
                                        null, Main.locale) + " ");
      TestResults.appendStatsText(
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                        "sendingMetaInformation",
                                        null, Main.locale) + " ");
      TestResults.appendEmailText(
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                        "sendingMetaInformation",
                                        null, Main.locale) + " ");
      TestResults.set_pub_status("sendingMetaInformation");
      
      // Server starts with a TEST_PREPARE messsage.
      if (msg.receiveMessage(protocolObj.ctlSocket) !=
          NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
        TestResults.appendErrMsg(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "protocolError", null, Main.locale)
          + parseInt(new String(msg.body), 16) + " instead\n");
        metaTest = false;
        onComplete();
        return;
      }
      if (msg.type != MessageType.TEST_PREPARE) {
        // any other message type is 'wrong'
        TestResults.appendErrMsg(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "metaWrongMessage",
                                          null, Main.locale) + "\n");
        if (msg.type == MessageType.MSG_ERROR) {
          TestResults.appendErrMsg("ERROR MSG: "
                                   + parseInt(new String(msg.body), 16)
                                   + "\n");
        }
        metaTest = false;
        onComplete();
        return;
      }
      comStage = TEST_START;
      if (ctlSocket.bytesAvailable > MIN_MSG_SIZE)
        testStart();
    }
    
    /**
     * Function triggered when the server sends the TEST_START message to 
     * indicate that the client should start sending META data.
     */
    private function testStart():void {
      // Server now sends a TEST_START message
      if (msg.receiveMessage(protocolObj.ctlSocket) !=
          NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
        // message not received / read correctly
        TestResults.appendErrMsg(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "protocolError", null, Main.locale)
          + parseInt(new String(msg.body), 16) + " instead\n");
        metaTest = false;
        onComplete();
        return;
      }
      // Only TEST_START message expected here. Everything else is 'wrong'
      if (msg.type != MessageType.TEST_START) {
        TestResults.appendErrMsg(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "metaWrongMessage",
                                           null, Main.locale) + "\n"); 
        if (msg.type == MessageType.MSG_ERROR) {
          TestResults.appendErrMsg("ERROR MSG: "
                                   + parseInt(new String(msg.body), 16)
                                   + "\n");
        }
        metaTest = false;
        onComplete();
        return;
      }
      comStage = SEND_DATA;
      sendData();
    }
    
    /**
     * Function that sends META data to the server to add information to the
     * results collected.
     */
    private function sendData():void {
      // As a response to the server's TEST_START message, the client
      // responds with TEST_MSG type message.
      // These message may be used to send name-value pairs as configuration data.
      // There are length constraints to key-values : 64 / 256 respectively
      TestResults.appendTraceOutput("USERAGENT " + TestResults.get_UserAgent() + "\n");
      trace("USERAGENT " + TestResults.get_UserAgent());
      var toSend:ByteArray = new ByteArray();
      
      toSend.writeUTFBytes(new String(NDTConstants.META_CLIENT_OS + ":" + Capabilities.os));
      Message.sendMessage(protocolObj.ctlSocket, MessageType.TEST_MSG, toSend);
      toSend.clear();
      toSend = new ByteArray();
      toSend.writeUTFBytes(new String(NDTConstants.META_CLIENT_BROWSER + ":"
                           + UserAgentTools.getBrowser(TestResults.get_UserAgent())[2]));
      Message.sendMessage(protocolObj.ctlSocket, MessageType.TEST_MSG, toSend);
      toSend.clear();
      toSend = new ByteArray();
      toSend.writeUTFBytes(new String(NDTConstants.META_CLIENT_VERSION + ":"
                           + NDTConstants.CLIENT_VERSION));
      Message.sendMessage(protocolObj.ctlSocket, MessageType.TEST_MSG, toSend);
      toSend.clear();
      toSend = new ByteArray();
      toSend.writeUTFBytes(new String(NDTConstants.META_CLIENT_APPLICATION
                           + ":" + clientId));
                      
      // Client can send any number of such meta data in a TEST_MSG
      // format and signal the send of the transmission using an empty
      // TEST_MSG
      Message.sendMessage(protocolObj.ctlSocket, MessageType.TEST_MSG, new ByteArray());
      comStage = FINALIZE_TEST;
      if (ctlSocket.bytesAvailable > MIN_MSG_SIZE)
        finalizeTest();
    }
    
    /**
     * Function that is called when all the data that has to be sent has been
     * sent to the server.
     */
    private function finalizeTest():void {
      // Server now closes the META test session by sending a 
      // TEST_FINALIZE message
      if (msg.receiveMessage(protocolObj.ctlSocket) !=
          NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
        // error receiving / reading message
        TestResults.appendErrMsg(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "protocolError", null, Main.locale)
          + parseInt(new String(msg.body), 16) + " instead\n");
        metaTest = false;
        onComplete();
        return;
      }
      if (msg.type != MessageType.TEST_FINALIZE) {
        // any other message is 'wrong'
        TestResults.appendErrMsg(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "metaWrongMessage", null, Main.locale));
        if (msg.type == MessageType.MSG_ERROR) {
          TestResults.appendErrMsg("ERROR MSG: "
                                   + parseInt(new String(msg.body), 16)
                                   + "\n");
        }
        metaTest = false;
        onComplete();
        return;
      }
      allDone();
    }
    
    private function allDone():void {
      // Display status as "complete" and assign status
      if (metaTest) {
        TestResults.appendConsoleOutput(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "done", null, Main.locale) + "\n");
        TestResults.appendStatsText(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "done", null, Main.locale) + "\n");
        TestResults.appendEmailText(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "done", null, Main.locale) + "\n%0A");
      } else {
        TestResults.appendConsoleOutput(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "metaFailed", null, Main.locale) + "\n");
        TestResults.appendStatsText(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "metaFailed", null, Main.locale) + "\n");
        TestResults.appendEmailText(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "metaFailed", null, Main.locale) + "\n%0A");
      }
      TestResults.set_pub_status("done");
      onComplete();
    }
    
    /**
     * Constructor that initializes local variables to their appropriate values
     * and triggers the testPrepare method if data is waiting to be read at the
     * socket.
     * @param {Socket} socket The Control Socket of communication
     * @param {Protocol} protObj The Protocol Object used in communications
     * @param {String} cID The client ID to be sent to the server
     * @param {MainFrame} callerObject Reference to instance of the caller object
     */
    public function TestMETA(socket:Socket, protObj:Protocol, 
                             cID:String, callerObject:MainFrame) {
      ctlSocket = socket;
      protocolObj = protObj;
      clientId = cID;
      callerObj = callerObject;
      comStage = TEST_PREPARE;
      metaTest = true;    // initially the test hasn't failed
      msg = new Message();
      
      addResponseListener();
      if(ctlSocket.bytesAvailable > MIN_MSG_SIZE)
        testPrepare();
    }
  }
}

