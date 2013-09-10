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
  import mx.resources.ResourceManager;
  /**
   * Class that defines utility methods used by NDT.
   */
  public class NDTUtils {    
    /**
     *  Utility method to print Text values for data speed related keys.
     *  @param {int} paramIntVal Parameter for which we find text value
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
  }
}

