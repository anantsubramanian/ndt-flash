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
   * Class to define an NDT message. A message is characterized by
   * - a type:
   *     The type of a message is stored in the 1st byte of the body.
         All the valid types are defined in the class MessageType.
   * - a lenght:
   *     The lenght of a message is stored in the 2nd and 3rd bytes of the body.
   * - a body.
   */
  public class Message {
    // TODO: Change to private.
    public var body_:ByteArray;

    public function get type():uint {
      if (body_.length > 0)
        return body_[0];
      else
        return MessageType.UNDEF_TYPE;
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

