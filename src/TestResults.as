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
  import flash.text.TextField;
  import flash.system.Capabilities;
  import flash.utils.getTimer;
  import mx.resources.ResourceManager;
  
  /**
   * Class that interprets the results of the tests. These results are stored in
   * variables that can be accessed through JavaScript.
   */
  public class TestResults {
    // variables declaration section
    private static var _yTests:int;  // Requested test-suite
    
    // Section : "pub_xxx" variables. Declared
    // as private but they have getter/setter methods.
    private static var pub_status:String = null;
    private static var pub_flashVer:String = null;
    private static var pub_host:String = null;
    private static var pub_osName:String = null;
    private static var pub_osArch:String = null;
    private static var pub_AccessTech:String = null;
    private static var pub_clientIP:String = null;
    private static var pub_natBox:String = null;
    private static var pub_SACKsRcvd:int = 0;
    private static var pub_MaxRwinRcvd:int = 0;
    private static var pub_CurRTO:int = 0;
    private static var pub_MaxRTO:int = 0;
    private static var pub_MinRTO:int = 0;
    private static var pub_MinRTT:int = 0;
    private static var pub_MaxRTT:int = 0;
    private static var pub_CurRwinRcvd:int = 0;
    private static var pub_Timeouts:int = 0;
    private static var pub_mismatch:int = 0;
    private static var pub_congestion:int = 0;
    private static var pub_Bad_cable:int = 0;
    private static var pub_DupAcksOut:int = 0;
    private static var pub_loss:Number = 0.0;
    private static var pub_avgrtt:Number = 0.0;
    private static var pub_cwndtime:Number = 0.0;
    private static var pub_c2sspd:Number = 0.0;
    private static var pub_s2cspd:Number = 0.0;
    private static var pub_pctRcvrLimited:Number = 0.0;
    private static var pub_time:Number = 0.0;
    private static var pub_bytes:Number = 0.0;
    
    private static var pub_TimeStamp:Date = null;
    
    // Section : web100 integer variables
    private static var MSSSent:int = 0;
    private static var MSSRcvd:int = 0;
    private static var _iECNEnabled:int = 0;
    private static var _iNagleEnabled:int = 0;
    private static var _iSACKEnabled:int = 0;
    private static var _iTimestampsEnabled:int = 0;
    private static var _iWinScaleRcvd:int = 0;
    private static var _iWinScaleSent:int = 0;
    private static var _iSumRTT:int = 0;
    private static var _iCountRTT:int = 0;
    private static var _iCurrentMSS:int = 0;
    private static var _iTimeouts:int = 0;
    private static var _iPktsRetrans:int = 0;
    private static var _iSACKsRcvd:int = 0;
    private static var _iMaxRwinRcvd:int = 0;
    private static var _iDupAcksIn:int = 0;
    private static var _iMaxRwinSent:int = 0;
    private static var _iSndbuf:int = 0;
    private static var _iRcvbuf:int = 0;
    private static var _iDataPktsOut:int = 0;
    private static var _iFastRetran:int = 0;
    private static var _iAckPktsOut:int = 0;
    private static var _iSmoothedRTT:int = 0;
    private static var _iCurrentCwnd:int = 0;
    private static var _iMaxCwnd:int = 0;
    private static var _iSndLimTimeRwin:int = 0;
    private static var _iSndLimTimeCwnd:int = 0;
    private static var _iSndLimTimeSender:int = 0;
    private static var _iDataBytesOut:int = 0;
    private static var _iAckPktsIn:int = 0;
    private static var _iSndLimTransRwin:int = 0;
    private static var _iSndLimTransCwnd:int = 0;
    private static var _iSndLimTransSender:int = 0;
    private static var _iMaxSsthresh:int = 0;
    private static var _iCurrentRTO:int = 0;
    private static var _iC2sData:int = 0;
    private static var _iC2sAck:int = 0;
    private static var _iS2cData:int = 0;
    private static var _iS2cAck:int = 0;
    private static var _iPktsOut:int = 0;
    private static var mismatch:int = 0;
    private static var congestion:int = 0;
    private static var bad_cable:int = 0;
    private static var half_duplex:int = 0;
    private static var _iCongestionSignals:int = 0;
    private static var _iRcvWinScale:int = 0;
    
    // Section : web100 double variables
    private static var _dEstimate:Number = 0.0;
    private static var _dLoss:Number = 0.0;
    private static var _dAvgrtt:Number = 0.0;
    private static var _dWaitsec:Number = 0.0;
    private static var _dTimesec:Number = 0.0;
    private static var _dOrder:Number = 0.0;
    private static var _dRwintime:Number = 0.0;
    private static var _dSendtime:Number = 0.0;
    private static var _dCwndtime:Number = 0.0;
    private static var _dRttsec:Number = 0.0;
    private static var _dRwin:Number = 0.0;
    private static var _dSwin:Number = 0.0;
    private static var _dCwin:Number = 0.0;
    private static var _dSpd:Number = 0.0;
    private static var _dAspd:Number = 0.0;
    private static var mylink:Number = 0.0;
    private static var _dSc2sspd:Number = 0.0;
    private static var _dSs2cspd:Number = 0.0;
    private static var _dS2cspd:Number = 0.0;
    private static var _dC2sspd:Number = 0.0;
    
    // Section : Misc variables
    private static var _sUserAgent:String = null;            
    
    // Output containing strings
    private static var consoleOutput:String = "";
    private static var errMsg:String = "";
    private static var statsText:String = "";
    private static var traceOutput:String = "";
    private static var diagnosisText:String = "";
    private static var emailText:String = "";
    
    private static var _bFailed:Boolean = false;
    // end variables declaration
    
    // Accessor methods for "pub_xxx" variables
    public static function get_c2sspd():String {
      return pub_c2sspd.toString();
    }    
    public static function get_s2cspd():String {
      return pub_s2cspd.toString();
    }    
    public static function get_loss():String {
      return pub_loss.toString();
    }    
    public static function get_avgrtt():String {
      return pub_avgrtt.toString();
    }    
    public static function get_flashVer():String {
      return pub_flashVer;
    }    
    public static function get_host():String {
      return pub_host;
    }    
    public static function get_osName():String {
      return pub_osName;
    }    
    public static function get_osArch():String {
      return pub_osArch;
    }    
    public static function get_SACKsRcvd():String {
      return pub_SACKsRcvd.toString();
    }    
    public static function get_MaxRwinRcvd():String {
      return pub_MaxRwinRcvd.toString();
    }    
    public static function get_CurRTO():String {
      return pub_CurRTO.toString();
    }    
    public static function get_MaxRTO():String {
      return pub_MaxRTO.toString();
    }    
    public static function get_MinRTO():String {
      return pub_MinRTO.toString();
    }    
    public static function get_Ping():String {
      return pub_MinRTT.toString();
    }    
    public static function get_MaxRTT():String {
      return pub_MaxRTT.toString();
    }    
    public static function get_CurRwinRcvd():String {
      return pub_CurRwinRcvd.toString();
    }    
    public static function get_WaitSec():String {
      return ((pub_CurRTO * pub_Timeouts) / 1000).toString();
    }    
    public static function get_mismatch():String {
      if (pub_mismatch == 0)
        return "no";
      else
        return "yes";
    }    
    public static function get_congestion():String {
      if (pub_congestion == 1)
        return "yes";
      else
        return "no";
    }    
    public static function get_Bad_cable():String {
      if (pub_Bad_cable == 1)
        return "yes";
      else
        return "no";
    }    
    public static function get_cwndtime():String {
      return pub_cwndtime.toString();
    }    
    public static function getAccessTech():String {
      return pub_AccessTech;
    }    
    public static function get_rcvrLimiting():String {
      return pub_pctRcvrLimited.toString();
    }    
    public static function get_optimalRcvrBuffer():String {
      return (pub_MaxRwinRcvd * NDTConstants.KILO).toString();
    }    
    public static function get_clientIP():String {
      return pub_clientIP;
    }    
    public static function get_natStatus():String {
      return pub_natBox;
    }    
    public static function get_DupAcksOut():String {
      return pub_DupAcksOut.toString();
    }    
    public static function get_TimeStamp():String {
      if (pub_TimeStamp != null)
        return pub_TimeStamp.toString();
      else
        return "unknown";
    }    
    public static function get_jitter():String {
      return (pub_MaxRTT - pub_MinRTT).toString();
    }    
    public static function get_status():String {
      return pub_status;
    }    
    public static function get_instSpeed():String {
      // get speed in bits, hence multiply by 8
      // for bit->byte conversion
      return ((pub_bytes * NDTConstants.EIGHT) / (getTimer() - pub_time)).toString();      
    }    
    public static function get_UserAgent():String {
      return _sUserAgent;
    }    
    public static function get_bFailed():Boolean {
      return _bFailed;
    }
    
    // Setter methods
    public static function set_bFailed(b:Boolean):void {
      _bFailed = b;
    }
    public static function set_pub_status(sParam:String):void {
      pub_status = sParam;
    }    
    public static function set_pub_time(dParam:Number):void {
      pub_time = dParam;
    }    
    public static function set_pub_bytes(dParam:Number):void {
      pub_bytes = dParam;
    }    
    public static function set_Ss2cspd(dParam:Number):void {
      _dSs2cspd = dParam;
    }    
    public static function set_S2cspd(dParam:Number):void {
      _dS2cspd = dParam;
    }    
    public static function set_Sc2sspd(dParam:Number):void {
      _dSc2sspd = dParam;
    }    
    public static function set_C2sspd(dParam:Number):void {
      _dC2sspd = dParam;
    }    
    public static function set_UserAgent(sParam:String):void {
      _sUserAgent = sParam;
    }
    
    // Output handler functions
    public static function appendConsoleOutput(sParam:String):void {
      consoleOutput += sParam;
      if (Main.guiEnabled)
        GUI.addConsoleOutput(sParam);
    }    
    public static function appendStatsText(sParam:String):void {
      statsText += sParam;
    }    
    public static function appendTraceOutput(sParam:String):void {
      traceOutput += sParam;
      if (Main.guiEnabled)
        GUI.addConsoleOutput(sParam);
    }    
    public static function appendDiagnosisText(sParam:String):void {
      diagnosisText += sParam;
    }    
    public static function appendEmailText(sParam:String):void {
      emailText += sParam;
    }    
    public static function appendErrMsg(sParam:String):void {
      errMsg += sParam;
    }    
    public static function getConsoleOutput():String {
      return consoleOutput;
    }    
    public static function getStatsText():String {
      return statsText;
    }    
    public static function getTraceOutput():String {
      return traceOutput;
    }    
    public static function getDiagnosisText():String {
      return diagnosisText;
    }    
    public static function getEmailText():String {
      return emailText;
    }
    public static function getErrMsg():String {
      return errMsg;
    }
    
    /**
     * Function that takes a Human readable string containing the results and
     * assigns the key-value pairs to the correct variables.
     * These values are then interpreted to make decisions about various 
     * measurement items.
     * @param sTestResParam String containing the results as key-value pairs
     */
    public function interpretResults(sTestResParam:String):void {
      var tokens:Array;
      var i:int = 0;
      var sSysvar:String, sStrval:String;
      var iSysval:int;
      var dSysval2:Number, j:Number;
      var sOsName:String, sOsArch:String, sFlashVer:String, sClient:String;
      
      // extract the key-value pairs
      tokens = sTestResParam.split(/\s/);
      sSysvar = null;
      sStrval = null;
      for each(var token:String in tokens) {
        if (!(i & 1)) {
          sSysvar = tokens[i];
        }
        else {
          sStrval = tokens[i];
          diagnosisText += sSysvar + " " + sStrval + "\n";
          emailText += sSysvar + " " + sStrval + "\n%0A";
          if (sStrval.indexOf(".") == -1) {
            // no decimal point hence an integer
            iSysval = parseInt(sStrval);
            if (isNaN(iSysval)) {
              // The value was probably too big for int
              // it may have been unsigned
              trace("Error reading web100 var.");
              iSysval = -1;
            }
            // save value into a key value expected by us
            saveIntValues(sSysvar, iSysval);
          } else {
            // if not aninteger, save as a double
            dSysval2 = parseFloat(sStrval);
            saveDblValues(sSysvar, dSysval2);
          }
        }
        i++;
      }
      // Read client details from the SWF environment
      sOsName = Capabilities.os;
      pub_osName = sOsName;      
      sOsArch = Capabilities.cpuArchitecture;
      pub_osArch = sOsArch;      
      sFlashVer = Capabilities.version;
      pub_flashVer = sFlashVer;
      if (sOsArch.indexOf("x86") == 0)
        sClient = ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                  "pc", null, Main.locale);
      else
        sClient = ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                  "workstation",
                                                  null, Main.locale);
        
      // Calculate some variables and determine patch conditions
      // Note : Calculations now done by server and the results are
      // sent to the client for printing.
      if (_iCountRTT > 0) {
        // Now write some messages to the screen
        // Access speed / technology details added to consoleOutput
        // and mailing text. Link speed is also assigned.
        if (_iC2sData < NDTConstants.DATA_RATE_ETHERNET) {
          if (_iC2sData < NDTConstants.DATA_RATE_RTT) {
            // data was not sufficient to determine bottleneck type
            consoleOutput += 
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                              "unableToDetectBottleneck",
                                               null, Main.locale) + "\n";
            emailText += "Server unable to determine bottleneck link type.\n%0A";
            pub_AccessTech = "Connection type unknown";
          }
          else {
            // get link speed
            consoleOutput += 
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                              "your", null, Main.locale)
              + " " + sClient + " "
              + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                "connectedTo", null, Main.locale)
              + " ";
            emailText +=  
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                              "your", null, Main.locale)
              + " " + sClient + " "
              + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                "connectedTo", null, Main.locale)
              + " ";
                   
            if (_iC2sData == NDTConstants.DATA_RATE_DIAL_UP) {
              consoleOutput += 
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                "dialup", null, Main.locale) + "\n";
              emailText += 
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                "dialup", null, Main.locale) + "\n%0A";
              mylink = 0.064;  // 64 kbps speed
              pub_AccessTech = "Dial-up Modem";
            }
            else {
              consoleOutput += 
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                "cabledsl", null, Main.locale) + "\n";
              emailText += 
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                "cabledsl", null, Main.locale) + "\n%0A";
              mylink = 3;
              pub_AccessTech = "Cable/DSL modem";
            }
          }
        }
        else {
          consoleOutput += 
            ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                            "theSlowestLink",
                                             null, Main.locale) + " ";
          emailText += 
            ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                            "theSlowestLink",
                                            null, Main.locale)  + " ";
          switch(_iC2sData) {
            case NDTConstants.DATA_RATE_ETHERNET : 
                consoleOutput += 
                  ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                  "10mbps", null, Main.locale) + "\n";
                emailText += 
                  ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                  "10mbps", null, Main.locale) + "\n%0A";
                mylink = 10;
                pub_AccessTech = "10 Mbps Ethernet";
                break;                
            case NDTConstants.DATA_RATE_T3 :
                consoleOutput += 
                  ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                  "45mbps", null, Main.locale) + "\n";
                emailText += 
                  ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                  "45mbps", null, Main.locale) + "\n%0A";
                mylink = 45;
                pub_AccessTech = "45 Mbps T3/DS3 subnet";
                break;                
            case NDTConstants.DATA_RATE_FAST_ETHERNET :
                consoleOutput += "100 Mbps ";
                emailText += "100 Mbps";
                mylink = 100;
                pub_AccessTech = "100 Mbps Ethernet";
                // Fast ethernet. Determine if half/full duplex link was found
                if (half_duplex == 0) {
                  consoleOutput += 
                    ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                    "fullDuplex",
                                                    null, Main.locale) + "\n";
                  emailText += 
                    ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                    "fullDuplex",
                                                    null, Main.locale) + "\n%0A";
                }
                else {
                  consoleOutput += 
                    ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                    "halfDuplex",
                                                    null, Main.locale) + "\n";
                  emailText += 
                    ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                    "halfDuplex",
                                                    null, Main.locale) + "\n%0A";
                }
                break;            
            case NDTConstants.DATA_RATE_OC_12 :
                consoleOutput += 
                  ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                  "622mbps", null, Main.locale) + "\n";
                emailText += 
                  ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                  "622mbps", null, Main.locale) + "\n%0A";
                mylink = 622;
                pub_AccessTech = "622 Mbps OC-12";
                break;                
            case NDTConstants.DATA_RATE_GIGABIT_ETHERNET :
                consoleOutput += 
                  ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                  "1gbps", null, Main.locale) + "\n";
                emailText += 
                  ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                  "1gbps", null, Main.locale) + "\n%0A";
                mylink = 1000;
                pub_AccessTech = "1.0 Gbps Gigabit Ethernet";
                break;                
            case NDTConstants.DATA_RATE_OC_48 :
                consoleOutput += 
                  ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                  "2.4gbps", null, Main.locale) + "\n";
                emailText += 
                  ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                  "2.4gbps", null, Main.locale) + "\n%0A";
                mylink = 2400;
                pub_AccessTech = "2.4 Gbps OC-48";
                break;                
            case NDTConstants.DATA_RATE_10G_ETHERNET :
                consoleOutput += 
                  ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                  "10gbps", null, Main.locale) + "\n";
                emailText += 
                  ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                  "10gbps", null, Main.locale) + "\n%0A";
                mylink = 10000;
                pub_AccessTech = "10 Gigabit Ethernet/OC-192";
                break;            
            default:
                consoleOutput += "Undefined\n";
                errMsg += "No _iC2sData option match";
                break;
          } // end switch-case
        } // end inner else
        // duplex mismatch
        switch(mismatch) {
          case NDTConstants.DUPLEX_NOK_INDICATOR: //1
              consoleOutput += 
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                "oldDuplexMismatch",
                                                null, Main.locale) + "\n";
              emailText += 
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                "oldDuplexMismatch",
                                                null, Main.locale) + "\n%0A";
              break;            
          case NDTConstants.DUPLEX_SWITCH_FULL_HOST_HALF:
              consoleOutput += 
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                "duplexFullHalf",
                                                null, Main.locale) + "\n";
              emailText += 
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                "duplexFullHalf",
                                                null, Main.locale) + "\n%0A";
              break;            
          case NDTConstants.DUPLEX_SWITCH_HALF_HOST_FULL:
              consoleOutput += 
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                "duplexHalfFull",
                                                null, Main.locale) + "\n";
              emailText += 
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                "duplexHalfFull",
                                                null, Main.locale) + "\n%0A";
              break;            
          case NDTConstants.DUPLEX_SWITCH_FULL_HOST_HALF_POSS:
              consoleOutput += 
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                "possibleDuplexFullHalf",
                                                null, Main.locale) + "\n";
              emailText += 
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                "possibleDuplexFullHalf",
                                                null, Main.locale) + "\n%0A";
              break;            
          case NDTConstants.DUPLEX_SWITCH_HALF_HOST_FULL_POSS:
              consoleOutput += 
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                "possibleDuplexHalfFull",
                                                null, Main.locale) + "\n";
              emailText += 
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                "possibleDuplexHalfFull",
                                                null, Main.locale) + "\n%0A";
              break;            
          case NDTConstants.DUPLEX_SWITCH_HALF_HOST_FULL_WARN:
              consoleOutput += 
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                "possibleDuplexHalfFullWarning",
                                                null, Main.locale) + "\n";
              emailText += 
                ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                "possibleDuplexHalfFullWarning",
                                                null, Main.locale) + "\n%0A";
              break;            
          case NDTConstants.DUPLEX_OK_INDICATOR:
              if (bad_cable == 1) {
                consoleOutput += 
                  ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                  "excessiveErrors",
                                                  null, Main.locale) + "\n";
                emailText += 
                  ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                  "excessiveErrors",
                                                  null, Main.locale) + "\n%0A";
              }
              if (congestion == 1) {
                consoleOutput += 
                  ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                  "otherTraffic",
                                                  null, Main.locale) + "\n";
                emailText += 
                  ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                  "otherTraffic",
                                                  null, Main.locale) + "\n%0A";
              }
              // We seem to be transmitting less than link speed possibly due to
              // a receiver window setting (i.e calculated bandwidth is greater
              // than measured throughput). Advise appropriate size
              
              // Note: All comparisons henceforth of ((window size * 2/rttsec) < mylink)
              // are along the same logic
              if (((2 * _dRwin) / _dRttsec) < mylink) {  
                // multiplied by 2 to counter round-trip
                // Link speed is in Mbps. Convert it back to kbps (*1000),
                // and bytes (/8)
                j = Number(((mylink * _dAvgrtt) * NDTConstants.KILO)) / 
                           NDTConstants.EIGHT / NDTConstants.KILO_BITS;
                if (j > Number(_iMaxRwinRcvd)) {
                  consoleOutput += 
                    ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                    "receiveBufferShouldBe",
                                                    null, Main.locale)
                    + " " + j.toFixed(2)
                    + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                      "toMaximizeThroughput",
                                                      null, Main.locale) + "\n";
                  emailText += 
                    ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                    "receiveBufferShouldBe",
                                                    null, Main.locale)
                    + " " + j.toFixed(2)
                    + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                      "toMaximizeThroughput",
                                                      null, Main.locale) + "\n%0A";
                }
              }
              break;
            
          default: // default for indication of no match for mismatch variable
              break;
        }
        // C2S throughput test: Packet queueing
        if ((_yTests & NDTConstants.TEST_C2S) == NDTConstants.TEST_C2S) {
          if (_dSc2sspd < (_dC2sspd * (1.0 - NDTConstants.VIEW_DIFF))) {
            consoleOutput += 
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                              "c2sPacketQueuingDetected",
                                              null, Main.locale) + "\n";
          }
        }
        // S2C throughput test: Packet queueing
        if ((_yTests & NDTConstants.TEST_S2C) == NDTConstants.TEST_S2C) {
          if (_dS2cspd < (_dSs2cspd * (1.0 - NDTConstants.VIEW_DIFF))) {
            consoleOutput += 
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
      var iZero:int = 0;
      // Add client information
      statsText += 
        "\n\t-----  " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                        "clientInfo",
                                                        null, Main.locale) + "------\n";
      statsText += 
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                        "osData", null, Main.locale)
        + " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                "name", null, Main.locale)
        + " & " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                  "version", null, Main.locale)
        + " = " + pub_osName + ", " 
        + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "architecture", null, Main.locale)
        + " = " + pub_osArch + "\n";
      statsText += 
        "Flash Info: " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                 "version", null, Main.locale)
        + " = " + pub_flashVer + "\n";
        statsText += 
          "\n\t------ " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                          "web100Details",
                                                          null, Main.locale)
          + " ------\n";
      
      // Now add data about access speeds / technology
      // Slightly different from the earlier switch 
      // (that added data to the results pane) in that
      // negative values are checked for too.
      switch(_iC2sData) {
        case NDTConstants.DATA_RATE_INSUFFICIENT_DATA :
            statsText += 
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                              "insufficient", 
                                              null, Main.locale) + "\n";
            break;            
        case NDTConstants.DATA_RATE_SYSTEM_FAULT :
            statsText += 
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                              "ipcFail", null, Main.locale) + "\n";
            break;          
        case NDTConstants.DATA_RATE_RTT :
            statsText += 
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                              "rttFail", null, Main.locale) + "\n";
            break;            
        case NDTConstants.DATA_RATE_DIAL_UP :
            statsText += 
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                              "foundDialup",
                                              null, Main.locale) + "\n";
            break;            
        case NDTConstants.DATA_RATE_T1 :
            statsText += 
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                              "foundDsl",
                                              null, Main.locale) + "\n";
            break;            
        case NDTConstants.DATA_RATE_ETHERNET :
            statsText += 
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                              "found10mbps",
                                              null, Main.locale) + "\n";
            break;            
        case NDTConstants.DATA_RATE_T3 :
            statsText += 
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                              "found45mbps",
                                              null, Main.locale) + "\n";
            break;        
        case NDTConstants.DATA_RATE_FAST_ETHERNET :
            statsText += 
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                              "found100mbps",
                                              null, Main.locale) + "\n";
            break;            
        case NDTConstants.DATA_RATE_OC_12 :
            statsText += 
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                              "found622mbps",
                                              null, Main.locale) + "\n";
            break;            
        case NDTConstants.DATA_RATE_GIGABIT_ETHERNET :
            statsText += 
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                              "found1gbps",
                                              null, Main.locale) + "\n";
            break;            
        case NDTConstants.DATA_RATE_OC_48 :
            statsText += 
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                              "found2.4gbps",
                                              null, Main.locale) + "\n";
            break;        
        case NDTConstants.DATA_RATE_10G_ETHERNET :
            statsText += 
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                              "found10gbps",
                                              null, Main.locale) + "\n";
            break;
      }
      // Add decisions about duplex mode, congestion & duplex mismatch
      if (half_duplex == NDTConstants.DUPLEX_OK_INDICATOR)
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "linkFullDpx",
                                          null, Main.locale) + "\n";
      else
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "linkHalfDpx",
                                          null, Main.locale) + "\n";
        
      if (congestion == NDTConstants.CONGESTION_NONE)
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "congestNo",
                                          null, Main.locale) + "\n";
      else
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "congestYes",
                                          null, Main.locale) + "\n";
        
      if (bad_cable == NDTConstants.CABLE_STATUS_OK)
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "cablesOk", null, Main.locale) + "\n";
      else
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "cablesNok", null, Main.locale) + "\n";
        
      if (mismatch == NDTConstants.DUPLEX_OK_INDICATOR)
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "duplexOk",
                                          null, Main.locale) + "\n";
      else if (mismatch == NDTConstants.DUPLEX_NOK_INDICATOR) {
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "duplexNok",
                                          null, Main.locale) + " ";
        emailText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "duplexNok",
                                          null, Main.locale) + " ";
      }
      else if (mismatch == NDTConstants.DUPLEX_SWITCH_FULL_HOST_HALF) {
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "duplexFullHalf",
                                          null, Main.locale) + "\n";
        emailText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "duplexFullHalf",
                                          null, Main.locale) + "\n%0A";
      }
      else if (mismatch == NDTConstants.DUPLEX_SWITCH_HALF_HOST_FULL) {
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "duplexHalfFull",
                                          null, Main.locale) + "\n";
        emailText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "duplexHalfFull",
                                          null, Main.locale) + "\n%0A";
      }
          
      statsText += 
        "\n" + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                               "web100rtt", null, Main.locale)
        + " = " + (_dAvgrtt).toFixed(2) + " ms; ";
      emailText += 
        "\n%0A" + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                               "web100rtt", null, Main.locale)
        + " = " + (_dAvgrtt).toFixed(2) + " ms; ";
             
      statsText += 
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                        "packetsize", null, Main.locale)
        + " = " + _iCurrentMSS + " "
        + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "bytes", null, Main.locale)
        + "; " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                 "and", null, Main.locale) + " \n";
      emailText += 
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                        "packetsize", null, Main.locale)
        + " = " + _iCurrentMSS + " "
        + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "bytes", null, Main.locale)
        + "; " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                 "and", null, Main.locale) + " \n%0A";
             
      // check packet retransmissions count and update stats panel
      if (_iPktsRetrans > 0) {
        // packet retransmissions found
        statsText += 
          _iPktsRetrans + " "
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                            "pktsRetrans", null, Main.locale);
        statsText += 
          ", " + _iDupAcksIn + " " 
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                            "dupAcksIn", null, Main.locale);
        statsText += 
          ", " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                 "and", null, Main.locale) 
          + " " + _iSACKsRcvd + " " 
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                            "sackReceived", null, Main.locale) + "\n";
        emailText += 
          _iPktsRetrans + " "
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                            "pktsRetrans", null, Main.locale);
        emailText += 
          ", " + _iDupAcksIn + " " 
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                            "dupAcksIn", null, Main.locale);
        emailText += 
          ", " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                 "and", null, Main.locale) 
          + " " + _iSACKsRcvd + " " 
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                            "sackReceived", null, Main.locale) + "\n%0A";
      if (_iTimeouts > 0) {
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "connStalled", null, Main.locale) 
          + " " + _iTimeouts + " " 
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                            "timesPktLoss", null, Main.locale) + "\n";
        emailText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "connStalled", null, Main.locale) 
          + " " + _iTimeouts + " " 
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                            "timesPktLoss", null, Main.locale) + "\n%0A";
      }
      
      statsText += 
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                        "connIdle", null, Main.locale) 
        + " " + (_dWaitsec).toFixed(2) + " " 
        + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "seconds", null, Main.locale) 
        + " (" + ((_dWaitsec / _dTimesec) * NDTConstants.PERCENTAGE).toFixed(2)
        + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "pctOfTime", null, Main.locale) + ") \n";
      emailText += 
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                        "connIdle", null, Main.locale) 
        + " " + (_dWaitsec).toFixed(2) + " " 
        + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "seconds", null, Main.locale) 
        + " (" + ((_dWaitsec / _dTimesec) * NDTConstants.PERCENTAGE).toFixed(2)
        + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "pctOfTime", null, Main.locale) + ") \n%0A";
      }
      else if (_iDupAcksIn > 0) {
        // No packet loss, but packets arrived out-of-order
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "noPktLoss1", null, Main.locale) + " - ";
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "ooOrder", null, Main.locale)  
          + " " + (_dOrder * NDTConstants.PERCENTAGE).toFixed(2)
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                            "pctOfTime", null, Main.locale) + "\n";
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "noPktLoss1", null, Main.locale) + " - ";
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "ooOrder", null, Main.locale)  
          + " " + (_dOrder * NDTConstants.PERCENTAGE).toFixed(2)
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                            "pctOfTime", null, Main.locale) + "\n%0A";
      }
      else {
        // No packet retransmissions found
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "noPktLoss2", null, Main.locale) + ".\n";
        emailText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "noPktLoss2", null, Main.locale) + ".\n%0A";
      }
      
      // Add Packet queueing details found during C2S throughput test to the
      // stats pane. Data is displayed as percentage
      if ((_yTests & NDTConstants.TEST_C2S) == NDTConstants.TEST_C2S) {
        if (_dC2sspd > _dSc2sspd) {
          if (_dSc2sspd < (_dC2sspd * (1.0 - NDTConstants.VIEW_DIFF))) {
            statsText += 
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                              "c2s", null, Main.locale) 
              + " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME,
                                                      "qSeen", null, Main.locale) 
              + ": " + (NDTConstants.PERCENTAGE * 
                         (_dC2sspd - _dSc2sspd) / _dC2sspd).toFixed(2) + "%\n";
          }
          else {
            statsText += 
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                              "c2s", null, Main.locale) 
              + " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                      "qSeen", null, Main.locale) 
              + ": " + (NDTConstants.PERCENTAGE * 
                         (_dC2sspd - _dSc2sspd) / _dC2sspd).toFixed(2) + "%\n";
          }
        }
      }
      
      // Add packet queueing details found during S2C throughput test to
      // the statistics pane. Data is displayed as a percentage.
      if ((_yTests & NDTConstants.TEST_S2C) == NDTConstants.TEST_S2C) {
        if (_dSs2cspd > _dS2cspd) {
          if (_dSs2cspd < (_dSs2cspd * (1.0 - NDTConstants.VIEW_DIFF))) {
            statsText += 
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                              "s2c", null, Main.locale)  
              + " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                      "qSeen", null, Main.locale) 
              + ": " + (NDTConstants.PERCENTAGE * 
                         (_dSs2cspd - _dS2cspd) / _dSs2cspd).toFixed(2) + "%\n";
          } 
          else {
            statsText += 
              ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                              "s2c", null, Main.locale) 
              + " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                      "qSeen", null, Main.locale) 
              + ": " + (NDTConstants.PERCENTAGE * 
                         (_dSs2cspd - _dS2cspd) / _dSs2cspd).toFixed(2) + "%\n";
          }
        }
      }
      
      // Add connection details to the statistics pane
      // Is the connection receiver limited ?
      if (_dRwintime > NDTConstants.BUFFER_LIMITED) {
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "thisConnIs", null, Main.locale)
          + " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                  "limitRx", null, Main.locale) 
          + " " + (_dRwintime * NDTConstants.PERCENTAGE).toFixed(2)
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                            "pctOfTime", null, Main.locale) + ".\n";
        emailText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "thisConnIs", null, Main.locale)
          + " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                  "limitRx", null, Main.locale) 
          + " " + (_dRwintime * NDTConstants.PERCENTAGE).toFixed(2)
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                            "pctOfTime", null, Main.locale) + ".\n%0A";
        pub_pctRcvrLimited = _dRwintime * NDTConstants.PERCENTAGE;
        if (((2 * _dRwin) / _dRttsec) < mylink) {
          // multiplying by 2 to counter round-trip
          statsText += 
            " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                  "incrRxBuf", null, Main.locale) 
            + " (" + (_iMaxRwinRcvd / NDTConstants.KILO_BITS).toFixed(2)
            + " KB)" + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                       "willImprove",
                                                       null, Main.locale) + "\n";
        }
      }
      // Is the connection sender limited ?
      if (_dSendtime > NDTConstants.BUFFER_LIMITED) {
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "thisConnIs", null, Main.locale) 
          + " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                  "limitTx", null, Main.locale)
          + " " + (_dSendtime * NDTConstants.PERCENTAGE).toFixed(2)
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                            "pctOfTime", null, Main.locale) + ".\n";
        emailText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "thisConnIs", null, Main.locale) 
          + " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                  "limitTx", null, Main.locale)
          + " " + (_dSendtime * NDTConstants.PERCENTAGE).toFixed(2)
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                            "pctOfTime", null, Main.locale) + ".\n%0A";
               
        if ((2 * (_dSwin / _dRttsec)) < mylink) {
          // dividing by 2 to counter round-trip
          statsText += 
            " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                  "incrRxBuf", null, Main.locale) 
            + " (" + (_iSndbuf / (2 * NDTConstants.KILO_BITS)).toFixed(2)
            + " KB)" + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                       "willImprove",
                                                       null, Main.locale) + "\n";
        }
      }
      
      // Is the connection network limited ?
        // If the congestion windows is limited more than 0.5%
        // of the time, NDT claims that the connection is network
        // limited.
      if (_dCwndtime > 0.005) {
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "thisConnIs", null, Main.locale) 
          + " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                  "limitNet", null, Main.locale)
          + " " + (_dCwndtime * NDTConstants.PERCENTAGE).toFixed(2)
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                            "pctOfTime", null, Main.locale) + "\n";
        emailText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "thisConnIs", null, Main.locale) 
          + " " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                  "limitNet", null, Main.locale)
          + " " + (_dCwndtime * NDTConstants.PERCENTAGE).toFixed(2)
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                            "pctOfTime", null, Main.locale) + "\n%0A";
      }
      
      // Is the loss excessive ?
      // If the link speed is less than a T3, and loss is greater than 1 percent,
      // loss is determined to be excessive.
      if ((_dSpd < 4) && (_dLoss > 0.01))
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "excLoss", null, Main.locale) + "\n";
      
      // Update statistics on TCP negotiated optional Performance Settings
      statsText += 
        "\n" + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                               "web100tcpOpts",
                                               null, Main.locale) + "\n";
      statsText += "RFC 2018 Selective Acknowledgement: ";
      if (_iSACKEnabled == iZero)
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "off", null, Main.locale) + "\n";
      else
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "on", null, Main.locale) + "\n";
        
      statsText += "RFC 896 Nagle Algorithm: ";
      if (_iNagleEnabled == iZero)
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "off", null, Main.locale) + "\n";
      else
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "on", null, Main.locale) + "\n";
        
      statsText += "RFC 3168 Excplicit Congestion Notification: ";
      if (_iECNEnabled == iZero)
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "off", null, Main.locale) + "\n";
      else
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "on", null, Main.locale) + "\n";
        
      statsText += "RFC 1323 Time Stamping: ";
      if (_iTimestampsEnabled == NDTConstants.RFC_1323_DISABLED)
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "off", null, Main.locale) + "\n";
      else
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "on", null, Main.locale) + "\n";
        
      statsText += "RFC 1323 Window Scaling: ";
      if (_iMaxRwinRcvd < NDTConstants.TCP_MAX_RECV_WIN_SIZE)
        _iWinScaleRcvd = 0; // Max rec window size lesser than TCP's max
                            // value, so no scaling requested
                            
      // According to RFC1323, Section 2.3 the max valid value of iWinScaleRcvd is 14.
      // NDT uses 20 for this, leaving for now in case it is an error value. May need
      // to be inspected again.
      if ((_iWinScaleRcvd == 0) || (_iWinScaleRcvd > 20))
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "off", null, Main.locale) + "\n";
      else
        statsText += 
          ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "on", null, Main.locale) 
          + "; " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                   "scalingFactors", 
                                                   null, Main.locale)
          + " -  " + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                                    "server", null, Main.locale) 
          + "=" + _iWinScaleRcvd + ", " 
          + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                            "client", null, Main.locale) 
          + "=" + _iWinScaleSent + "\n";            
      statsText += "\n";
      // End tcp negotiated performance settings
      addMoreDetails();
    }
    
    private function addMoreDetails():void {
      // Adding more details to the diagnostic text, related
      // to factors influencing throughput
      diagnosisText += "\n";
      // Theoretical network limit
      diagnosisText += 
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                        "theoreticalLimit", null, Main.locale)
        + " " + (_dEstimate).toFixed(2) + " " + "Mbps\n";
      emailText += 
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                        "theoreticalLimit", null, Main.locale)
        + " " + (_dEstimate).toFixed(2) + " " + "Mbps\n%0A";
    // NDT server buffer imposed limit 
      // divide by 2 to counter "round-trip" time
      diagnosisText += 
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                        "ndtServerHas", null, Main.locale)
        + " " + (_iSndbuf / (2 * NDTConstants.KILO_BITS)).toFixed(2) + " "
        + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "kbyteBufferLimits", null, Main.locale) 
        + " " + (_dSwin / _dRttsec).toFixed(2) + " Mbps\n";
      emailText += 
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                        "ndtServerHas", null, Main.locale)
        + " " + (_iSndbuf / (2 * NDTConstants.KILO_BITS)).toFixed(2) + " "
        + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "kbyteBufferLimits", null, Main.locale) 
        + " " + (_dSwin / _dRttsec).toFixed(2) + " Mbps\n%0A";
      // PC buffer imposed throughput limit
      diagnosisText += 
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                        "yourPcHas", null, Main.locale) 
        + " " + (_iMaxRwinRcvd / NDTConstants.KILO_BITS).toFixed(2) + " "
        + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "kbyteBufferLimits", null, Main.locale) 
        + " " + (_dRwin / _dRttsec).toFixed(2) + " Mbps\n";
      emailText += 
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                        "yourPcHas", null, Main.locale) 
        + " " + (_iMaxRwinRcvd / NDTConstants.KILO_BITS).toFixed(2) + " "
        + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                          "kbyteBufferLimits", null, Main.locale) 
        + " " + (_dRwin / _dRttsec).toFixed(2) + " Mbps\n%0A";
      // Network based flow control limit imposed throughput limit
      diagnosisText += 
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                        "flowControlLimits", null, Main.locale)
        + " " + (_dCwin / _dRttsec).toFixed(2) + " Mbps\n";
      emailText += 
        ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                        "flowControlLimits", null, Main.locale)
        + " " + (_dCwin / _dRttsec).toFixed(2) + " Mbps\n%0A";
      
      // Client, Server data reports on link capacity
      if (NDTUtils.getDataRateString(_iC2sData) == null
         || NDTUtils.getDataRateString(_iC2sAck) == null
         || NDTUtils.getDataRateString(_iS2cData) == null
         || NDTUtils.getDataRateString(_iS2cAck) == null)
      {
        errMsg += "Error ! No matching data rate value found.\n";
      }
      diagnosisText += 
      "\n" + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                             "clientDataReports", null, Main.locale)
      + " '" + NDTUtils.getDataRateString(_iC2sData) + "', "
      + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                        "clientAcksReport", null, Main.locale) 
      + " '" + NDTUtils.getDataRateString(_iC2sAck) + "'\n"
      + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                        "serverDataReports", null, Main.locale) 
      + " '" + NDTUtils.getDataRateString(_iS2cData) + "', "
      + ResourceManager.getInstance().getString(NDTConstants.BUNDLE_NAME, 
                                        "serverAcksReport", null, Main.locale) 
      + " '" + NDTUtils.getDataRateString(_iS2cAck) + "'\n";
    }
    
    // Routine to store integer and double values received from the server
    // into their respective variables.    
    /**
     * Method to save integer values of various 'keys' from the test results
     * String into corresponding integer variables.
     * @param {String} sSysvarParam Key name
     * @param {int} iSysvalParam value for this key name
     */
    public function saveIntValues(sSysvarParam:String, iSysvalParam:int):void {
      // Values saved in variables : SumRTT CountRTT CurrentMSS Timeouts
      // PktsRetrans SACKsRcvd DupAcksIn MaxRwinRcvd MaxRwinSent Sndbuf
      // Rcvbuf DataPktsOut SndLimTimeRwin SndLimTimeCwnd SndLimTimeSender
      if (sSysvarParam == "MSSSent:")
        MSSSent = iSysvalParam;
      else if (sSysvarParam == "MSSRcvd:")
        MSSRcvd = iSysvalParam;
      else if (sSysvarParam == "ECNEnabled:")
        _iECNEnabled = iSysvalParam;
      else if (sSysvarParam == "NagleEnabled:")
        _iNagleEnabled = iSysvalParam;
      else if (sSysvarParam == "SACKEnabled:")
        _iSACKEnabled = iSysvalParam;
      else if (sSysvarParam == "TimestampsEnabled:")
        _iTimestampsEnabled = iSysvalParam;
      else if (sSysvarParam == "WinScaleRcvd:")
        _iWinScaleRcvd = iSysvalParam;
      else if (sSysvarParam == "WinScaleSent:")
        _iWinScaleSent = iSysvalParam;
      else if (sSysvarParam == "SumRTT:")
        _iSumRTT = iSysvalParam;
      else if (sSysvarParam == "CountRTT:")
        _iCountRTT = iSysvalParam;
      else if (sSysvarParam == "CurMSS:")
        _iCurrentMSS = iSysvalParam;
      else if (sSysvarParam == "Timeouts:")
        _iTimeouts = iSysvalParam;
      else if (sSysvarParam == "PktsRetrans:")
        _iPktsRetrans = iSysvalParam;
      else if (sSysvarParam == "SACKsRcvd:") {
        _iSACKsRcvd = iSysvalParam;
        pub_SACKsRcvd = _iSACKsRcvd;
      } else if (sSysvarParam == "DupAcksIn:")
        _iDupAcksIn = iSysvalParam;
      else if (sSysvarParam == "MaxRwinRcvd:") {
        _iMaxRwinRcvd = iSysvalParam;
        pub_MaxRwinRcvd = _iMaxRwinRcvd;
      } else if (sSysvarParam == "MaxRwinSent:")
        _iMaxRwinSent = iSysvalParam;
      else if (sSysvarParam == "Sndbuf:")
        _iSndbuf = iSysvalParam;
      else if (sSysvarParam == "X_Rcvbuf:")
        _iRcvbuf = iSysvalParam;
      else if (sSysvarParam == "DataPktsOut:")
        _iDataPktsOut = iSysvalParam;
      else if (sSysvarParam == "FastRetran:")
        _iFastRetran = iSysvalParam;
      else if (sSysvarParam == "AckPktsOut:")
        _iAckPktsOut = iSysvalParam;
      else if (sSysvarParam == "SmoothedRTT:")
        _iSmoothedRTT = iSysvalParam;
      else if (sSysvarParam == "CurCwnd:")
        _iCurrentCwnd = iSysvalParam;
      else if (sSysvarParam == "MaxCwnd:")
        _iMaxCwnd = iSysvalParam;
      else if (sSysvarParam == "SndLimTimeRwin:")
        _iSndLimTimeRwin = iSysvalParam;
      else if (sSysvarParam == "SndLimTimeCwnd:")
        _iSndLimTimeCwnd = iSysvalParam;
      else if (sSysvarParam == "SndLimTimeSender:")
        _iSndLimTimeSender = iSysvalParam;
      else if (sSysvarParam == "DataBytesOut:")
        _iDataBytesOut = iSysvalParam;
      else if (sSysvarParam == "AckPktsIn:")
        _iAckPktsIn = iSysvalParam;
      else if (sSysvarParam == "SndLimTransRwin:")
        _iSndLimTransRwin = iSysvalParam;
      else if (sSysvarParam == "SndLimTransCwnd:")
        _iSndLimTransCwnd = iSysvalParam;
      else if (sSysvarParam == "SndLimTransSender:")
        _iSndLimTransSender = iSysvalParam;
      else if (sSysvarParam == "MaxSsthresh:")
        _iMaxSsthresh = iSysvalParam;
      else if (sSysvarParam == "CurRTO:") {
        _iCurrentRTO = iSysvalParam;
        pub_CurRTO = _iCurrentRTO;
      } else if (sSysvarParam == "MaxRTO:")
        pub_MaxRTO = iSysvalParam;
      else if (sSysvarParam == "MinRTO:")
        pub_MinRTO = iSysvalParam;
      else if (sSysvarParam == "MinRTT:")
        pub_MinRTT = iSysvalParam;
      else if (sSysvarParam == "MaxRTT:")
        pub_MaxRTT = iSysvalParam;
      else if (sSysvarParam == "CurRwinRcvd:")
        pub_CurRwinRcvd = iSysvalParam;
      else if (sSysvarParam == "Timeouts:")
        pub_Timeouts = iSysvalParam;
      else if (sSysvarParam == "c2sData:")
        _iC2sData = iSysvalParam;
      else if (sSysvarParam == "c2sAck:")
        _iC2sAck = iSysvalParam;
      else if (sSysvarParam == "s2cData:")
        _iS2cData = iSysvalParam;
      else if (sSysvarParam == "s2cAck:")
        _iS2cAck = iSysvalParam;
      else if (sSysvarParam == "PktsOut:")
        _iPktsOut = iSysvalParam;
      else if (sSysvarParam == "mismatch:") {
        mismatch = iSysvalParam;
        pub_mismatch = mismatch;
      } else if (sSysvarParam == "congestion:") {
        congestion = iSysvalParam;
        pub_congestion = congestion;
      } else if (sSysvarParam == "bad_cable:") {
        bad_cable = iSysvalParam;
        pub_Bad_cable = bad_cable;
      } else if (sSysvarParam == "half_duplex:")
        half_duplex = iSysvalParam;
      else if (sSysvarParam == "CongestionSignals:")
        _iCongestionSignals = iSysvalParam;
      else if (sSysvarParam == "RcvWinScale:") {
        if (_iRcvWinScale > 15)
          _iRcvWinScale = 0;
        else
          _iRcvWinScale = iSysvalParam;
      }
    }
    
    /**
     * Method to save double values of various 'keys' from the test results
     * string into corresponding double variables.
     * @param {String} sSysvarParam key name
     * @param {Number} dSysvalParam value for this key name
     */
    public function saveDblValues(sSysvarParam:String, dSysvalParam:Number):void {
      
      if (sSysvarParam == "bw:")
        _dEstimate = dSysvalParam;
      else if (sSysvarParam == "loss:") {
        _dLoss = dSysvalParam;
        pub_loss = _dLoss;
      } else if (sSysvarParam == "avgrtt:") {
        _dAvgrtt = dSysvalParam;
        pub_avgrtt = _dAvgrtt;
      } else if (sSysvarParam == "waitsec:")
        _dWaitsec = dSysvalParam;
      else if (sSysvarParam == "timesec:")
        _dTimesec = dSysvalParam;
      else if (sSysvarParam == "order:")
        _dOrder = dSysvalParam;
      else if (sSysvarParam == "rwintime:")
        _dRwintime = dSysvalParam;
      else if (sSysvarParam == "sendtime:")
        _dSendtime = dSysvalParam;
      else if (sSysvarParam == "cwndtime:") {
        _dCwndtime = dSysvalParam;
        pub_cwndtime = _dCwndtime;
      } else if (sSysvarParam == "rttsec:")
        _dRttsec = dSysvalParam;
      else if (sSysvarParam == "rwin:")
        _dRwin = dSysvalParam;
      else if (sSysvarParam == "swin:")
        _dSwin = dSysvalParam;
      else if (sSysvarParam == "cwin:")
        _dCwin = dSysvalParam;
      else if (sSysvarParam == "spd:")
        _dSpd = dSysvalParam;
      else if (sSysvarParam == "aspd:")
        _dAspd = dSysvalParam;
    }
    
    /**
     * Constructor that initializes the values and calls the function to start
     * interpreting the results.
     */
    public function TestResults(_sTestResults:String, testSuite:int) {
      _yTests = testSuite;
      interpretResults(_sTestResults);
    }
  }
}

