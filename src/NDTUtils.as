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
  /**
   * Class that defines utility methods used by the NDT.
   */
  public class NDTUtils {
    /**
     * Utility method to print a double value upto the hundereth place. 
     * @param {Number} paramDblToFormat Double number to format
     * @return {String} Value of double number upto hundereth place.
     */
    public static function prtdbl(paramDblToFormat:Number):String {
      var str:String = null;
      var i:int;
      
      if (paramDblToFormat == 0) {
        return("0");
      }
      
      str = paramDblToFormat.toString();
      i = str.indexOf(".");
      if (i == -1)
        return (new String(str + ".0"));
      
      i += 3;
      if (i > str.length) {
        i -= 1;
      }
      if (i > str.length) {
        i -= 1;
      }
      return (str.substring(0, i));
    }
    
    /**
     * Function that trims the spaces before and after a String.
     */
    public static function trim(sParam:String):String {
      var i:int = 0;
      
      if (sParam == null)
        return null;
      
      while (sParam.charAt(i) == " ") {
        i++;
      }    
      var j:int = sParam.length;
      while (sParam.charAt(j) == " ") {
        j--;
      }
      return sParam.substring(i, j);
    }
    
    /**
     *  Utility method to print Text values for data speed related keys.
     *  @param {int} paramIntVal Parameter for which we find text value
     *  @return {String} Textual name for input parameter
     */
    public static function prttxt(paramIntVal:int):String {
      var strNameTxt:String = null;
  
      switch (paramIntVal) {
      case (NDTConstants.DATA_RATE_SYSTEM_FAULT):
        strNameTxt = DispMsgs.systemFault; 
        break;
      case NDTConstants.DATA_RATE_RTT:
        strNameTxt = DispMsgs.rtt; 
        break;
      case NDTConstants.DATA_RATE_DIAL_UP:
        strNameTxt = DispMsgs.dialup2;
        break;
      case NDTConstants.DATA_RATE_T1:
        strNameTxt = NDTConstants.T1_STR;
        break;
      case NDTConstants.DATA_RATE_ETHERNET:
        strNameTxt = NDTConstants.ETHERNET_STR;
        break;
      case NDTConstants.DATA_RATE_T3:
        strNameTxt = NDTConstants.T3_STR;
        break;
      case NDTConstants.DATA_RATE_FAST_ETHERNET:
        strNameTxt = NDTConstants.FAST_ETHERNET; 
        break;
      case NDTConstants.DATA_RATE_OC_12:
        strNameTxt = NDTConstants.OC_12_STR;
        break;
      case NDTConstants.DATA_RATE_GIGABIT_ETHERNET:
        strNameTxt = NDTConstants.GIGABIT_ETHERNET_STR; 
        break;
      case NDTConstants.DATA_RATE_OC_48:
        strNameTxt = NDTConstants.OC_48_STR;
        break;
      case NDTConstants.DATA_RATE_10G_ETHERNET:
        strNameTxt = NDTConstants.TENGIGABIT_ETHERNET_STR; 
        break;
      } // end switch
      return (strNameTxt);
    } // prttxt() method ends
  }
}

