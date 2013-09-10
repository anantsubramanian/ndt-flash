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
  import flash.globalization.LocaleID;
  import flash.system.Capabilities;
  import flash.system.Security;
  import flash.net.Socket;
  import flash.utils.ByteArray;
  import mx.resources.ResourceManager;
   */
  public class NDTUtils {    
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
     */
    public static function initializeFromHTML(paramObject:Object):void {
      if (NDTConstants.HTML_LOCALE in paramObject) {
        Main.locale = paramObject[NDTConstants.HTML_LOCALE];
      } else {
        initializeLocale();
      }
      if (NDTConstants.HTML_USERAGENT in paramObject) {
        TestResults.set_UserAgent(paramObject[NDTConstants.HTML_USERAGENT]);
      }
    }
    
    /**
     * Initializes the locale used by the tool to match the environment of the
     * SWF.
     */ 
    public static function initializeLocale():void {
      var localeId:LocaleID = new LocaleID(Capabilities.language);
      var lang:String = localeId.getLanguage();
      var region:String = localeId.getRegion();
      if (lang != null && region != null
          && (ResourceManager.getInstance().getResourceBundle(
                lang+"_"+region, NDTConstants.BUNDLE_NAME) != null)) {
        // Bundle for specified locale found, change value of locale
        Main.locale = new String(lang + "_" + region);
        trace("Using locale " + locale);
      } else {
        trace("Error: ResourceBundle for provided locale not found.");
        trace("Using default " + CONFIG::defaultLocale);
      }
    }
    
    /**
     * Function that adds the callbacks to allow data access from, and to allow
     * data to be sent to JavaScript.
     */
    public static function addJSCallbacks():void {
      // TODO: restrict domain to the M-Lab website / server
      Security.allowDomain("*");
      try {
        ExternalInterface.addCallback("getStandardOutput", 
                                      TestResults.getConsoleOutput);
        ExternalInterface.addCallback("getDebugOutput", 
                                      TestResults.getTraceOutput);
        ExternalInterface.addCallback("getDetails", 
                                      TestResults.getStatsText);
        ExternalInterface.addCallback("getAdvanced", 
                                      TestResults.getDiagnosisText);
        ExternalInterface.addCallback("getErrors", TestResults.getErrMsg);
        ExternalInterface.addCallback("getNDTvar", getNDTVariable);
      } catch (e:Error) {
        TestResults.appendErrMsg("Container doesn't support callbacks.\n");
      } catch (se:SecurityError) {
        TestResults.appendErrMsg("Security error " + se.toString());
      }
    }

      /**
       * Reads bytes from a socket into a ByteArray and returns the number of
       * successfully read bytes.
       * @param {Socket} socket Socket object to read from.
       * @param {ByteArray} bytes ByteArray where to store the read bytes.
       * @param {uint} offset Position of the ByteArray from where to start
                              storing the read values.
       * @param {uint} byteToRead Number of bytes to read.
       * @return {int} Number of successfully read bytes.
       */
      public static function readBytes(socket:Socket, bytes:ByteArray,
                                       offset:uint, bytesToRead:uint):int {
        var bytesRead:int = 0;
        while (socket.bytesAvailable && bytesRead < bytesToRead) {
          bytes[bytesRead + offset] = socket.readByte();
          bytesRead++;
        }
        return bytesRead;
      }
    }
  }
}

