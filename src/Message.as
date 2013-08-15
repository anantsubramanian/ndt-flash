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
	import flash.utils.ByteArray;
	
	public class Message {

		/*
			Class to define Message. Messages are composed of a "type" and a body. Some
 			examples of message types are : COMM_FAILURE, SRV_QUEUE, MSG_LOGIN,
 			TEST_PREPARE. Messages are defined to have a "length" field too. Currently, 2
 			bytes of the message "body" byte array are often used to store length (For
 			example, second/third array positions)
		*/
		
		// variables declaration section
		
		var _yType:int;
		var _yaBody:ByteArray;
		
		/*
			Get Message Type
			
			@return int indicating Message Type
		*/
		
		public function getType():int {
			return _yType;
		}
		
		/*
			Set Message Type
			
			@param bParamType
						integer (representing byte) indicating Message Type
		*/
		public function setType(bParamType:int):void {
			this._yType = bParamType;
		}
		
		/*
			Get Message body as array
			
			@return byte array message body
		*/
		
		public function getBody():ByteArray {
			return _yaBody;
		}
		
		/*
			Set Message body, given a byte array input
			
			@param baParamBody
						message body byte array
		*/
		public function setBody(baParamBody:ByteArray):void {
			var iParamSize:int = 0;
			if(baParamBody != null) {
				iParamSize = baParamBody.length;
			}
			_yaBody = new ByteArray();
			arraycopy(baParamBody, 0, _yaBody, 0, iParamSize);
			
		}
		
		/*
			Set Message body, given a byte array and a size parameter. This may be
			useful if user wants to initialize the message, and then continue to
	 		populate it later. This method is unused currently.
		*/
		
		public function setBodySize(baParamBody:ByteArray, iParamSize:int):void {
			_yaBody = new ByteArray();
			arraycopy(baParamBody, 0, _yaBody, 0, iParamSize);
		}
		
		/*
			Utility method to initialize Message body
			
			@param iParamSize
						byte array size
		*/
		public function initBodySize(iParamSize:int):void {
			this._yaBody = new ByteArray();
			var pos:int = 0;
			while(_yaBody.length < iParamSize) {
				_yaBody[pos] = 0;
				pos++;
			}
			_yaBody.position = 0;
		}
		
		/*
		
			Function to copy certain number of bytes from a particular
			position of source bytearray to a particular position of the 
			destination bytearray.
			
			@param src
						source ByteArray
			
			@param srcpos
						position to start copying from source
			
			@param dest
						destination ByteArray
			
			@param destpos
						position to start copying to at the destination
						
			@param len
						length of array to be copied
			
		*/
		
		private function arraycopy(src:ByteArray, srcpos:int, dest:ByteArray, destpos:int, len:int):void {
			var srccounter:int = srcpos;
			var destcounter:int = destpos;
			for(; srccounter < len; srccounter++, destcounter++)
			{
				dest[destcounter] = src[srccounter];
			}
		}

	}
	
}
