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
  import flash.net.Socket;
  
  /**
   * Class aggregating operations that can be performed for sending / receiving
   * or reading Protocol messages.  
   */
  public class Protocol {
    public var ctlSocket:Socket = null;
    
    /**
     * Constructor that accepts socket over which to communicate as parameter
     * @param {Socket} ctlSocketParam Object used to send the protocol messages
     */
    public function Protocol(ctlSocketParam:Socket) {
      ctlSocket = ctlSocketParam;      
    }
  }
}

