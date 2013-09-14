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
  import flash.display.DisplayObject;
  import flash.display.LoaderInfo;
  import flash.external.ExternalInterface;
  import mx.resources.ResourceManager;
  /**
   * Class that defines utility methods used by NDT.
   */
  public class NDTUtils {    
    /**
     *  Utility method to print Text values for data speed related keys.
     *  @param {int} dataRateInt Parameter for which we find text value
     *  @return {String} Textual name for input parameter
     */
    public static function getDataRateString(dataRateInt:int):String {
      switch (dataRateInt) {
      case NDTConstants.DATA_RATE_SYSTEM_FAULT:
        return ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                               "systemFault", null, Main.locale);
      case NDTConstants.DATA_RATE_RTT:
        return ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                               "rtt", null, Main.locale);
      case NDTConstants.DATA_RATE_DIAL_UP:
        return ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                               "dialup2", null, Main.locale);
      case NDTConstants.DATA_RATE_T1:
        return ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                               "t1Str", null, Main.locale);
      case NDTConstants.DATA_RATE_ETHERNET:
        return ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                               "ethernetStr", null, Main.locale);
      case NDTConstants.DATA_RATE_T3:
        return ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                               "t3Str", null, Main.locale);
      case NDTConstants.DATA_RATE_FAST_ETHERNET:
        return ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                               "fastEthernet", null, Main.locale);
      case NDTConstants.DATA_RATE_OC_12:
        return ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                               "oc12Str", null, Main.locale);
      case NDTConstants.DATA_RATE_GIGABIT_ETHERNET:
        return ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                               "gigabitEthernetStr", 
                                               null, Main.locale); 
      case NDTConstants.DATA_RATE_OC_48:
        return ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                               "oc48Str", null, Main.locale);
      case NDTConstants.DATA_RATE_10G_ETHERNET:
        return ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                               "tengigabitEthernetStr", 
                                               null, Main.locale);
      } // end switch
      return null;
    }
    
    /**
     * Function that returns the current text that should be displayed as
     * Standard Output.
     * @return {String} The standard output text
     */
    public static function getStandardOut():String {
      return TestResults.getConsoleOutput();
    }
    
    /**
     * Function that returns the current text that should be displayed as
     * Debug Output.
     * @return {String} The debug output text
     */
    public static function getDebugOut():String {
      return TestResults.getTraceOutput();
    }
    
    /**
     * Function that return text that is an analysis of the test results.
     * @return {String} The analyzed text or 'Details'.
     */
    public static function getDetailedInfo():String {
      return TestResults.getStatsText();
    }
    
    /**
     * Function that returns the set of web100 variables or advanced information.
     * @return {String} 'Advanced' text to be displayed.
     */
    public static function getAdvancedInfo():String {
      return TestResults.getDiagnosisText();
    }
    
    /**
     * Function that returns any errors that may have occured during the program
     * run.
     * @return {String} Errors that may have occured, each one on a new line.
     */
    public static function getErrorInfo():String {
      return TestResults.getErrMsg();
    } 
    
    /**
     * Function that return a variable corresponding to the parameter passed to
     * it as a request.
     * @param {String} The parameter which the caller is seeking.
     * @return {String} The value of the desired parameter.
     */
    public static function getNDTvariables(varName:String):String {
      switch(varName) {
        case "TestList": 
          var testSuite:String = "";
          if(TestResults.get_testSuite() & NDTConstants.TEST_C2S)
            testSuite += "CLIENT_TO_SERVER_THROUGHPUT\n";
          if(TestResults.get_testSuite() & NDTConstants.TEST_S2C)
            testSuite += "SERVER_TO_CLIENT_THROUGHPUT\n";
          if(TestResults.get_testSuite() & NDTConstants.TEST_META)
            testSuite += "META_TEST\n";
          return testSuite;
        case "TestDuration":
          return (TestResults.get_EndTime() - TestResults.get_StartTime()).toString();
        case "ClientToServerSpeed":
          return TestResults.get_c2sspd();
        case "ServerToClientSpeed":
          return TestResults.get_s2cspd();
        case "PacketLoss":
          return TestResults.get_loss();
        case "MaxRTT":
          return TestResults.get_MaxRTT();
        case "AverageRTT":
          return TestResults.get_avgrtt();
        case "MinRTT":
          return TestResults.get_Ping();
        case "Jitter":
          return TestResults.get_jitter();
        case "OperatingSystem":
          return TestResults.get_osName();
        case "ClientVersion":
          return NDTConstants.VERSION;
        case "FlashVersion":
          return TestResults.get_flashVer();
        case "OsArch":
          return TestResults.get_osArch();
      }
      return null;
    }
    /**
     * Function that calls a JS function through the ExternalInterface class if it
     * exists by the name specified in the parameter.
     * @param {String} functionName The name of the JS function to call.
     * @param {...} args A variable length array that contains the parameters to
     *     pass to the JS function
     */
    public static function callExternalFunction(functionName:String, ... args):void {
      try {
        switch (args.length) {
          case 0: ExternalInterface.call(functionName);
                  break;
          case 1: ExternalInterface.call(functionName, args[0]);
                  break;
          case 2: ExternalInterface.call(functionName, args[0], args[1]);
                  break;
        }
      } catch (e:Error) {
        trace("No ExternalInterface detected.");
      }
    }
    /**
     * Function that reads the HTML parameter tags for the SWF file and
     * initializes the variables in the SWF accordingly.
     * @return {Boolean} Whether the locale was set or not.
     */
    public static function initializeTagsFromHTML(root:DisplayObject):Boolean {
      var paramObject:Object = LoaderInfo(root.loaderInfo).parameters;
      var localeSet:Boolean = false;
      var key:String;
      for (key in paramObject) {
        if (key == "Locale") {
          Main.locale = paramObject[key];
          localeSet = true;
        }
        else if (key == "UserAgentString")
          TestResults.set_UserAgent(paramObject[key]);
      }
      return localeSet;
    }
  }
}

