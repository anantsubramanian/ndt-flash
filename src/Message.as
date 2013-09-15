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
  
  /**
   * Class to define an NDT message. A message is characterized by a type,
   * a length and a body. All the types are defined in the class MessageType.
   * All the valid types are defined in the class MessageType.
   * The client and server exchange messages as sequence of bytes, where
   * - the 1st byte contains the type of a message,
   * - the 2nd and 3rd bytes contain the length of the message.
   */
  public class Message {
    private var type_:int;
    // TODO: Change to private.
    public var body_:ByteArray;

    public function get type():int {
      return type_;
    }
    public function setType(rawMessage:ByteArray):void {
      if (rawMessage.length == 0)
         throw new Error("Message without type");
      type_ = rawMessage[0];
    }

    public function get body():ByteArray {
      return body_;
    }
    
    /**
     * Utility method to initialize Message body
     * @param {int} iParamSize ByteArray size
     */
    public function initBodySize(iParamSize:int):void {
      this.body_ = new ByteArray();
      var pos:int = 0;
      while (body_.length < iParamSize) {
        body_[pos] = 0;
        pos++;
      }
      body_.position = 0;
    }
  }
}

