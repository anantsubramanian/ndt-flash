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
  import flash.utils.ByteArray;
  import flash.utils.Timer;
  import flash.events.TimerEvent;
  import flash.utils.getTimer;
  import flash.net.Socket;
  import flash.events.ProgressEvent;
  import flash.events.Event;
  import flash.events.IOErrorEvent;
  import flash.events.SecurityErrorEvent;
  import flash.events.OutputProgressEvent;
  import flash.errors.IOError;
  import mx.resources.ResourceManager;
  
  /**
   * Class that contains functions that perform the Client-to-Server
   * throughput test. It is a 10 second memory-to-memory data transfer
   * to test achievable network bandwidth.
   */
  public class TestC2S {
    // Constants used in this class
    private static const buffSize:int = 64 * NDTConstants.KBITS2BITS;
    private static const MIN_MSG_SIZE:int   = 1;
    private static const PKT_WAIT_SIZE:int   = 5;
    private static const TEST_PREPARE:int   = 0;
    private static const TEST_START:int      = 1;
    private static const SENDING_DATA:int   = 2;
    private static const CALC_THRUPUT:int  = 3;
    private static const COMP_SERVER:int  = 4;
    private static const FINALIZE_TEST:int   = 5;
    private static const ALL_COMPLETE:int   = 6;
    
    // variables declaration section
    private var callerObj:NDTPController;
    private var ctlSocket:Socket;
    private var sHostname:String;
    private var msg:Message;
    private var _dC2sspd:Number;
    private var _dSc2sspd:Number;
    private var outSocket:Socket;
    private var _iLength:int = NDTConstants.PREDEFINED_BUFFER_SIZE;
    private var _iPkts:int;
    private var _iPktsRem:int;  // indicating the number of packets not sent 
                                // from the last outSocket send operation
    private var _dPktsSent:Number;
    private var _dTime:Number;
    private var outTimer:Timer;
    private var c2sTest:Boolean;
    private static var comStage:int; // indicates the communication stage
    private static var yabuff2Write:ByteArray;
    
    // Event listener functions
    private function onCtlResponse(e:ProgressEvent):void {
      switch (comStage) {
        
        case TEST_PREPARE:  testPrepare();
                            break;
        case TEST_START:    // Mark the start time for the test
                            _dTime = getTimer();
                            TestResults.ndt_test_results::c2sTime = _dTime;
                            testStart();
                            break;
        case COMP_SERVER:   compareWithServer();
                            break;
        case FINALIZE_TEST: finalizeTest();
                            break;
        case ALL_COMPLETE:  break;
      }
      if(comStage == ALL_COMPLETE)
        onComplete();      
    }
    
    /**
     * Function triggered on completion of the test.
     * It may have been successful or unsuccessful.
     */
    private function onComplete():void {
      if (!c2sTest) {
        TestResults.appendConsoleOutput(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "c2sThroughputFailed",
                                          null, Main.locale) + "\n");
        TestResults.appendStatsText(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "c2sThroughputFailed",
                                          null, Main.locale) + "\n");
      }
      if (!isNaN(_dC2sspd))
        TestResults.ndt_test_results::c2sSpeed = _dC2sspd;
      if (!isNaN(_dSc2sspd))
        TestResults.ndt_test_results::sc2sSpeed = _dSc2sspd;
      TestResults.ndt_test_results::c2sFailed = !c2sTest;
      
      // mark this test as complete and continue
      callerObj.runTests();
    }
    
    private function addResponseListener():void {
      ctlSocket.addEventListener(ProgressEvent.SOCKET_DATA, onCtlResponse);
    }
    
    private function removeResponseListener():void {
      ctlSocket.removeEventListener(ProgressEvent.SOCKET_DATA, onCtlResponse);
    }
    
    /** 
     * Function triggered on successful connection of the test socket.
     */
    private function onOutConnect(e:Event):void {
      trace("C2S Socket Connected");
      TestResults.appendTraceOutput("C2S Socket Connected\n");
    }
    
    /**
     * Function triggered when the test socket connection is closed by the
     * server. 
     */
    private function onOutClose(e:Event):void {
      // get time duration for the test
      _dTime = getTimer() - _dTime;
      _iPktsRem = 0;
      outTimer.stop();
      trace("C2S Socket Closed.");
      TestResults.appendTraceOutput("C2S Socket closed\n");
      removeEventListeners();
      calculateThroughput();
    }
    
    private function onOutSecError(e:SecurityErrorEvent):void {
      trace("C2S Security Error" + e);
      TestResults.appendErrMsg("C2S Security error : " + e);
      c2sTest = false;
      removeEventListeners();
      removeResponseListener();
      onComplete();
    }
    
    private function onOutError(e:IOErrorEvent):void {
      trace("C2S IOError : " + e);
      TestResults.appendErrMsg("C2S IOError : " + e);
      c2sTest = false;
      removeEventListeners();
      removeResponseListener();
      onComplete();
    }
    
    /**
     * Function triggered when data is moved from the write buffer of the
     * socket to its network transport layer.
     */
    private function onOutProgress(e:OutputProgressEvent):void {
      if (outSocket.bytesPending == 0) {
        _iPkts++;
        if (outSocket.connected) {
          sendData();
          return;
        } else {
          // get time duration for the test
          _dTime = getTimer() - _dTime;
          _iPktsRem = 0;
          outTimer.stop();
          removeEventListeners();
          calculateThroughput();
        }          
      }
    }
    
    /**
     * Function triggered when 10 sec of writing to the socket
     * is complete.
     */
    private function onOutTimeout(e:TimerEvent):void {
      // get time duration for the test
      _dTime = getTimer() - _dTime;
      // save the num of bytes not sent from last message if any
      if (outSocket.connected)
        _iPktsRem = outSocket.bytesPending;
      else _iPktsRem = 0;
      outTimer.stop();
      removeEventListeners();
      calculateThroughput();
    }
    
    private function addEventListeners():void {
      outSocket.addEventListener(Event.CONNECT, onOutConnect);
      outSocket.addEventListener(Event.CLOSE, onOutClose);
      outSocket.addEventListener(IOErrorEvent.IO_ERROR, onOutError);
      outSocket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onOutSecError);
      outSocket.addEventListener(OutputProgressEvent.OUTPUT_PROGRESS, onOutProgress);
    }
    
    private function removeEventListeners():void {
      outSocket.removeEventListener(Event.CONNECT, onOutConnect);
      outSocket.removeEventListener(Event.CLOSE, onOutClose);
      outSocket.removeEventListener(IOErrorEvent.IO_ERROR, onOutError);
      outSocket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onOutSecError);
      outSocket.removeEventListener(OutputProgressEvent.OUTPUT_PROGRESS, onOutProgress);
    }
    
    /**
     * Function that handles the initial test prepare message sent by the server.
     * It fills the buffer ByteArray with data and creates a new Socket object
     * to connect to the port specified by the server.
     */
    private function testPrepare():void {
      TestResults.appendConsoleOutput(
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                        "runningOutboundTest",
                                        null, Main.locale) + " " + "\n");
      TestResults.appendStatsText(
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                        "runningOutboundTest",
                                        null, Main.locale) + " " + "\n");
      TestResults.ndt_test_results::ndtTestStatus = "runningOutboundTest";
      
      if (msg.receiveMessage(ctlSocket) !=
          NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
        // error reading / receiving message
        TestResults.appendErrMsg(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "protocolError", null, Main.locale)
          + parseInt(new String(msg.body), 16) + " instead\n");
        c2sTest = false;
        onComplete();
        return;
      }
      // Initial message from the server is TEST_PREPARE
      // containing the socket to connect to
      if (msg.type != MessageType.TEST_PREPARE) {
        // 'wrong' message type
        TestResults.appendErrMsg(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "outboundWrongMessage", 
                                          null, Main.locale) + "\n");
        if (msg.type == MessageType.MSG_ERROR) {
          TestResults.appendErrMsg("ERROR MSG: " 
                                   + parseInt(new String(msg.body), 16)
                                   + "\n");
        }
        c2sTest = false;
        onComplete();
        return;
      }
      
      // Fill buffer upto NDTConstants.PREDEFINED_BUFFER_SIZE packets
      var c:int = parseInt('0');
      var i:int;
      for (i = 0; i < _iLength; i++) {
        if (c == parseInt('z')) {
          c = parseInt('0');
        }
        yabuff2Write.writeByte(c++);
      }
      TestResults.appendTraceOutput("******Send buffer size = " + i + "\n");
      trace("******Send buffer size = " + i);
      
      // get port to bind to from message
      var iC2sport:int = parseInt(new String(msg.body));
      comStage = TEST_START;
      outSocket = new Socket(sHostname, iC2sport);
      addEventListeners();
      if (ctlSocket.bytesAvailable > MIN_MSG_SIZE)
        testStart();
    }
    
    /**
     * Function triggered when the server sends the TEST_START message to 
     * indicate to the client that it should start sending data.
     */
    private function testStart():void {
      // remove ctlSocket listener so it doesn't interfere with
      // the outSocket listeners.
      removeResponseListener();
      comStage = SENDING_DATA;
      _iPkts = 0;
      outTimer = new Timer(10000, 0);
      outTimer.addEventListener(TimerEvent.TIMER, onOutTimeout);
      
      // read signal from server application
      // This signal tells the client to start pumping out data
      if (msg.receiveMessage(ctlSocket) !=
          NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
        TestResults.appendErrMsg(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "protocolError", null, Main.locale)
          + parseInt(new String(msg.body), 16) + " instead\n");
        c2sTest = false;
        onComplete();
        return;
      }
      // Expecting a TEST_START message from the server now.
      // Any other message is an error
      if (msg.type != MessageType.TEST_START) {
        TestResults.appendErrMsg(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "outboundWrongMessage",
                                          null, Main.locale) + "\n");
        if (msg.type == MessageType.MSG_ERROR) {
          TestResults.appendErrMsg ("ERROR MSG: " 
                                    + parseInt(new String(msg.body), 16)
                                    + "\n");
        }
        c2sTest = false;
        onComplete();
        return;
      }
      outTimer.start();
      sendData();
    }
    
    /**
     * Function that is called repeatedly to write data through the Socket
     * connection to the server.
     * @See: onOutProgress
    */
    private function sendData():void {
      outSocket.writeBytes(yabuff2Write, 0, yabuff2Write.length);
      outSocket.flush();
    }
    
    /**
     * Function that is called to calculate the throughput once all data that
     * can be sent in the time duration _dTime has been sent to the server.
     */
    private function calculateThroughput():void {
      comStage = CALC_THRUPUT;
      // number of packets sent = 
      // (no. of iterations) * (buffer size) + (bytes sent from last message)
      _dPktsSent = (_iPkts * _iLength) + (_iLength - _iPktsRem);
      
      TestResults.ndt_test_results::c2sPktsSent = _dPktsSent;
      trace(_dTime + " millisec test completed" + ", "
            + yabuff2Write.length + ", " + _iPkts + ", "
            + (_iLength - _iPktsRem));
      TestResults.appendTraceOutput(_dTime + " millisec test completed" + ", "
                                    + yabuff2Write.length + ", " + _iPkts + ", "
                                    + (_iLength - _iPktsRem) + "\n");
      if (_dTime == 0)
        _dTime = 1;
      
      // Calculate C2S throughput in kbps
      // 8 for calculating bits
      trace(((NDTConstants.BYTES2BITS * _dPktsSent) / _dTime), "kb/s outbound");
      TestResults.appendTraceOutput((NDTConstants.BYTES2BITS * _dPktsSent) / _dTime
                                    + " kb/s outbound\n");
      _dC2sspd = ((NDTConstants.BYTES2BITS * _dPktsSent) / NDTConstants.SEC2MSEC) / _dTime;
      
      comStage = COMP_SERVER;
      addResponseListener();
      try {
        outSocket.close();
      } catch (e:IOError) {
        trace("IO Error while closing C2S Test Socket : " + e);
      }
    }
    
    /**
     * Function that receives the server computed value of the throughput and
     * stores it in the corresponding field.
     */
    private function compareWithServer():void {
      if (ctlSocket.bytesAvailable <= PKT_WAIT_SIZE)
        return;
      
      // The client has stopped streaming data, and the server is now
      // expected to send a TEST_MSG message with the throughput it
      // calculated at its end.
      if (msg.receiveMessage(ctlSocket) !=
          NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
        TestResults.appendErrMsg(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "protocolError", null, Main.locale)
          + parseInt(new String(msg.body), 16) + " instead\n");
        c2sTest = false;
        onComplete();
        return;
      }
      if (msg.type != MessageType.TEST_MSG) {
        // 'wrong' type received
        TestResults.appendErrMsg(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "outboundWrongMessage",
                                          null, Main.locale) + "\n");
        if(msg.type == MessageType.MSG_ERROR) {
          TestResults.appendErrMsg("ERROR MSG: "
                                   + parseInt(new String(msg.body), 16) 
                                   + "\n");
        }
        c2sTest = false;
        onComplete();
        return;        
      }
      
      // Get throughput calculated by the server
      var tmpstr:String = new String(msg.body);
      _dSc2sspd = parseFloat(tmpstr) / NDTConstants.SEC2MSEC;
      // Display server calculated throughput value
      trace("Server calculated throughput value = " + _dSc2sspd + " Mb/s");
      TestResults.appendTraceOutput("Server calculated throughput value = " 
                                    + _dSc2sspd + " Mb/s\n");
      comStage = FINALIZE_TEST;
      if(ctlSocket.bytesAvailable > MIN_MSG_SIZE)
        finalizeTest();
    }
    
    /**
     * Function that adds the results to the output to be displayed and removes
     * all local Event Listeners.
     */
    private function finalizeTest():void {
      // Print results in the most convinient units
      if (_dSc2sspd < 1.0) {
        TestResults.appendConsoleOutput(
          (_dSc2sspd * NDTConstants.SEC2MSEC).toFixed(2) + "kb/s\n");
        TestResults.appendStatsText(
          (_dSc2sspd * NDTConstants.SEC2MSEC).toFixed(2) + "kb/s\n");
      } else {
        TestResults.appendConsoleOutput((_dSc2sspd).toFixed(2) + "Mb/s\n");
        TestResults.appendStatsText((_dSc2sspd).toFixed(2) + "Mb/s\n");
      }
      
      // Server should close session with a TEST_FINALIZE message
      if (msg.receiveMessage(ctlSocket) !=
          NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
        TestResults.appendErrMsg(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "protocolError", null, Main.locale) 
          + parseInt(new String(msg.body), 16) + " instead\n");
        c2sTest = false;
        onComplete();
        return;
      }
      if (msg.type != MessageType.TEST_FINALIZE) {
        // 'wrong' message type
        TestResults.appendErrMsg(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "outboundWrongMessage",
                                          null, Main.locale) + "\n");
        if (msg.type == MessageType.MSG_ERROR) {
          TestResults.appendErrMsg("ERROR MSG: "
                                   + parseInt(new String(msg.body), 16)
                                   + "\n");
        }
        c2sTest = false;
        onComplete();
        return;
      }
      // All done with test
      removeResponseListener();
      onComplete();      
    }
    
    /**
     * Constructor for the TestC2S class that adds response listeners
     * and calls the testPrepare method if data is available at the
     * Control Socket.
     * @param {Socket} socket The Control Socket of communication
     * @param {String} host The Hostname of the server
     * @param {NDTPController} callerObject Reference to instance of the caller object
    */
    public function TestC2S(socket:Socket, host:String,
                            callerObject:NDTPController) {
      callerObj = callerObject
      ctlSocket = socket;
      sHostname = host;
      c2sTest = true;    // initially the test has not failed
      
      // initializing local variables
      _iPkts = 0;
      _iPktsRem = 0;  
      _dPktsSent = 0.0;
      _dTime = 0.0;
      yabuff2Write = new ByteArray();
      msg = new Message();
      comStage = TEST_PREPARE;
      
      addResponseListener();
      if (ctlSocket.bytesAvailable > MIN_MSG_SIZE)
        testPrepare();      
    }
  }
}

