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
  use namespace ndt_test_results;
  import flash.events.ProgressEvent;
  import flash.events.TimerEvent;
  import flash.net.Socket;
  import flash.system.Capabilities;
  import flash.utils.getTimer;
  import flash.utils.Timer;
  import mx.resources.ResourceManager;
  /**
   * Class that interprets the results of the tests. These results are stored in
   * variables that can be accessed through JavaScript.
   */
  public class TestResults {
    private static var _requestedTests:int;
    private static var _readResultsTimer:Timer = new Timer(10000);
    private static var _ctlSocket:Socket;
    private static var _remoteTestResults:String;
    private static var _callerObj:NDTPController;

    private static var _ndtTestStartTime:Number = 0.0;
    private static var _ndtTestEndTime:Number = 0.0;
    private static var _mylink:Number = 0.0;

    // Aggregate test results.
    private static var _resultDetails:String = "";
    private static var _errMsg:String = "";
    private static var _debugMsg:String = "";

    // TODO: To remove.
    private static var _consoleOutput:String = "";
    private static var _statsText:String = "";

    // Variables accesses by other classes to get and/or set values.
    ndt_test_results static var ndtVariables:Object = new Object();
    ndt_test_results static var ndtTestStatus:String = null;
    ndt_test_results static var ndtTestFailed:Boolean = false;
    ndt_test_results static var flashVersion:String = null;
    ndt_test_results static var osName:String = null;
    ndt_test_results static var osArchitecture:String = null;
    ndt_test_results static var c2sTime:Number = 0.0;
    ndt_test_results static var c2sPktsSent:Number = 0.0;
    ndt_test_results static var s2cTestResults:String;
    ndt_test_results static var sc2sSpeed:Number = 0.0;
    ndt_test_results static var ss2cSpeed:Number = 0.0;
    ndt_test_results static var s2cSpeed:Number = 0.0;
    ndt_test_results static var c2sSpeed:Number = 0.0;
    ndt_test_results static var userAgent:String = null;


    public static function get jitter():Number {
      return ndtVariables[NDTConstants.MAXRTT] -
             ndtVariables[NDTConstants.MINRTT];
    }
    public static function get duration():Number {
      return _ndtTestEndTime - _ndtTestStartTime;
    }
    public static function get testList():String {
       var testSuite:String = "";
       if(_requestedTests & TestType.C2S)
          testSuite += "CLIENT_TO_SERVER_THROUGHPUT\n";
       if(_requestedTests & TestType.S2C)
          testSuite += "SERVER_TO_CLIENT_THROUGHPUT\n";
       if(_requestedTests & TestType.META)
          testSuite += "META_TEST\n";
      return testSuite;
    }

    public static function recordStartTime():void {
      _ndtTestStartTime = getTimer();
    }
    public static function recordEndTime():void {
      _ndtTestEndTime = getTimer();
    }

    // Output handler functions
    public static function appendResultDetails(sParam:String):void {
      _resultDetails += sParam;
    }
    public static function appendErrMsg(msg:String):void {
      _errMsg += msg + "\n";
      NDTUtils.callExternalFunction("appendErrors", msg);
      appendDebugMsg(msg);
    }
    public static function appendDebugMsg(msg:String):void {
      if (!CONFIG::debug) {
          return;
      }
      _debugMsg += msg + "\n";
      NDTUtils.callExternalFunction("appendDebugOutput", msg);
      // _ndtTestStartTime > 0 ensures the console window has been created.
      // TODO: Verify if there is cleaner alternative.
      if (Main.guiEnabled && _ndtTestStartTime > 0)
        // TODO: Handle the communication with GUI via events, instead of
        // blocking calls.
        GUI.addConsoleOutput(msg + "\n");
    }

    public static function getDebugMsg():String {
      return _debugMsg;
    }
    public static function getResultDetails():String {
      return _resultDetails;
    }
    public static function getErrMsg():String {
      return _errMsg;
    }

    /**
     * Function that takes a Human readable string containing the results and
     * assigns the key-value pairs to the correct variables.
     * These values are then interpreted to make decisions about various
     * measurement items.
     * @param sTestResParam String containing the results as key-value pairs
     */
    public function interpretResults():void {
      var tokens:Array;
      var i:int = 0;
      var sSysvar:String, sStrval:String;
      var iSysval:int;
      var dSysval2:Number, j:Number;
      var sOsName:String, sOsArch:String, sFlashVer:String, sClient:String;
      var accessTech:String = null;

      // extract the key-value pairs
      tokens = _remoteTestResults.split(/\s/);
      sSysvar = null;
      sStrval = null;
      for each(var token:String in tokens) {
        if (!(i & 1)) {
          sSysvar = tokens[i].split(":")[0];
        }
        else {
          sStrval = tokens[i];
          _resultDetails += sSysvar + " " + sStrval + "\n";
          if (sStrval.indexOf(".") == -1) {
            // no decimal point hence an integer
            iSysval = parseInt(sStrval);
            if (isNaN(iSysval)) {
              // The value was probably too big for int
              // it may have been unsigned
              appendErrMsg("Error reading web100 var.");
              iSysval = -1;
            }
            // save value into a key value expected by us
            ndtVariables[sSysvar] = iSysval;
          } else {
            // if not aninteger, save as a double
            dSysval2 = parseFloat(sStrval);
            ndtVariables[sSysvar] = dSysval2;
          }
        }
        i++;
      }
      // Read client details from the SWF environment
      osName = Capabilities.os;
      osArchitecture = Capabilities.cpuArchitecture;
      flashVersion = Capabilities.version;
      if (osArchitecture.indexOf("x86") == 0)
        sClient = ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                  "pc", null, Main.locale);
      else
        sClient = ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                  "workstation",
                                                  null, Main.locale);

      // Calculate some variables and determine patch conditions
      // Note : Calculations now done by server and the results are
      // sent to the client for printing.
      if (ndtVariables[NDTConstants.COUNTRTT] > 0) {
        // Now write some messages to the screen
        // Access speed / technology details added to consoleOutput
        // and mailing text. Link speed is also assigned.
        if (ndtVariables[NDTConstants.C2SDATA] < NDTConstants.DATA_RATE_ETHERNET) {
          if (ndtVariables[NDTConstants.C2SDATA] < NDTConstants.DATA_RATE_RTT) {
            // data was not sufficient to determine bottleneck type
            _consoleOutput +=
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "unableToDetectBottleneck",
                                               null, Main.locale) + "\n";
            accessTech = "Connection type unknown";
          }
          else {
            // get link speed
            _consoleOutput +=
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "your", null, Main.locale)
              + " " + sClient + " "
              + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                "connectedTo", null, Main.locale)
              + " ";

            if (ndtVariables[NDTConstants.C2SDATA] == NDTConstants.DATA_RATE_DIAL_UP) {
              _consoleOutput +=
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                "dialup", null, Main.locale) + "\n";
              _mylink = 0.064;  // 64 kbps speed
              accessTech = "Dial-up Modem";
            }
            else {
              _consoleOutput +=
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                "cabledsl", null, Main.locale) + "\n";
              _mylink = 3;
              accessTech = "Cable/DSL modem";
            }
          }
        }
        else {
          _consoleOutput +=
            ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                            "theSlowestLink",
                                             null, Main.locale) + " ";
          switch(ndtVariables[NDTConstants.C2SDATA]) {
            case NDTConstants.DATA_RATE_ETHERNET :
                _consoleOutput +=
                  ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                  "10mbps", null, Main.locale) + "\n";
                _mylink = 10;
                accessTech = "10 Mbps Ethernet";
                break;
            case NDTConstants.DATA_RATE_T3 :
                _consoleOutput +=
                  ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                  "45mbps", null, Main.locale) + "\n";
                _mylink = 45;
                accessTech = "45 Mbps T3/DS3 subnet";
                break;
            case NDTConstants.DATA_RATE_FAST_ETHERNET :
                _consoleOutput += "100 Mbps ";
                _mylink = 100;
                accessTech = "100 Mbps Ethernet";
                // Fast ethernet. Determine if half/full duplex link was found
                if (ndtVariables[NDTConstants.HALF_DUPLEX] == 0) {
                  _consoleOutput +=
                    ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                    "fullDuplex",
                                                    null, Main.locale) + "\n";
                }
                else {
                  _consoleOutput +=
                    ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                    "halfDuplex",
                                                    null, Main.locale) + "\n";
                }
                break;
            case NDTConstants.DATA_RATE_OC_12 :
                _consoleOutput +=
                  ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                  "622mbps", null, Main.locale) + "\n";
                _mylink = 622;
                accessTech = "622 Mbps OC-12";
                break;
            case NDTConstants.DATA_RATE_GIGABIT_ETHERNET :
                _consoleOutput +=
                  ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                  "1gbps", null, Main.locale) + "\n";
                _mylink = 1000;
                accessTech = "1.0 Gbps Gigabit Ethernet";
                break;
            case NDTConstants.DATA_RATE_OC_48 :
                _consoleOutput +=
                  ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                  "2.4gbps", null, Main.locale) + "\n";
                _mylink = 2400;
                accessTech = "2.4 Gbps OC-48";
                break;
            case NDTConstants.DATA_RATE_10G_ETHERNET :
                _consoleOutput +=
                  ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                  "10gbps", null, Main.locale) + "\n";
                _mylink = 10000;
                accessTech = "10 Gigabit Ethernet/OC-192";
                break;
            default:
                _consoleOutput += "Undefined\n";
                _errMsg += "No ndtVariables[NDTConstants.C2SDATA] option match";
                break;
          }
        }
        switch(ndtVariables[NDTConstants.MISMATCH]) {
          case NDTConstants.DUPLEX_NOK_INDICATOR: //1
              _consoleOutput +=
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                "oldDuplexMismatch",
                                                null, Main.locale) + "\n";
              break;
          case NDTConstants.DUPLEX_SWITCH_FULL_HOST_HALF:
              _consoleOutput +=
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                "duplexFullHalf",
                                                null, Main.locale) + "\n";
              break;
          case NDTConstants.DUPLEX_SWITCH_HALF_HOST_FULL:
              _consoleOutput +=
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                "duplexHalfFull",
                                                null, Main.locale) + "\n";
              break;
          case NDTConstants.DUPLEX_SWITCH_FULL_HOST_HALF_POSS:
              _consoleOutput +=
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                "possibleDuplexFullHalf",
                                                null, Main.locale) + "\n";
              break;
          case NDTConstants.DUPLEX_SWITCH_HALF_HOST_FULL_POSS:
              _consoleOutput +=
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                "possibleDuplexHalfFull",
                                                null, Main.locale) + "\n";
              break;
          case NDTConstants.DUPLEX_SWITCH_HALF_HOST_FULL_WARN:
              _consoleOutput +=
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                "possibleDuplexHalfFullWarning",
                                                null, Main.locale) + "\n";
              break;
          case NDTConstants.DUPLEX_OK_INDICATOR:
              if (ndtVariables[NDTConstants.BAD_CABLE] == 1) {
                _consoleOutput +=
                  ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                  "excessiveErrors",
                                                  null, Main.locale) + "\n";
              }
              if (ndtVariables[NDTConstants.CONGESTION] == 1) {
                _consoleOutput +=
                  ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                  "otherTraffic",
                                                  null, Main.locale) + "\n";
              }
              // We seem to be transmitting less than link speed possibly due to
              // a receiver window setting (i.e calculated bandwidth is greater
              // than measured throughput). Advise appropriate size

              // Note: All comparisons henceforth of ((window size * 2/rttsec) < _mylink)
              // are along the same logic
              if (((2 * ndtVariables[NDTConstants.RWIN]) / ndtVariables[NDTConstants.RTTSEC]) < _mylink) {
                // multiplied by 2 to counter round-trip
                // Link speed is in Mbps. Convert it back to kbps (*1000),
                // and bytes (/8)
                j = Number(((_mylink * ndtVariables[NDTConstants.AVGRTT]) * NDTConstants.SEC2MSEC)) /
                           NDTConstants.BYTES2BITS / NDTConstants.KBITS2BITS;
                if (j > Number(ndtVariables[NDTConstants.MAXRWINRCVD])) {
                  _consoleOutput +=
                    ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                    "receiveBufferShouldBe",
                                                    null, Main.locale)
                    + " " + j.toFixed(2)
                    + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                      "toMaximizeThroughput",
                                                      null, Main.locale) + "\n";
                }
              }
              break;

          default: // default for indication of no match for mismatch variable
              break;
        }
        // C2S throughput test: Packet queueing
        if ((_requestedTests & TestType.C2S) == TestType.C2S) {
          if (sc2sSpeed < (c2sSpeed * (1.0 - NDTConstants.VIEW_DIFF))) {
            _consoleOutput +=
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "c2sPacketQueuingDetected",
                                              null, Main.locale) + "\n";
          }
        }
        // S2C throughput test: Packet queueing
        if ((_requestedTests & TestType.S2C) == TestType.S2C) {
          if (s2cSpeed < (ss2cSpeed * (1.0 - NDTConstants.VIEW_DIFF))) {
            _consoleOutput +=
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "s2cPacketQueuingDetected",
                                              null, Main.locale) + "\n";
          }
        }
        updateStatisticsText();
      } // end if countRTT > 0
    }

    /**
     * Function that updates the text to be shown in the statistics section.
     */
    public function updateStatisticsText():void {
      var pctRcvrLimited:Number = 0.0;
      var iZero:int = 0;
      // Add client information
      _statsText +=
        "\n\t-----  " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                        "clientInfo",
                                                        null, Main.locale) + "------\n";
      _statsText +=
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                        "osData", null, Main.locale)
        + " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                "name", null, Main.locale)
        + " & " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                  "version", null, Main.locale)
        + " = " + osName + ", "
        + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "architecture", null, Main.locale)
        + " = " + osArchitecture + "\n";
      _statsText +=
        "Flash Info: " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                 "version", null, Main.locale)
        + " = " + flashVersion + "\n";
        _statsText +=
          "\n\t------ " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                          "web100Details",
                                                          null, Main.locale)
          + " ------\n";

      // Now add data about access speeds / technology
      // Slightly different from the earlier switch
      // (that added data to the results pane) in that
      // negative values are checked for too.
      switch(ndtVariables[NDTConstants.C2SDATA]) {
        case NDTConstants.DATA_RATE_INSUFFICIENT_DATA :
            _statsText +=
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "insufficient",
                                              null, Main.locale) + "\n";
            break;
        case NDTConstants.DATA_RATE_SYSTEM_FAULT :
            _statsText +=
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "ipcFail", null, Main.locale) + "\n";
            break;
        case NDTConstants.DATA_RATE_RTT :
            _statsText +=
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "rttFail", null, Main.locale) + "\n";
            break;
        case NDTConstants.DATA_RATE_DIAL_UP :
            _statsText +=
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "foundDialup",
                                              null, Main.locale) + "\n";
            break;
        case NDTConstants.DATA_RATE_T1 :
            _statsText +=
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "foundDsl",
                                              null, Main.locale) + "\n";
            break;
        case NDTConstants.DATA_RATE_ETHERNET :
            _statsText +=
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "found10mbps",
                                              null, Main.locale) + "\n";
            break;
        case NDTConstants.DATA_RATE_T3 :
            _statsText +=
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "found45mbps",
                                              null, Main.locale) + "\n";
            break;
        case NDTConstants.DATA_RATE_FAST_ETHERNET :
            _statsText +=
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "found100mbps",
                                              null, Main.locale) + "\n";
            break;
        case NDTConstants.DATA_RATE_OC_12 :
            _statsText +=
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "found622mbps",
                                              null, Main.locale) + "\n";
            break;
        case NDTConstants.DATA_RATE_GIGABIT_ETHERNET :
            _statsText +=
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "found1gbps",
                                              null, Main.locale) + "\n";
            break;
        case NDTConstants.DATA_RATE_OC_48 :
            _statsText +=
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "found2.4gbps",
                                              null, Main.locale) + "\n";
            break;
        case NDTConstants.DATA_RATE_10G_ETHERNET :
            _statsText +=
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "found10gbps",
                                              null, Main.locale) + "\n";
            break;
      }
      // Add decisions about duplex mode, congestion and mismatch
      if (ndtVariables[NDTConstants.HALF_DUPLEX] == NDTConstants.DUPLEX_OK_INDICATOR)
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "linkFullDpx",
                                          null, Main.locale) + "\n";
      else
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "linkHalfDpx",
                                          null, Main.locale) + "\n";

      if (ndtVariables[NDTConstants.CONGESTION] == NDTConstants.CONGESTION_NONE)
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "congestNo",
                                          null, Main.locale) + "\n";
      else
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "congestYes",
                                          null, Main.locale) + "\n";

      if (ndtVariables[NDTConstants.BAD_CABLE] == NDTConstants.CABLE_STATUS_OK)
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "cablesOk", null, Main.locale) + "\n";
      else
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "cablesNok", null, Main.locale) + "\n";

      if (ndtVariables[NDTConstants.MISMATCH] == NDTConstants.DUPLEX_OK_INDICATOR)
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "duplexOk",
                                          null, Main.locale) + "\n";
      else if (ndtVariables[NDTConstants.MISMATCH] == NDTConstants.DUPLEX_NOK_INDICATOR) {
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "duplexNok",
                                          null, Main.locale) + " ";
      }
      else if (ndtVariables[NDTConstants.MISMATCH] == NDTConstants.DUPLEX_SWITCH_FULL_HOST_HALF) {
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "duplexFullHalf",
                                          null, Main.locale) + "\n";
      }
      else if (ndtVariables[NDTConstants.MISMATCH] == NDTConstants.DUPLEX_SWITCH_HALF_HOST_FULL) {
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "duplexHalfFull",
                                          null, Main.locale) + "\n";
      }

      _statsText +=
        "\n" + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                               "web100rtt", null, Main.locale)
        + " = " + (ndtVariables[NDTConstants.AVGRTT]).toFixed(2) + " ms; ";

      _statsText +=
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                        "packetsize", null, Main.locale)
        + " = " + ndtVariables[NDTConstants.CURMSS] + " "
        + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "bytes", null, Main.locale)
        + "; " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                 "and", null, Main.locale) + " \n";

      // check packet retransmissions count and update stats panel
      if (ndtVariables[NDTConstants.PKTSRETRANS] > 0) {
        // packet retransmissions found
        _statsText +=
          ndtVariables[NDTConstants.PKTSRETRANS] + " "
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                            "pktsRetrans", null, Main.locale);
        _statsText +=
          ", " + ndtVariables[NDTConstants.DUPACKSIN] + " "
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                            "dupAcksIn", null, Main.locale);
        _statsText +=
          ", " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                 "and", null, Main.locale)
          + " " + ndtVariables[NDTConstants.SACKSRCVD] + " "
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                            "sackReceived", null, Main.locale) + "\n";
      if (ndtVariables[NDTConstants.TIMEOUTS] > 0) {
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "connStalled", null, Main.locale)
          + " " + ndtVariables[NDTConstants.TIMEOUTS] + " "
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                            "timesPktLoss", null, Main.locale) + "\n";
      }

      _statsText +=
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                        "connIdle", null, Main.locale)
        + " " + (ndtVariables[NDTConstants.WAITSEC]).toFixed(2) + " "
        + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "seconds", null, Main.locale)
        + " (" + ((ndtVariables[NDTConstants.WAITSEC] / ndtVariables[NDTConstants.TIMESEC]) * NDTConstants.PERCENTAGE).toFixed(2)
        + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "pctOfTime", null, Main.locale) + ") \n";
      }
      else if (ndtVariables[NDTConstants.DUPACKSIN] > 0) {
        // No packet loss, but packets arrived out-of-order
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "noPktLoss1", null, Main.locale) + " - ";
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "ooOrder", null, Main.locale)
          + " " + (ndtVariables[NDTConstants.ORDER] * NDTConstants.PERCENTAGE).toFixed(2)
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                            "pctOfTime", null, Main.locale) + "\n";
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "noPktLoss1", null, Main.locale) + " - ";
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "ooOrder", null, Main.locale)
          + " " + (ndtVariables[NDTConstants.ORDER] * NDTConstants.PERCENTAGE).toFixed(2)
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                            "pctOfTime", null, Main.locale) + "\n%0A";
      }
      else {
        // No packet retransmissions found
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "noPktLoss2", null, Main.locale) + ".\n";
      }

      // Add Packet queueing details found during C2S throughput test to the
      // stats pane. Data is displayed as percentage
      if ((_requestedTests & TestType.C2S) == TestType.C2S) {
        if (c2sSpeed > sc2sSpeed) {
          if (sc2sSpeed < (c2sSpeed * (1.0 - NDTConstants.VIEW_DIFF))) {
            _statsText +=
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "c2s", null, Main.locale)
              + " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                      "qSeen", null, Main.locale)
              + ": " + (NDTConstants.PERCENTAGE *
                         (c2sSpeed - sc2sSpeed) / c2sSpeed).toFixed(2) + "%\n";
          }
          else {
            _statsText +=
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "c2s", null, Main.locale)
              + " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                      "qSeen", null, Main.locale)
              + ": " + (NDTConstants.PERCENTAGE *
                         (c2sSpeed - sc2sSpeed) / c2sSpeed).toFixed(2) + "%\n";
          }
        }
      }

      // Add packet queueing details found during S2C throughput test to
      // the statistics pane. Data is displayed as a percentage.
      if ((_requestedTests & TestType.S2C) == TestType.S2C) {
        if (ss2cSpeed > s2cSpeed) {
          if (ss2cSpeed < (ss2cSpeed * (1.0 - NDTConstants.VIEW_DIFF))) {
            _statsText +=
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "s2c", null, Main.locale)
              + " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                      "qSeen", null, Main.locale)
              + ": " + (NDTConstants.PERCENTAGE *
                         (ss2cSpeed - s2cSpeed) / ss2cSpeed).toFixed(2) + "%\n";
          }
          else {
            _statsText +=
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "s2c", null, Main.locale)
              + " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                      "qSeen", null, Main.locale)
              + ": " + (NDTConstants.PERCENTAGE *
                         (ss2cSpeed - s2cSpeed) / ss2cSpeed).toFixed(2) + "%\n";
          }
        }
      }

      // Add connection details to the statistics pane
      // Is the connection receiver limited ?
      if (ndtVariables[NDTConstants.RWINTIME] > NDTConstants.SND_LIM_TIME_THRESHOLD) {
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "thisConnIs", null, Main.locale)
          + " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                  "limitRx", null, Main.locale)
          + " " + (ndtVariables[NDTConstants.RWINTIME] * NDTConstants.PERCENTAGE).toFixed(2)
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                            "pctOfTime", null, Main.locale) + ".\n";
        pctRcvrLimited = ndtVariables[NDTConstants.RWINTIME] * NDTConstants.PERCENTAGE;
        if (((2 * ndtVariables[NDTConstants.RWIN]) / ndtVariables[NDTConstants.RTTSEC]) < _mylink) {
          // multiplying by 2 to counter round-trip
          _statsText +=
            " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                  "incrRxBuf", null, Main.locale)
            + " (" + (ndtVariables[NDTConstants.MAXRWINRCVD] / NDTConstants.KBITS2BITS).toFixed(2)
            + " KB)" + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                       "willImprove",
                                                       null, Main.locale) + "\n";
        }
      }
      // Is the connection sender limited ?
      if (ndtVariables[NDTConstants.SENDTIME] > NDTConstants.SND_LIM_TIME_THRESHOLD) {
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "thisConnIs", null, Main.locale)
          + " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                  "limitTx", null, Main.locale)
          + " " + (ndtVariables[NDTConstants.SENDTIME] * NDTConstants.PERCENTAGE).toFixed(2)
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                            "pctOfTime", null, Main.locale) + ".\n";

        if ((2 * (ndtVariables[NDTConstants.SWIN] / ndtVariables[NDTConstants.RTTSEC])) < _mylink) {
          // dividing by 2 to counter round-trip
          _statsText +=
            " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                  "incrRxBuf", null, Main.locale)
            + " (" + (ndtVariables[NDTConstants.SNDBUF] / (2 * NDTConstants.KBITS2BITS)).toFixed(2)
            + " KB)" + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                       "willImprove",
                                                       null, Main.locale) + "\n";
        }
      }

      // Is the connection network limited ?
        // If the congestion windows is limited more than 0.5%
        // of the time, NDT claims that the connection is network
        // limited.
      if (ndtVariables[NDTConstants.CWNDTIME] > 0.005) {
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "thisConnIs", null, Main.locale)
          + " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                  "limitNet", null, Main.locale)
          + " " + (ndtVariables[NDTConstants.CWNDTIME] * NDTConstants.PERCENTAGE).toFixed(2)
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                            "pctOfTime", null, Main.locale) + "\n";
      }

      // Is the loss excessive ?
      // If the link speed is less than a T3, and loss is greater than 1 percent,
      // loss is determined to be excessive.
      if ((ndtVariables[NDTConstants.SPD] < 4) && (ndtVariables[NDTConstants.LOSS] > 0.01))
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "excLoss", null, Main.locale) + "\n";

      // Update statistics on TCP negotiated optional Performance Settings
      _statsText +=
        "\n" + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                               "web100tcpOpts",
                                               null, Main.locale) + "\n";
      _statsText += "RFC 2018 Selective Acknowledgement: ";
      if (ndtVariables[NDTConstants.SACKENABLED] == iZero)
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "off", null, Main.locale) + "\n";
      else
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "on", null, Main.locale) + "\n";

      _statsText += "RFC 896 Nagle Algorithm: ";
      if (ndtVariables[NDTConstants.NAGLEENABLED] == iZero)
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "off", null, Main.locale) + "\n";
      else
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "on", null, Main.locale) + "\n";

      _statsText += "RFC 3168 Excplicit Congestion Notification: ";
      if (ndtVariables[NDTConstants.ECNENABLED] == iZero)
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "off", null, Main.locale) + "\n";
      else
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "on", null, Main.locale) + "\n";

      _statsText += "RFC 1323 Time Stamping: ";
      if (ndtVariables[NDTConstants.TIMESTAMPSENABLED] == NDTConstants.RFC_1323_DISABLED)
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "off", null, Main.locale) + "\n";
      else
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "on", null, Main.locale) + "\n";

      _statsText += "RFC 1323 Window Scaling: ";
      if (ndtVariables[NDTConstants.MAXRWINRCVD] < NDTConstants.TCP_MAX_RECV_WIN_SIZE)
        ndtVariables[NDTConstants.WINSCALERCVD] = 0; // Max rec window size lesser than TCP's max
                            // value, so no scaling requested

      // According to RFC1323, Section 2.3 the max valid value of iWinScaleRcvd is 14.
      // NDT uses 20 for this, leaving for now in case it is an error value. May need
      // to be inspected again.
      if ((ndtVariables[NDTConstants.WINSCALERCVD] == 0) || (ndtVariables[NDTConstants.WINSCALERCVD] > 20))
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "off", null, Main.locale) + "\n";
      else
        _statsText +=
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "on", null, Main.locale)
          + "; " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                   "scalingFactors",
                                                   null, Main.locale)
          + " -  " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                    "server", null, Main.locale)
          + "=" + ndtVariables[NDTConstants.WINSCALERCVD] + ", "
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                            "client", null, Main.locale)
          + "=" + ndtVariables[NDTConstants.WINSCALESENT] + "\n";
      _statsText += "\n";
      // End tcp negotiated performance settings
      addMoreDetails();
    }

    private function addMoreDetails():void {
      // Adding more details to the diagnostic text, related
      // to factors influencing throughput
      _resultDetails += "\n";
      // Theoretical network limit
      _resultDetails +=
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                        "theoreticalLimit", null, Main.locale)
        + " " + (ndtVariables[NDTConstants.BW]).toFixed(2) + " " + "Mbps\n";
    // NDT server buffer imposed limit
      // divide by 2 to counter "round-trip" time
      _resultDetails +=
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                        "ndtServerHas", null, Main.locale)
        + " " + (ndtVariables[NDTConstants.SNDBUF] / (2 * NDTConstants.KBITS2BITS)).toFixed(2) + " "
        + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "kbyteBufferLimits", null, Main.locale)
        + " " + (ndtVariables[NDTConstants.SWIN] / ndtVariables[NDTConstants.RTTSEC]).toFixed(2) + " Mbps\n";
      // PC buffer imposed throughput limit
      _resultDetails +=
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                        "yourPcHas", null, Main.locale)
        + " " + (ndtVariables[NDTConstants.MAXRWINRCVD] / NDTConstants.KBITS2BITS).toFixed(2) + " "
        + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "kbyteBufferLimits", null, Main.locale)
        + " " + (ndtVariables[NDTConstants.RWIN] / ndtVariables[NDTConstants.RTTSEC]).toFixed(2) + " Mbps\n";
      // Network based flow control limit imposed throughput limit
      _resultDetails +=
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                        "flowControlLimits", null, Main.locale)
        + " " + (ndtVariables[NDTConstants.CWIN] / ndtVariables[NDTConstants.RTTSEC]).toFixed(2) + " Mbps\n";

      // Client, Server data reports on link capacity
      if (TestResultsUtils.getDataRateString(ndtVariables[NDTConstants.C2SDATA]) == null
         || TestResultsUtils.getDataRateString(ndtVariables[NDTConstants.C2SACK]) == null
         || TestResultsUtils.getDataRateString(ndtVariables[NDTConstants.S2CDATA]) == null
         || TestResultsUtils.getDataRateString(ndtVariables[NDTConstants.S2CACK]) == null)
      {
        _errMsg += "Error ! No matching data rate value found.\n";
      }
      _resultDetails +=
      "\n" + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                             "clientDataReports", null, Main.locale)
      + " '" + TestResultsUtils.getDataRateString(ndtVariables[NDTConstants.C2SDATA]) + "', "
      + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                        "clientAcksReport", null, Main.locale)
      + " '" + TestResultsUtils.getDataRateString(ndtVariables[NDTConstants.C2SACK]) + "'\n"
      + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                        "serverDataReports", null, Main.locale)
      + " '" + TestResultsUtils.getDataRateString(ndtVariables[NDTConstants.S2CDATA]) + "', "
      + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                        "serverAcksReport", null, Main.locale)
      + " '" + TestResultsUtils.getDataRateString(ndtVariables[NDTConstants.S2CACK]) + "'\n";
      NDTUtils.callExternalFunction("resultsProcessed");
    }

    private function onReceivedData(e:ProgressEvent):void {
      getRemoteResults();
    }
    private function addOnReceivedDataListener():void {
      _ctlSocket.addEventListener(ProgressEvent.SOCKET_DATA, onReceivedData);
    }
    private function removeOnReceivedDataListener():void {
      _ctlSocket.removeEventListener(ProgressEvent.SOCKET_DATA, onReceivedData);
    }
    private function addOnReadTimeout():void {
      _readResultsTimer.reset();
      _readResultsTimer.addEventListener(TimerEvent.TIMER, onReadTimeout);
      _readResultsTimer.start();
    }
    private function onReadTimeout(e:TimerEvent):void {
      _readResultsTimer.stop();
      TestResults.appendErrMsg("Read timeout while reading results.");
      _callerObj.failNDTTest();
    }


    public function receiveRemoteResults():void {
      addOnReadTimeout();
      addOnReceivedDataListener();
      // In case data arrived before starting the onReceiveData listener.
       if (_ctlSocket.bytesAvailable > 0) {
          getRemoteResults();
       }
      }

   /**
     * Function that reads the rest of the server calculated
     * results and appends them to the test results String
     * for interpretation.
     */
     private function getRemoteResults():void {
      _remoteTestResults = s2cTestResults;
      var msg:Message = new Message();
      while (_ctlSocket.bytesAvailable > 0) {
        if (msg.receiveMessage(_ctlSocket) !=
            NDTConstants.PROTOCOL_MSG_READ_SUCCESS) {
          TestResults.appendErrMsg(
              ResourceManager.getInstance().getString(
                  NDTConstants.BUNDLE_NAME, "protocolError", null, Main.locale)
            + parseInt(new String(msg.body), 16)
            + " instead");
          ndtTestFailed = true;
          _readResultsTimer.stop();
          return;
        }
        // all results obtained. "Log Out" message received now
        if (msg.type == MessageType.MSG_LOGOUT) {
          _readResultsTimer.stop();
          removeOnReceivedDataListener();
          _callerObj.finishedAll();
        }
        // get results in the form of a human-readable string
        if (msg.type != MessageType.MSG_RESULTS) {
          TestResults.appendErrMsg(
            ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "resultsWrongMessage", null,Main.locale)
            + "\n");
          ndtTestFailed = true;
          _readResultsTimer.stop();
          return;
        }
        _remoteTestResults += new String(msg.body);
      }
    }

    /**
     * Constructor that initializes the values and calls the function to start
     * interpreting the results.
     */
    public function TestResults(
        socket:Socket, requestedTests:int, callerObject:NDTPController) {
      _ctlSocket = socket;
      _requestedTests = requestedTests;
      _callerObj = callerObject;
    }
  }
}

