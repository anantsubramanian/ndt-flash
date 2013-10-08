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
          return TestResults.c2sSpeed.toString();
        case "ServerToClientSpeed":
          return TestResults.s2cSpeed.toString();
        case "Jitter":
          return TestResults.jitter.toString();
        case "OperatingSystem":
          return TestResults.osName;
        case "ClientVersion":
          return NDTConstants.CLIENT_VERSION;
        case "FlashVersion":
          return TestResults.flashVersion;
        case "OsArchitecture":
          return TestResults.osArchitecture;
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
      // Note: All comparisons henceforth of ((window size * 2/rttsec) < TestResults.mylink)
      // are along the same logic.
      // TODO: Clean up.
      if (((2 * TestResults.ndtVariables[NDTConstants.RWIN]) /
          TestResults.ndtVariables[NDTConstants.RTTSEC]) < TestResults.mylink) {
        // Multiplied by 2 to counter round-trip
        // Link speed is in Mbps. Convert it back to kbps (*1000) and bytes (/8)
        var j:Number = Number(((TestResults.mylink *
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
      if (TestResults.sc2sSpeed <
          (TestResults.c2sSpeed * (1.0 - NDTConstants.SPD_DIFF)))
        TestResults.appendResultDetails(
            ResourceManager.getInstance().getString(
                NDTConstants.BUNDLE_NAME, "c2sPacketQueuingDetected", null,
                Main.locale));
    }

    public static function appendS2CPacketQueueingResult():void {
       if (TestResults.s2cSpeed <
           (TestResults.ss2cSpeed * (1.0 - NDTConstants.SPD_DIFF)))
         TestResults.appendResultDetails(
             ResourceManager.getInstance().getString(
                 NDTConstants.BUNDLE_NAME, "s2cPacketQueuingDetected", null,
                 Main.locale));
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
              + " " + TestResults.client + " "
              + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                "connectedTo", null, Main.locale));

            if (TestResults.ndtVariables[NDTConstants.C2SDATA] == NDTConstants.DATA_RATE_DIAL_UP) {
              TestResults.appendResultDetails(
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                "dialup", null, Main.locale));
              TestResults.mylink = 0.064;  // 64 kbps speed
              TestResults.accessTech = "Dial-up Modem";
            }
            else {
              TestResults.appendResultDetails(
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                "cabledsl", null, Main.locale));
              TestResults.mylink = 3;
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
          TestResults.mylink = 10;
          TestResults.accessTech = "10 Mbps Ethernet";
          break;
        case NDTConstants.DATA_RATE_T3 :
          TestResults.appendResultDetails(
              ResourceManager.getInstance().getString(
                  NDTConstants.BUNDLE_NAME, "45mbps", null, Main.locale));
          TestResults.mylink = 45;
          TestResults.accessTech = "45 Mbps T3/DS3 subnet";
          break;
        case NDTConstants.DATA_RATE_FAST_ETHERNET :
          TestResults.appendResultDetails("100 Mbps ");
          TestResults.mylink = 100;
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
           TestResults.mylink = 622;
           TestResults.accessTech = "622 Mbps OC-12";
           break;
         case NDTConstants.DATA_RATE_GIGABIT_ETHERNET:
           TestResults.appendResultDetails(
               ResourceManager.getInstance().getString(
                   NDTConstants.BUNDLE_NAME, "1gbps", null, Main.locale));
           TestResults.mylink = 1000;
           TestResults.accessTech = "1.0 Gbps Gigabit Ethernet";
           break;
         case NDTConstants.DATA_RATE_OC_48:
           TestResults.appendResultDetails(
               ResourceManager.getInstance().getString(
                   NDTConstants.BUNDLE_NAME, "2.4gbps", null, Main.locale));
           TestResults.mylink = 2400;
           TestResults.accessTech = "2.4 Gbps OC-48";
           break;
         case NDTConstants.DATA_RATE_10G_ETHERNET:
           TestResults.appendResultDetails(
               ResourceManager.getInstance().getString(
                   NDTConstants.BUNDLE_NAME, "10gbps", null, Main.locale));
           TestResults.mylink = 10000;
           TestResults.accessTech = "10 Gigabit Ethernet/OC-192";
           break;
         default:
           TestResults.appendResultDetails("Undefined");
           TestResults.appendErrMsg("Non valid calue for NDTConstants.C2SDATA");
      }
    }
  }
}

