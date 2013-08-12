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
	
	public class NDTUtils {

		/*
		
			Class that defines utility methods used by the NDT.
		
		*/
		
		/*
			Utility method to print a double value upto the
			hundereth place.
			
			@param paramDblToFormat
						Double number to format
						
			@return String value of double number
		*/
		public static function prtdbl(paramDblToFormat:Number):String {
			var str:String = null;
			var i:int;
			
			if(paramDblToFormat == 0) {
				return("0");
			}
			
			str = paramDblToFormat.toString();
			i = str.indexOf(".");
			
			if(i == -1)
				return (new String(str + ".0"));
			
			i += 3;
			if(i > str.length) {
				i -= 1;
			}
			if(i > str.length) {
				i -= 1;
			}
			
			return (str.substring(0, i));
		}
		
		public static function trim(sParam:String):String {
			var i:int = 0;
			
			while(sParam.charAt(i) == " ") {
				i++;
			}
			
			var j:int = sParam.length;
			
			while(sParam.charAt(j) == " ") {
				j--;
			}
			
			return sParam.substring(i, j);
		}
	}
	
}
