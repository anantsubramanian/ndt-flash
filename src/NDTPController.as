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
  import flash.net.Socket;
  import flash.system.Security;
  import mx.resources.ResourceManager;

  /**
   * Class responsible for establishing the socket connection and initiating
   * communications with the server (NDTP-Control).
   * Calls functions to perform the required tests and to interpret the results.
   */
  public class NDTPController {
    private var hostname_:String;
    private var ctlSocket_:Socket = null;
    private var testsToRun_:Array;
    private var testResults_:TestResults;

    public function NDTPController(hostname:String) {
      hostname_ = hostname;
    }

    // Control socket event listeners.
    private function onConnect(e:Event):void {
      TestResults.appendDebugMsg("Control socket connected");
      startHandshake();
    }
    private function onClose(e:Event):void {
      TestResults.appendDebugMsg("Control socket closed by server");
    }
    private function onIOError(e:IOErrorEvent):void {
      TestResults.appendErrMsg("IOError on control socket: " + e);
      failNDTTest();
    }
    private function onSecurityError(e:SecurityErrorEvent):void {
      TestResults.appendErrMsg("Security error on control socket: " + e);
      failNDTTest();
    }
    private function addSocketEventListeners():void {
      ctlSocket_.addEventListener(Event.CONNECT, onConnect);
      ctlSocket_.addEventListener(Event.CLOSE, onClose);
      ctlSocket_.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
      ctlSocket_.addEventListener(SecurityErrorEvent.SECURITY_ERROR,
                                  onSecurityError);
      // TODO: Check if also OutputProgressEvents should be handled.
    }

    public function startNDTTest():void {
      TestResults.recordStartTime();
      TestResults.appendDebugMsg(
        ResourceManager.getInstance().getString(
          NDTConstants.BUNDLE_NAME, "connectingTo", null, Main.locale)
        + " " + hostname_ + " " +
        ResourceManager.getInstance().getString(
          NDTConstants.BUNDLE_NAME, "toRunTest", null, Main.locale));

      ctlSocket_ = new Socket();
      addSocketEventListeners();
      try {
        ctlSocket_.connect(hostname_, NDTConstants.DEFAULT_CONTROL_PORT);
      } catch(e:IOError) {
        TestResults.appendErrMsg("Control socket connect IO error: " + e);
        failNDTTest();
      } catch(e:SecurityError) {
        TestResults.appendErrMsg("Control socket connect security error: " + e);
        failNDTTest();
      }
    }

    private function startHandshake():void {
      var handshake:Handshake = new Handshake(
          ctlSocket_, NDTConstants.TESTS_REQUESTED_BY_CLIENT, this);
      handshake.sendLoginMessage();
    }

    /**
     * This function initializes the array 'tests' with
     * the different tests received in the message from
     * the server.
     */
    public function initiateTests(testsConfirmedByServer:String):void {
      testsToRun_ = testsConfirmedByServer.split(" ");
      runTests();
    }

    /**
     * Function that creates objects of the respective classes to run
     * the tests.
     */
    public function runTests():void {
      if (testsToRun_.length > 0) {
        var currentTest:int = parseInt(testsToRun_.shift());
        switch (currentTest) {
          case TestType.C2S:
              var c2s:TestC2S = new TestC2S(ctlSocket_, hostname_, this);
	      c2s.run();
              break;
          case TestType.S2C:
              var s2c:TestS2C = new TestS2C(ctlSocket_, hostname_, this);
	      s2c.run();
              break;
          case TestType.META:
              var meta:TestMETA = new TestMETA(ctlSocket_, this);
	      meta.run();
              break;
        }
      } else {
        // TODO: Use tests confirmed by the server.
        testResults_ = new TestResults(
	    ctlSocket_, NDTConstants.TESTS_REQUESTED_BY_CLIENT, this);
        testResults_.receiveRemoteResults();
      }
    }

    public function failNDTTest():void {
      TestResults.ndt_test_results::ndtTestFailed = true;
      NDTUtils.callExternalFunction("fatalErrorOccured");
      TestResults.appendErrMsg("NDT test failed");
      finishedAll();
    }
    /**
     * Function that is called on completion of all the tests and after the
     * retrieval of the last set of results.
     */
    public function finishedAll():void {
      TestResults.recordEndTime();
      NDTUtils.callExternalFunction("allTestsCompleted");
      TestResults.appendDebugMsg("All the tests completed successfully");
      try {
        ctlSocket_.close();
      } catch (e:IOError) {
        TestResults.appendErrMsg("Client failed to close control socket. " +
	                         "Error" + e);
      }
      testResults_.interpretResults();
      if (Main.guiEnabled) {
        Main.gui.displayResults();
      }
    }
  }
}

