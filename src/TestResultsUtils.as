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
  }
}

