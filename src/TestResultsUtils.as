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
  import flash.system.Capabilities;
  import mx.resources.ResourceManager;

  public class TestResultsUtils {
    /**
     *  Return text representation of data speed values.
     */
    public static function getDataRateString(dataRateInt:int):String {
      switch (dataRateInt) {
      case NDTConstants.DATA_RATE_SYSTEM_FAULT:
        return ResourceManager.getInstance().getString(
	    NDTConstants.BUNDLE_NAME, "systemFault", null, Main.locale);
      case NDTConstants.DATA_RATE_RTT:
        return ResourceManager.getInstance().getString(
	    NDTConstants.BUNDLE_NAME, "rtt", null, Main.locale);
      case NDTConstants.DATA_RATE_DIAL_UP:
        return ResourceManager.getInstance().getString(
	    NDTConstants.BUNDLE_NAME, "dialup2", null, Main.locale);
      case NDTConstants.DATA_RATE_T1:
        return ResourceManager.getInstance().getString(
	    NDTConstants.BUNDLE_NAME, "t1Str", null, Main.locale);
      case NDTConstants.DATA_RATE_ETHERNET:
        return ResourceManager.getInstance().getString(
	    NDTConstants.BUNDLE_NAME, "ethernetStr", null, Main.locale);
      case NDTConstants.DATA_RATE_T3:
        return ResourceManager.getInstance().getString(
	    NDTConstants.BUNDLE_NAME, "t3Str", null, Main.locale);
      case NDTConstants.DATA_RATE_FAST_ETHERNET:
        return ResourceManager.getInstance().getString(
	    NDTConstants.BUNDLE_NAME, "fastEthernet", null, Main.locale);
      case NDTConstants.DATA_RATE_OC_12:
        return ResourceManager.getInstance().getString(
	    NDTConstants.BUNDLE_NAME, "oc12Str", null, Main.locale);
      case NDTConstants.DATA_RATE_GIGABIT_ETHERNET:
        return ResourceManager.getInstance().getString(
	    NDTConstants.BUNDLE_NAME, "gigabitEthernetStr", null, Main.locale);
      case NDTConstants.DATA_RATE_OC_48:
        return ResourceManager.getInstance().getString(
	    NDTConstants.BUNDLE_NAME, "oc48Str", null, Main.locale);
      case NDTConstants.DATA_RATE_10G_ETHERNET:
        return ResourceManager.getInstance().getString(
	    NDTConstants.BUNDLE_NAME, "tengigabitEthernetStr", null,
	    Main.locale);
      }
      return null;
    }

    /**
     * Function that return a variable corresponding to the parameter passed to
     * it as a request.
     * @param {String} The parameter which the caller is seeking.
     * @return {String} The value of the desired parameter.
     */
    public static function getNDTVariable(varName:String):String {
      switch(varName) {
        case "TestList":
          return TestResults.testList;
        case "TestDuration":
          return TestResults.duration.toString();
        case "ClientToServerSpeed":
          return TestResults.ndt_test_results::c2sSpeed.toString();
        case "ServerToClientSpeed":
          return TestResults.ndt_test_results::s2cSpeed.toString();
        case "Jitter":
          return TestResults.jitter.toString();
        case "OperatingSystem":
          return Capabilities.os;
        case "ClientVersion":
          return NDTConstants.CLIENT_VERSION;
        case "FlashVersion":
          return Capabilities.version;
        case "OsArchitecture":
          return Capabilities.cpuArchitecture;
      }
      if (varName in TestResults.ndtVariables) {
        return TestResults.ndtVariables[varName].toString();
      }
      return null;
    }

    public static function appendDuplexMismatchResult(
        duplexIndicator:int):void {
      switch(duplexIndicator) {
        case NDTConstants.DUPLEX_NOK_INDICATOR:
          TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(
                  NDTConstants.BUNDLE_NAME, "oldDuplexMismatch", null,
                  Main.locale));
          break;
        case NDTConstants.DUPLEX_SWITCH_FULL_HOST_HALF:
          TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(
                  NDTConstants.BUNDLE_NAME, "duplexFullHalf", null,
                  Main.locale));
          break;
        case NDTConstants.DUPLEX_SWITCH_HALF_HOST_FULL:
          TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(
                  NDTConstants.BUNDLE_NAME, "duplexHalfFull", null,
                  Main.locale));
          break;
        case NDTConstants.DUPLEX_SWITCH_FULL_HOST_HALF_POSS:
          TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(
                  NDTConstants.BUNDLE_NAME, "possibleDuplexFullHalf", null,
                  Main.locale));
          break;
        case NDTConstants.DUPLEX_SWITCH_HALF_HOST_FULL_POSS:
          TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(
                  NDTConstants.BUNDLE_NAME, "possibleDuplexHalfFull", null,
                  Main.locale));
          break;
        case NDTConstants.DUPLEX_SWITCH_HALF_HOST_FULL_WARN:
          TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(
                  NDTConstants.BUNDLE_NAME, "possibleDuplexHalfFullWarning",
                  null, Main.locale));
          break;
        case NDTConstants.DUPLEX_OK_INDICATOR:
          appendCableStatusResult();
          appendCongestionResult();
	  appendRecommendedBufferSize();
          break;
        default:
          TestResults.appendErrMsg("Non valid duplex indicator");
      }
    }
    private static function appendCableStatusResult():void {
      if (TestResults.ndtVariables[NDTConstants.BAD_CABLE] ==
          NDTConstants.CABLE_STATUS_NOK)
        TestResults.appendResultDetails(ResourceManager.getInstance().getString(
            NDTConstants.BUNDLE_NAME, "excessiveErrors", null, Main.locale));
    }

    private static function appendCongestionResult():void {
      if (TestResults.ndtVariables[NDTConstants.CONGESTION] ==
          NDTConstants.CONGESTION_YES)
        TestResults.appendResultDetails(ResourceManager.getInstance().getString(
            NDTConstants.BUNDLE_NAME, "otherTraffic", null, Main.locale));
    }

    private static function appendRecommendedBufferSize():void {
      // If we seem to be transmitting less than link speed (i.e calculated
      // bandwidth is greater than measured throughput), it is possibly due to a
      // receiver window setting. Advise appropriate size.
      // Note: All comparisons henceforth of ((window size * 2/rttsec) < TestResults.ndt_test_results::mylink)
      // are along the same logic.
      // TODO: Clean up.
      if (((2 * TestResults.ndtVariables[NDTConstants.RWIN]) /
          TestResults.ndtVariables[NDTConstants.RTTSEC]) < TestResults.ndt_test_results::mylink) {
        // Multiplied by 2 to counter round-trip
        // Link speed is in Mbps. Convert it back to kbps (*1000) and bytes (/8)
        var j:Number = Number(((TestResults.ndt_test_results::mylink *
                     TestResults.ndtVariables[NDTConstants.AVGRTT]) *
                     NDTConstants.SEC2MSEC)) /
                   NDTConstants.BYTES2BITS / NDTConstants.KBITS2BITS;
        if (j > Number(TestResults.ndtVariables[NDTConstants.MAXRWINRCVD]))
          TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(
                  NDTConstants.BUNDLE_NAME, "receiveBufferShouldBe", null,
                  Main.locale) +
              " " + j.toFixed(2) +
              ResourceManager.getInstance().getString(
                  NDTConstants.BUNDLE_NAME, "toMaximizeThroughput", null,
                  Main.locale));
      }
    }

    public static function appendC2SPacketQueueingResult():void {
      if (TestResults.ndt_test_results::sc2sSpeed <
          (TestResults.ndt_test_results::c2sSpeed * (1.0 - NDTConstants.SPD_DIFF)))
        TestResults.appendResultDetails(
            ResourceManager.getInstance().getString(
                NDTConstants.BUNDLE_NAME, "c2sPacketQueuingDetected", null,
                Main.locale));
    }

    public static function appendS2CPacketQueueingResult():void {
       if (TestResults.ndt_test_results::s2cSpeed <
           (TestResults.ndt_test_results::ss2cSpeed * (1.0 - NDTConstants.SPD_DIFF)))
         TestResults.appendResultDetails(
             ResourceManager.getInstance().getString(
                 NDTConstants.BUNDLE_NAME, "s2cPacketQueuingDetected", null,
                 Main.locale));
    }

    public static function appendClientInfo():void {
      TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "clientInfo", null, Main.locale));
      TestResults.appendResultDetails(
        ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "osData", null, Main.locale)
        + " " + ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "name", null, Main.locale)
        + " & " + ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "version", null, Main.locale)
        + " = " + Capabilities.os + ", "
        + ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "architecture", null, Main.locale)
        + " = " + Capabilities.cpuArchitecture);
      TestResults.appendResultDetails(
        "Flash Info: " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                 "version", null, Main.locale)
        + " = " + Capabilities.version);
        TestResults.appendResultDetails(
          "\n\t------ " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                          "web100Details",
                                                          null, Main.locale)
          + " ------");
    }

    public static function getAccessLinkSpeed():void {
        if (TestResults.ndtVariables[NDTConstants.C2SDATA] < NDTConstants.DATA_RATE_ETHERNET) {
          if (TestResults.ndtVariables[NDTConstants.C2SDATA] < NDTConstants.DATA_RATE_RTT) {
            // data was not sufficient to determine bottleneck type
            TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "unableToDetectBottleneck",
                                               null, Main.locale));
            TestResults.accessTech = "Connection type unknown";
          }
          else {
            // get link speed
            TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "your", null, Main.locale)
              + " " + getClient(Capabilities.cpuArchitecture) + " "
              + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                "connectedTo", null, Main.locale));

            if (TestResults.ndtVariables[NDTConstants.C2SDATA] == NDTConstants.DATA_RATE_DIAL_UP) {
              TestResults.appendResultDetails(
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                "dialup", null, Main.locale));
              TestResults.ndt_test_results::mylink = 0.064;  // 64 kbps speed
              TestResults.accessTech = "Dial-up Modem";
            }
            else {
              TestResults.appendResultDetails(
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                "cabledsl", null, Main.locale));
              TestResults.ndt_test_results::mylink = 3;
              TestResults.accessTech = "Cable/DSL modem";
            }
          }
        }
        else
          appendSlowestLinkResult();
    }

    private static function appendSlowestLinkResult():void {
      TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(
              NDTConstants.BUNDLE_NAME, "theSlowestLink", null, Main.locale)
          + " ");
      switch(TestResults.ndtVariables[NDTConstants.C2SDATA]) {
        case NDTConstants.DATA_RATE_ETHERNET:
          TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(
                  NDTConstants.BUNDLE_NAME, "10mbps", null, Main.locale));
          TestResults.ndt_test_results::mylink = 10;
          TestResults.accessTech = "10 Mbps Ethernet";
          break;
        case NDTConstants.DATA_RATE_T3 :
          TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(
                  NDTConstants.BUNDLE_NAME, "45mbps", null, Main.locale));
          TestResults.ndt_test_results::mylink = 45;
          TestResults.accessTech = "45 Mbps T3/DS3 subnet";
          break;
        case NDTConstants.DATA_RATE_FAST_ETHERNET :
          TestResults.appendResultDetails("100 Mbps ");
          TestResults.ndt_test_results::mylink = 100;
          TestResults.accessTech = "100 Mbps Ethernet";
          // Fast ethernet. Determine if half/full duplex link was found
          if (TestResults.ndtVariables[NDTConstants.HALF_DUPLEX] == 0)
              TestResults.appendResultDetails(
                  ResourceManager.getInstance().getString(
                      NDTConstants.BUNDLE_NAME, "fullDuplex", null, Main.locale));
          else
              TestResults.appendResultDetails(
                  ResourceManager.getInstance().getString(
                      NDTConstants.BUNDLE_NAME, "halfDuplex", null, Main.locale));
          break;
        case NDTConstants.DATA_RATE_OC_12:
          TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(
                  NDTConstants.BUNDLE_NAME, "622mbps", null, Main.locale));
           TestResults.ndt_test_results::mylink = 622;
           TestResults.accessTech = "622 Mbps OC-12";
           break;
         case NDTConstants.DATA_RATE_GIGABIT_ETHERNET:
           TestResults.appendResultDetails(
               ResourceManager.getInstance().getString(
                   NDTConstants.BUNDLE_NAME, "1gbps", null, Main.locale));
           TestResults.ndt_test_results::mylink = 1000;
           TestResults.accessTech = "1.0 Gbps Gigabit Ethernet";
           break;
         case NDTConstants.DATA_RATE_OC_48:
           TestResults.appendResultDetails(
               ResourceManager.getInstance().getString(
                   NDTConstants.BUNDLE_NAME, "2.4gbps", null, Main.locale));
           TestResults.ndt_test_results::mylink = 2400;
           TestResults.accessTech = "2.4 Gbps OC-48";
           break;
         case NDTConstants.DATA_RATE_10G_ETHERNET:
           TestResults.appendResultDetails(
               ResourceManager.getInstance().getString(
                   NDTConstants.BUNDLE_NAME, "10gbps", null, Main.locale));
           TestResults.ndt_test_results::mylink = 10000;
           TestResults.accessTech = "10 Gigabit Ethernet/OC-192";
           break;
         default:
           TestResults.appendResultDetails("Undefined");
           TestResults.appendErrMsg("Non valid calue for NDTConstants.C2SDATA");
      }
    }
    public static function getClient(osArchitecture:String):String {
      if (osArchitecture.indexOf("x86") == 0)
        return ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                       "pc", null, Main.locale);
      else
        return ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                       "workstation", null,
                                                       Main.locale);
    }

    // Now add data about access speeds / technology
    // Slightly different from the earlier switch
    // (that added data to the results pane) in that
    // negative values are checked for too.
    public static function appendDataRateResults():void {
      switch(TestResults.ndtVariables[NDTConstants.C2SDATA]) {
        case NDTConstants.DATA_RATE_INSUFFICIENT_DATA :
            TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "insufficient",
                                              null, Main.locale));
            break;
        case NDTConstants.DATA_RATE_SYSTEM_FAULT :
            TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "ipcFail", null, Main.locale));
            break;
        case NDTConstants.DATA_RATE_RTT :
            TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "rttFail", null, Main.locale));
            break;
        case NDTConstants.DATA_RATE_DIAL_UP :
            TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "foundDialup",
                                              null, Main.locale));
            break;
        case NDTConstants.DATA_RATE_T1 :
            TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "foundDsl",
                                              null, Main.locale));
            break;
        case NDTConstants.DATA_RATE_ETHERNET :
            TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "found10mbps",
                                              null, Main.locale));
            break;
        case NDTConstants.DATA_RATE_T3 :
            TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "found45mbps",
                                              null, Main.locale));
            break;
        case NDTConstants.DATA_RATE_FAST_ETHERNET :
            TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "found100mbps",
                                              null, Main.locale));
            break;
        case NDTConstants.DATA_RATE_OC_12 :
            TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "found622mbps",
                                              null, Main.locale));
            break;
        case NDTConstants.DATA_RATE_GIGABIT_ETHERNET :
            TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "found1gbps",
                                              null, Main.locale));
            break;
        case NDTConstants.DATA_RATE_OC_48 :
            TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "found2.4gbps",
                                              null, Main.locale));
            break;
        case NDTConstants.DATA_RATE_10G_ETHERNET :
            TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "found10gbps",
                                              null, Main.locale));
            break;
      }
   }

   // Add decisions about duplex mode, congestion and mismatch
   public static function appendDuplexCongestionMismatchResults():void {
      if (TestResults.ndtVariables[NDTConstants.HALF_DUPLEX] == NDTConstants.DUPLEX_OK_INDICATOR)
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "linkFullDpx",
                                          null, Main.locale));
      else
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "linkHalfDpx",
                                          null, Main.locale));

      if (TestResults.ndtVariables[NDTConstants.CONGESTION] == NDTConstants.CONGESTION_NONE)
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "congestNo",
                                          null, Main.locale));
      else
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "congestYes",
                                          null, Main.locale));

      if (TestResults.ndtVariables[NDTConstants.BAD_CABLE] == NDTConstants.CABLE_STATUS_OK)
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "cablesOk", null, Main.locale));
      else
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "cablesNok", null, Main.locale));

      if (TestResults.ndtVariables[NDTConstants.MISMATCH] == NDTConstants.DUPLEX_OK_INDICATOR)
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "duplexOk",
                                          null, Main.locale));
      else if (TestResults.ndtVariables[NDTConstants.MISMATCH] == NDTConstants.DUPLEX_NOK_INDICATOR) {
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "duplexNok",
                                          null, Main.locale));
      }
      else if (TestResults.ndtVariables[NDTConstants.MISMATCH] == NDTConstants.DUPLEX_SWITCH_FULL_HOST_HALF) {
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "duplexFullHalf",
                                          null, Main.locale));
      }
      else if (TestResults.ndtVariables[NDTConstants.MISMATCH] == NDTConstants.DUPLEX_SWITCH_HALF_HOST_FULL) {
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "duplexHalfFull",
                                          null, Main.locale));
      }
   }
   // check packet retransmissions count and update stats panel
   public static function appendPacketRetrasmissionResults():void {
      if (TestResults.ndtVariables[NDTConstants.PKTSRETRANS] > 0) {
        // packet retransmissions found
        TestResults.appendResultDetails(
          TestResults.ndtVariables[NDTConstants.PKTSRETRANS] + " "
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                            "pktsRetrans", null, Main.locale));
        TestResults.appendResultDetails(
          ", " + TestResults.ndtVariables[NDTConstants.DUPACKSIN] + " "
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                            "dupAcksIn", null, Main.locale));
        TestResults.appendResultDetails(
          ", " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                 "and", null, Main.locale)
          + " " + TestResults.ndtVariables[NDTConstants.SACKSRCVD] + " "
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                            "sackReceived", null, Main.locale));
      if (TestResults.ndtVariables[NDTConstants.TIMEOUTS] > 0) {
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "connStalled", null, Main.locale)
          + " " + TestResults.ndtVariables[NDTConstants.TIMEOUTS] + " "
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                            "timesPktLoss", null, Main.locale));
      }

      TestResults.appendResultDetails(
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                        "connIdle", null, Main.locale)
        + " " + (TestResults.ndtVariables[NDTConstants.WAITSEC]).toFixed(2) + " "
        + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "seconds", null, Main.locale)
        + " (" + ((TestResults.ndtVariables[NDTConstants.WAITSEC] / TestResults.ndtVariables[NDTConstants.TIMESEC]) * NDTConstants.PERCENTAGE).toFixed(2)
        + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "pctOfTime", null, Main.locale) + ")");
      }
      else if (TestResults.ndtVariables[NDTConstants.DUPACKSIN] > 0) {
        // No packet loss, but packets arrived out-of-order
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "noPktLoss1", null, Main.locale) + " - ");
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "ooOrder", null, Main.locale)
          + " " + (TestResults.ndtVariables[NDTConstants.ORDER] * NDTConstants.PERCENTAGE).toFixed(2)
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                            "pctOfTime", null, Main.locale));
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "noPktLoss1", null, Main.locale) + " - ");
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "ooOrder", null, Main.locale)
          + " " + (TestResults.ndtVariables[NDTConstants.ORDER] * NDTConstants.PERCENTAGE).toFixed(2)
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                            "pctOfTime", null, Main.locale) + "\n%0A");
      }
      else {
        // No packet retransmissions found
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "noPktLoss2", null, Main.locale) + ".");
      }
   }

   public static function appendPacketQueueingResults(requestedTests:int):void {
      // Add Packet queueing details found during C2S throughput test to the
      // stats pane. Data is displayed as percentage
      if ((requestedTests & TestType.C2S) == TestType.C2S) {
        if (TestResults.ndt_test_results::c2sSpeed > TestResults.ndt_test_results::sc2sSpeed) {
          if (TestResults.ndt_test_results::sc2sSpeed < (TestResults.ndt_test_results::c2sSpeed * (1.0 - NDTConstants.SPD_DIFF))) {
            TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "c2s", null, Main.locale)
              + " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                      "qSeen", null, Main.locale)
              + ": " + (NDTConstants.PERCENTAGE *
                         (TestResults.ndt_test_results::c2sSpeed - TestResults.ndt_test_results::sc2sSpeed) / TestResults.ndt_test_results::c2sSpeed).toFixed(2) + "%");
          }
          else {
            TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "c2s", null, Main.locale)
              + " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                      "qSeen", null, Main.locale)
              + ": " + (NDTConstants.PERCENTAGE *
                         (TestResults.ndt_test_results::c2sSpeed - TestResults.ndt_test_results::sc2sSpeed) / TestResults.ndt_test_results::c2sSpeed).toFixed(2) + "%");
          }
        }
      }

      // Add packet queueing details found during S2C throughput test to
      // the statistics pane. Data is displayed as a percentage.
      if ((requestedTests & TestType.S2C) == TestType.S2C) {
        if (TestResults.ndt_test_results::ss2cSpeed > TestResults.ndt_test_results::s2cSpeed) {
          if (TestResults.ndt_test_results::ss2cSpeed < (TestResults.ndt_test_results::ss2cSpeed * (1.0 - NDTConstants.SPD_DIFF))) {
            TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "s2c", null, Main.locale)
              + " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                      "qSeen", null, Main.locale)
              + ": " + (NDTConstants.PERCENTAGE *
                         (TestResults.ndt_test_results::ss2cSpeed - TestResults.ndt_test_results::s2cSpeed) / TestResults.ndt_test_results::ss2cSpeed).toFixed(2) + "%");
          }
          else {
            TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "s2c", null, Main.locale)
              + " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                      "qSeen", null, Main.locale)
              + ": " + (NDTConstants.PERCENTAGE *
                         (TestResults.ndt_test_results::ss2cSpeed - TestResults.ndt_test_results::s2cSpeed) / TestResults.ndt_test_results::ss2cSpeed).toFixed(2) + "%");
          }
        }
      }
   }

   public static function appendBottleneckResults():void {
     // Is the connection receiver limited ?
      if (TestResults.ndtVariables[NDTConstants.RWINTIME] > NDTConstants.SND_LIM_TIME_THRESHOLD) {
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "thisConnIs", null, Main.locale)
          + " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                  "limitRx", null, Main.locale)
          + " " + (TestResults.ndtVariables[NDTConstants.RWINTIME] * NDTConstants.PERCENTAGE).toFixed(2)
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                            "pctOfTime", null, Main.locale) + ".");
        // TODO: Verify where to output this value
	// TestResults.ndtVariables[NDTConstants.RWINTIME] * NDTConstants.PERCENTAGE;
        if (((2 * TestResults.ndtVariables[NDTConstants.RWIN]) / TestResults.ndtVariables[NDTConstants.RTTSEC]) < TestResults.ndt_test_results::mylink) {
          // multiplying by 2 to counter round-trip
          TestResults.appendResultDetails(
            " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                  "incrRxBuf", null, Main.locale)
            + " (" + (TestResults.ndtVariables[NDTConstants.MAXRWINRCVD] / NDTConstants.KBITS2BITS).toFixed(2)
            + " KB)" + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                       "willImprove",
                                                       null, Main.locale));
        }   
      }   
      // Is the connection sender limited ?
      if (TestResults.ndtVariables[NDTConstants.SENDTIME] > NDTConstants.SND_LIM_TIME_THRESHOLD) {
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "thisConnIs", null, Main.locale)
          + " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                  "limitTx", null, Main.locale)
          + " " + (TestResults.ndtVariables[NDTConstants.SENDTIME] * NDTConstants.PERCENTAGE).toFixed(2)
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                            "pctOfTime", null, Main.locale) + ".");

        if ((2 * (TestResults.ndtVariables[NDTConstants.SWIN] / TestResults.ndtVariables[NDTConstants.RTTSEC])) < TestResults.ndt_test_results::mylink) {
          // dividing by 2 to counter round-trip
          TestResults.appendResultDetails(
            " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                  "incrRxBuf", null, Main.locale)
            + " (" + (TestResults.ndtVariables[NDTConstants.SNDBUF] / (2 * NDTConstants.KBITS2BITS)).toFixed(2)
            + " KB)" + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                       "willImprove",
                                                       null, Main.locale));
        }   
      }   

      // Is the connection network limited ?
        // If the congestion windows is limited more than 0.5%
        // of the time, NDT claims that the connection is network
        // limited.
      if (TestResults.ndtVariables[NDTConstants.CWNDTIME] > 0.005) {
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "thisConnIs", null, Main.locale)
          + " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                  "limitNet", null, Main.locale)
          + " " + (TestResults.ndtVariables[NDTConstants.CWNDTIME] * NDTConstants.PERCENTAGE).toFixed(2)
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                            "pctOfTime", null, Main.locale));
      }
   }

   public static function appendTCPNegotiatedOptions():void {
     TestResults.appendResultDetails(
        "\n" + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                               "web100tcpOpts",
                                               null, Main.locale));
      TestResults.appendResultDetails( "RFC 2018 Selective Acknowledgement: ");
      if (TestResults.ndtVariables[NDTConstants.SACKENABLED] == 0)
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "off", null, Main.locale));
      else
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "on", null, Main.locale));

      TestResults.appendResultDetails( "RFC 896 Nagle Algorithm: ");
      if (TestResults.ndtVariables[NDTConstants.NAGLEENABLED] == 0)
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "off", null, Main.locale));
      else
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "on", null, Main.locale));

      TestResults.appendResultDetails( "RFC 3168 Excplicit Congestion Notification: ");
      if (TestResults.ndtVariables[NDTConstants.ECNENABLED] == 0)
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "off", null, Main.locale));
      else
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "on", null, Main.locale));

      TestResults.appendResultDetails( "RFC 1323 Time Stamping: ");
      if (TestResults.ndtVariables[NDTConstants.TIMESTAMPSENABLED] == NDTConstants.RFC_1323_DISABLED)
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "off", null, Main.locale));
      else
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "on", null, Main.locale));

      TestResults.appendResultDetails( "RFC 1323 Window Scaling: ");
      if (TestResults.ndtVariables[NDTConstants.MAXRWINRCVD] < NDTConstants.TCP_MAX_RECV_WIN_SIZE)
        TestResults.ndtVariables[NDTConstants.WINSCALERCVD] = 0; // Max rec window size lesser than TCP's max
                            // value, so no scaling requested

      // According to RFC1323, Section 2.3 the max valid value of iWinScaleRcvd is 14.
      // NDT uses 20 for this, leaving for now in case it is an error value. May need
      // to be inspected again.
      if ((TestResults.ndtVariables[NDTConstants.WINSCALERCVD] == 0) || (TestResults.ndtVariables[NDTConstants.WINSCALERCVD] > 20))
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "off", null, Main.locale));

      else
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "on", null, Main.locale)
          + "; " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                   "scalingFactors",
                                                   null, Main.locale)
          + " -  " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                    "server", null, Main.locale)
          + "=" + TestResults.ndtVariables[NDTConstants.WINSCALERCVD] + ", "
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                            "client", null, Main.locale)
          + "=" + TestResults.ndtVariables[NDTConstants.WINSCALESENT]);
   }

   public static function appendFurtherThroughputInfo():void {
      // Adding more details to the diagnostic text, related
      // to factors influencing throughput
      // Theoretical network limit
      TestResults.appendResultDetails(
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                        "theoreticalLimit", null, Main.locale)
        + " " + (TestResults.ndtVariables[NDTConstants.BW]).toFixed(2) + " " + "Mbps");
    // NDT server buffer imposed limit
      // divide by 2 to counter "round-trip" time
      TestResults.appendResultDetails(
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                        "ndtServerHas", null, Main.locale)
        + " " + (TestResults.ndtVariables[NDTConstants.SNDBUF] / (2 * NDTConstants.KBITS2BITS)).toFixed(2) + " "
        + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "kbyteBufferLimits", null, Main.locale)
        + " " + (TestResults.ndtVariables[NDTConstants.SWIN] / TestResults.ndtVariables[NDTConstants.RTTSEC]).toFixed(2) + " Mbps");
      // PC buffer imposed throughput limit
      TestResults.appendResultDetails(
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                        "yourPcHas", null, Main.locale)
        + " " + (TestResults.ndtVariables[NDTConstants.MAXRWINRCVD] / NDTConstants.KBITS2BITS).toFixed(2) + " "
        + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "kbyteBufferLimits", null, Main.locale)
        + " " + (TestResults.ndtVariables[NDTConstants.RWIN] / TestResults.ndtVariables[NDTConstants.RTTSEC]).toFixed(2) + " Mbps");
      // Network based flow control limit imposed throughput limit
      TestResults.appendResultDetails(
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                        "flowControlLimits", null, Main.locale)
        + " " + (TestResults.ndtVariables[NDTConstants.CWIN] / TestResults.ndtVariables[NDTConstants.RTTSEC]).toFixed(2) + " Mbps");

      // Client, Server data reports on link capacity
      if (TestResultsUtils.getDataRateString(TestResults.ndtVariables[NDTConstants.C2SDATA]) == null
         || TestResultsUtils.getDataRateString(TestResults.ndtVariables[NDTConstants.C2SACK]) == null
         || TestResultsUtils.getDataRateString(TestResults.ndtVariables[NDTConstants.S2CDATA]) == null
         || TestResultsUtils.getDataRateString(TestResults.ndtVariables[NDTConstants.S2CACK]) == null)
      {   
        TestResults.appendErrMsg("Error ! No matching data rate value found.");
      }   
      TestResults.appendResultDetails(
      "\n" + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                             "clientDataReports", null, Main.locale)
      + " '" + TestResultsUtils.getDataRateString(TestResults.ndtVariables[NDTConstants.C2SDATA]) + "', "
      + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                        "clientAcksReport", null, Main.locale)
      + " '" + TestResultsUtils.getDataRateString(TestResults.ndtVariables[NDTConstants.C2SACK]) + "'\n"
      + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                        "serverDataReports", null, Main.locale)
      + " '" + TestResultsUtils.getDataRateString(TestResults.ndtVariables[NDTConstants.S2CDATA]) + "', "
      + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                        "serverAcksReport", null, Main.locale)
      + " '" + TestResultsUtils.getDataRateString(TestResults.ndtVariables[NDTConstants.S2CACK]));
   }

   public static function appendOtherConnectionResults():void {
      TestResults.appendResultDetails(
        "\n" + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                               "web100rtt", null, Main.locale)
        + " = " + (TestResults.ndtVariables[NDTConstants.AVGRTT]).toFixed(2) + " ms; ");

      TestResults.appendResultDetails(
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                        "packetsize", null, Main.locale)
        + " = " + TestResults.ndtVariables[NDTConstants.CURMSS] + " "
        + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "bytes", null, Main.locale)
        + "; " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                 "and", null, Main.locale));
      // Is the loss excessive ?
      // If the link speed is less than a T3, and loss is greater than 1 percent,
      // loss is determined to be excessive.
      if ((TestResults.ndtVariables[NDTConstants.SPD] < 4) && (TestResults.ndtVariables[NDTConstants.LOSS] > 0.01))
        TestResults.appendResultDetails(
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                          "excLoss", null, Main.locale));
   }
 }
}

