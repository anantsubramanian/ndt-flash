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
  import flash.events.Event;
  import flash.events.SecurityErrorEvent;
  import flash.events.IOErrorEvent;
  import flash.errors.IOError;
  import flash.utils.Timer;
  import flash.events.TimerEvent;
  import flash.utils.getTimer;
  import mx.resources.ResourceManager;
  
  /**
   * This class contains the functions used to perform the Server-to-Client
   * throughput  test to measure the network bandwidth from the server to the
   * client. There is an event listener function that triggers different stages 
   * of the test depending on the status variable.
   */
  public class TestS2C {
    // constants declaration section
    private static const MIN_MSG_SIZE:int = 1;
    private static const WEB100_VARS_MIN_SIZE:int = 1000;
    private static const TEST_PREPARE:int = 0;
    private static const TEST_START:int = 1;
    private static const RECEIVE_DATA:int = 2;
    private static const COMPARE_SERVER:int = 3;
    private static const GET_WEB100:int = 4;
    private static const ALL_COMPLETE:int = 5;
    private static const buffLen:int = NDTConstants.PREDEFINED_BUFFER_SIZE;
    
    // variables declaration section
    private var callerObj:MainFrame;
    private var inSocket:Socket;
    private var ctlSocket:Socket;
    private var protocolObj:Protocol;
    private var sHostName:String; 
    private var comStage:int; // variable indicating stage of communication
                              // with the server.
    private var buff:ByteArray;
    private var msg:Message;
    private var iBitCount:int;
    private var inlth:int;
    private var iS2cport:int;
    private var _dS2cspd:Number;
    private var _dSs2cspd:Number;
    private var _iSsndqueue:int;
    private var _dSbytes:Number;
    private static var _sTestResults:String = null;
    private var _dTime:Number;
    private var soTimer:Timer;
    private var tempProtObj:Protocol;
    private var testStartRead:Boolean;
    private var waitTimerCount:int;
    private var waitTimer:Timer;  // A timer to wait to proceed to the next step
                                  // if enough data to proceed hasn't been
                                  // received yet
    public var s2cTest:Boolean; // variable that represents success (true) or
                                // failure (false) of the test.
                  
    // getter function to get Test Results String
    public static function getResultString():String {
      return _sTestResults;
    }
       
    /**
     * Function that handles responses from the server through the Control Socket.
     * Depending on the stage of comm. the correct function is called. When all
     * stages have completed successfully or the test fails, it returns
     * control to the caller object.
     */
    private function onCtlResponse(e:ProgressEvent):void {
      switch (comStage) {
        case TEST_PREPARE:   testPrepare();
                             break;
        case TEST_START:     testStart();
                             break;
        case COMPARE_SERVER: compareWithServer();
                             break;
        case GET_WEB100:     soTimer.reset();
                             soTimer.start();
                             getWeb100();
                             break;
        default:             break;
      }      
      if (comStage == ALL_COMPLETE) {
        onComplete();
      }
    }
    
    /**
     * Function to be called to return control to the caller object.
     */
    public function onComplete():void {
      if (!s2cTest) {
        TestResults.appendConsoleOutput(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "s2cThroughputFailed",
                                          null, Main.locale) + "\n");
        TestResults.appendStatsText(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "s2cThroughputFailed",
                                          null, Main.locale) + "\n");
      }      
      if (!isNaN(_dS2cspd))
        TestResults.set_S2cspd(_dS2cspd);
      if (!isNaN(_dSs2cspd))
        TestResults.set_Ss2cspd(_dSs2cspd);
      
      removeResponseListener();
      // Increase testNo to mark the test as complete
      callerObj.testNo++;
      callerObj.runTests(protocolObj);
    }
    
    /**    
     * Function triggered on successful connection of the test socket. It marks
     * the time for the beginning of the data transfer. 
     */
    private function onInConnect(e:Event):void {
      trace("S2C Socket Connected");
      TestResults.appendTraceOutput("S2C Socket Connected\n");
      comStage = RECEIVE_DATA;
      tempProtObj = new Protocol(inSocket);
      _dTime = getTimer();  // get start time for receiving data
    }
    
    /**
     * Function triggered every time the server sends some
     * data through the test socket. 
     */
    private function onInResponse(e:ProgressEvent):void {
      // inSocket
      soTimer.stop();
      soTimer.reset();
      soTimer.start();
      receiveData();
    }
    
    /** 
     * Function triggered when the server has finished sending
     * 10s data. It marks the end time for the data transfer
     * and calls calculateThroughput.
     */
    private function onInClose(e:Event):void {
      // get time duration during which bytes were received
      _dTime = getTimer() - _dTime;
      trace("S2C Socket Closed.");
      TestResults.appendTraceOutput("S2C Socket closed\n");
      removeEventListeners();
      soTimer.stop();
      inSocket.close();
      calculateThroughput();
    }    
    private function onInSecError(e:SecurityErrorEvent):void {
      trace("S2C Security Error" + e);
      TestResults.appendErrMsg("S2C Security error : " + e);
      s2cTest = false;
      removeResponseListener();
      removeEventListeners();
      onComplete();
    }    
    private function onInError(e:IOErrorEvent):void {
      trace("S2C IOError : " + e);
      TestResults.appendErrMsg("S2C IOError : " + e);
      s2cTest = false;
      removeEventListeners();
      removeResponseListener();
      onComplete();
    }    
    private function addEventListeners():void {
      inSocket.addEventListener(Event.CONNECT, onInConnect);
      inSocket.addEventListener(Event.CLOSE, onInClose);
      inSocket.addEventListener(ProgressEvent.SOCKET_DATA, onInResponse);
      inSocket.addEventListener(IOErrorEvent.IO_ERROR, onInError);
      inSocket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onInSecError);
    }    
    private function removeEventListeners():void {
      inSocket.removeEventListener(Event.CONNECT, onInConnect);
      inSocket.removeEventListener(Event.CLOSE, onInClose);
      inSocket.removeEventListener(ProgressEvent.SOCKET_DATA, onInResponse);
      inSocket.removeEventListener(IOErrorEvent.IO_ERROR, onInError);
      inSocket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onInSecError);
    }    
    private function addResponseListener():void {
      ctlSocket.addEventListener(ProgressEvent.SOCKET_DATA, onCtlResponse);
    }    
    private function removeResponseListener():void {
      ctlSocket.removeEventListener(ProgressEvent.SOCKET_DATA, onCtlResponse);
    }
    
    /**
     * Function that is triggered if a read timeout occurs
     * during the 10s data transfer.
     */
    private function readTimeout1(e:TimerEvent):void {
      _dTime = getTimer() - _dTime;
      soTimer.stop();
      removeEventListeners();
      calculateThroughput();
    }
    
    /**
     * Function that is triggered if a read timeout occurs
     * while getting the web100 variables. 
     */
    private function readTimeout2(e:TimerEvent):void {
      TestResults.appendErrMsg("Error Reading web100 variables. Socket read timed out.\n");
      comStage = ALL_COMPLETE;
    }
    
    /**
     * Function that responds by returning the appropriate function to the
     * wait timer as an event listener.
     * @return {Function} An event listener function appropriate to the comStage
     */
    private function returnWaitFunction():Function {
      if (ctlSocket.bytesAvailable <= MIN_MSG_SIZE) {
        if (waitTimerCount > 2) {
          s2cTest = false;
          TestResults.appendErrMsg("Server didn't respond in time.\n");
          onComplete();
        } else {
          waitTimerCount++;
          waitTimer.start();
        }
        return function doNothing(e:TimerEvent):void;
      }
      switch(comStage) {
        case TEST_PREPARE:   return function timerRespond(e:TimerEvent):void {
                                      testPrepare();
                                     }
                             break;
        case TEST_START:     return function timerRespond(e:TimerEvent):void {
                                      testStart();
                                     }
                             break;
        case COMPARE_SERVER: return function timerRespond(e:TimerEvent):void {
                                      compareWithServer();
                                    }
                             break;
        case GET_WEB100:     return function timerRespond(e:TimerEvent):void {
                                      getWeb100();
                                    }
                             break;
      }
      return function doNothing(e:TimerEvent):void;
    }
    
    /**   
     * Function that processes the TEST_PREPARE message and initializes the
     * inSocket object to the port mentioned by the server.
     */
    private function testPrepare():void {
      buff = new ByteArray();
      msg = new Message();
      
      // start s2c tests
      TestResults.appendConsoleOutput(
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                        "runningInboundTest",
                                        null, Main.locale));
      TestResults.appendStatsText(
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                        "runningInboundTest",
                                        null, Main.locale));
      TestResults.set_pub_status("runningInboundTest");
      // server sends TEST_PREPARE message with the port to bind
      // to as the message body
      if (msg.receiveMessage(protocolObj) != NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
        TestResults.appendErrMsg(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "protocolError", null, Main.locale)
          + parseInt(new String(msg.body), 16) + " instead\n");
        s2cTest = false;
        onComplete();
        return;
      }
      if (msg.type != MessageType.TEST_PREPARE) {
        // no other message type expected at this point
        TestResults.appendErrMsg(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "inboundWrongMessage",
                                          null, Main.locale) + "\n");
        if (msg.type == MessageType.MSG_ERROR) {
          TestResults.appendErrMsg("ERROR MESSAGE : "
                                   + parseInt(new String(msg.body), 16)
                                   + "\n");
        }
        s2cTest = false;
        onComplete();
        return;
      }
      // get port to bind to for the s2c tests
      iS2cport = parseInt(new String(msg.body));
      iBitCount = 0;
      inlth = 0;
      comStage = TEST_START;
      soTimer = new Timer(15000);
      soTimer.addEventListener(TimerEvent.TIMER, readTimeout1);
      inSocket = new Socket(sHostName, iS2cport);
      addEventListeners();
    }
    
    /**
     * Function that processes the TEST_START message once
     * the inSocket object has established connection to the
     * test port.
     */
    private function testStart():void {
      testStartRead = true;
      removeResponseListener();  // so that ctlSocket doesn't interfere with
                                 // inSocket events
      
      // server now sends a TEST_START message
      if (msg.receiveMessage(protocolObj) != NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
        TestResults.appendErrMsg(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "unknownServer", null, Main.locale)
          + parseInt(new String(msg.body), 16) + " instead\n");
        s2cTest = false;
        onComplete();
        return;
      }      
      if (msg.type != MessageType.TEST_START) {
        // no other message type expected at this point
        TestResults.appendErrMsg(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "serverFail", null, Main.locale) + "\n");
        if (msg.type == MessageType.MSG_ERROR) {
          TestResults.appendErrMsg("ERROR MSG : "
                                   + parseInt(new String(msg.body), 16)
                                   + "\n");
        }
        s2cTest = false;
        onComplete();
        return;
      }
    }
    
    /**
     * Function that is called repeatedly by the inSocket response
     * listener for the duration of the test. It processes and keeps
     * track of the total bits received from the server.
     * The test only progresses past this stage if comStage is changed 
     * because :
     * 1. All data was successfully received.
     * 2. A read timeout ( > 15s) occured on inSocket
     * 3. More than 14.5 seconds have elapsed since the beginning of the test.
     */
    private function receiveData():void {
      while ((inlth = NDTUtils.readBytes(
          inSocket, buff, 0, buffLen)) > 0) {
        iBitCount += inlth; // incrementing bit count
        if ((getTimer() - _dTime) > 14500) {
          // get time duration during which bytes were received
          _dTime = getTimer() - _dTime;
          soTimer.stop();
          removeEventListeners();
          calculateThroughput();
          return;
        }
      }
    }
    
    /**
     * Function that calculates the throughput value from iBitCount
     * and _dTime.
     */
    private function calculateThroughput():void {
      trace(iBitCount + " bytes " + (NDTConstants.BYTES2BITS * iBitCount) / _dTime
            + " kb/s " + _dTime / NDTConstants.SEC2MSEC + " secs");
      TestResults.appendTraceOutput(new String(iBitCount + " bytes " 
                                    + (NDTConstants.BYTES2BITS * iBitCount) / _dTime
                                    + " kb/s " + _dTime / NDTConstants.SEC2MSEC
                                    + " secs\n"));
      
      // calculate throughput
      _dS2cspd = ((NDTConstants.BYTES2BITS * iBitCount) / NDTConstants.SEC2MSEC) / _dTime;
      comStage = COMPARE_SERVER;
      addResponseListener();    // adding event listeners back to ctlSocket
      if (ctlSocket.bytesAvailable > MIN_MSG_SIZE) {
        compareWithServer();
      } else waitTimer.start();
    }
    
    /**
     * Function that receives and compares the server throughput value
     * with the client obtained one. It then sends the client calculated
     * throughput value to the server. 
     */
    private function compareWithServer():void {
      if (!testStartRead) {
        // sometimes the TEST_START message is not read before the tests
        // begin. This ensures that it is read and processed.
        testStart();
        addResponseListener();
        if (ctlSocket.bytesAvailable <= WEB100_VARS_MIN_SIZE) {
          return;
        }  
      }
      
      // once all data is received / timeout occurs, server sends
      // TEST_MSG message with throughput calculated at its end,
      // unsent data queue size and total sent byte count, separated
      // by spaces.
      //receive s2cspd from the server
      if (msg.receiveMessage(protocolObj) != NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
        // error reading / receiving message
        TestResults.appendErrMsg(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "protocolError", null, Main.locale)
          + parseInt(new String(msg.body), 16) + " instead\n");
        s2cTest = false;
        onComplete();
        return;
      }
      
      // Only message of type TEST_MSG expected from the server at this point
      if (msg.type != MessageType.TEST_MSG) {
        TestResults.appendErrMsg(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "inboundWrongMessage",
                                           null, Main.locale) + "\n");
        if (msg.type == MessageType.MSG_ERROR) {
          TestResults.appendErrMsg("ERROR MSG : "
                                   + parseInt(new String(msg.body), 16)
                                   + "\n");
        }
        s2cTest = false;
        onComplete();
        return;
      }
      // get data from message and check for errors
      var tmpstr:String = new String(msg.body);
      var k1:int = tmpstr.indexOf(" ");
      var k2:int = (tmpstr.substr(k1+1)).indexOf(" ");
      _dSs2cspd = parseFloat(tmpstr.substr(0, k1)) / NDTConstants.SEC2MSEC;
      _iSsndqueue = parseInt((tmpstr.substr(k1+1)).substr(0, k2));
      _dSbytes = parseFloat((tmpstr.substr(k1+1)).substr(k2+1));
      
      if (isNaN(_dSs2cspd) || isNaN(_iSsndqueue) || isNaN(_dSbytes)) {
        TestResults.appendErrMsg(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "inboundWrongMessage",
                                          null, Main.locale) + "\n");
        s2cTest = false;
        onComplete();
        return;
      }
      
      // Represent throughput using optimal units (i.e. kbps / mbps)
      if (_dS2cspd < 1.0) {
        TestResults.appendConsoleOutput((_dS2cspd * NDTConstants.SEC2MSEC).toFixed(2)
                                        + "kb/s\n");
        TestResults.appendStatsText((_dS2cspd * NDTConstants.SEC2MSEC).toFixed(2)
                                    + "kb/s\n");
      } else {
        TestResults.appendConsoleOutput((_dS2cspd).toFixed(2) + "Mb/s\n");
        TestResults.appendStatsText((_dS2cspd).toFixed(2) + "Mb/s\n");
      }
      
      // Set result for JavaScript access
      TestResults.set_pub_status("done");
      buff = new ByteArray();
      buff.writeUTFBytes((_dS2cspd * NDTConstants.SEC2MSEC).toString());
      var tmpstr2:String = buff.toString();
      trace("Sending '" + tmpstr2 + "' back to server");
      TestResults.appendTraceOutput("Sending '" + tmpstr2 + "' back to server\n");
      
      // Display server calculated throughput value
      trace("Server calculated throughput value = " + _dSs2cspd + " Mb/s");
      TestResults.appendTraceOutput("Server calculated throughput value = " + _dSs2cspd + " Mb/s\n"); 
      soTimer = new Timer(5000, 0);
      soTimer.removeEventListener(TimerEvent.TIMER, readTimeout1);
      soTimer.addEventListener(TimerEvent.TIMER, readTimeout2);
      comStage = GET_WEB100;
      
      // Client has to send its throughput to the server inside
      // a TEST_MSG message
      protocolObj.send_msg_array(MessageType.TEST_MSG, buff);
      _sTestResults = "";
      if (ctlSocket.bytesAvailable > WEB100_VARS_MIN_SIZE) {
        getWeb100();
      }
    }
    
    /**
     * Function that gets all the web100 variables as name-value string pairs.
     * It is called multiple times by the response listener of the Control Socket
     * and adds more data to _sTestResults every call.
     */
    private function getWeb100():void {
      // get web100 variables from the server
      while (ctlSocket.bytesAvailable > 0) {
        if (msg.receiveMessage(protocolObj) != NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
          // message not read / received correctly
          TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                            "protocolError", null, Main.locale)
            + parseInt(new String(msg.body), 16) + " instead\n");
          s2cTest = false;
          onComplete();
          return;
        }
        if (msg.type == MessageType.TEST_FINALIZE) {
          // all web100 variables have been sent by the server
          TestResults.set_pub_status("done");
          comStage = ALL_COMPLETE;
          soTimer.stop();
          removeResponseListener();
          return;
        }
        
        // Only a message of TEST_MSG type containing the web100 variables
        // is expected. Every other message is "incorrect"
        if (msg.type != MessageType.TEST_MSG) {
          TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                            "inboundWrongMessage",
                                            null, Main.locale) + "\n");
          if (msg.type == MessageType.MSG_ERROR) {
            TestResults.appendErrMsg("ERROR MSG : "
                                     + parseInt(new String(msg.body), 16)
                                     + "\n");
          }
          s2cTest = false;
          onComplete();
          return;
        }
        // get all web100 variables as name-value string pairs
        _sTestResults += new String(msg.body);
      }
    }
    
    /**
     * Constructor that initializes local variables to the ones
     * from the MainFrame object. Calls the test prepare function
     * if the Control Socket is ready.
     * @param {Socket} socket The Control Socket of communication
     * @param {Protocol} protObj The Protocol Object used in communications
     * @param {String} host The Hostname of the server
     * @param {MainFrame} callerObject Used to return control to the MainFrame object
     */
    public function TestS2C(socket:Socket, protObj:Protocol, 
                            host:String, callerObject:MainFrame) {
      callerObj = callerObject;
      ctlSocket = socket;
      protocolObj = protObj;
      sHostName = host;
      addResponseListener();
      
      // assigning initial values to variables
      comStage = TEST_PREPARE;
      testStartRead = false;
      waitTimerCount = 0;
      _dTime = 1;
      iBitCount = 0;
      inlth = 0;    
      s2cTest = true;    // initially the test has not failed.
      waitTimer = new Timer(1000, 0);
      waitTimer.addEventListener(TimerEvent.TIMER, returnWaitFunction);
      
      // if enough bytes have already been received to proceed
      if (ctlSocket.bytesAvailable > MIN_MSG_SIZE) {
        testPrepare();
      }
    }
  }
}

