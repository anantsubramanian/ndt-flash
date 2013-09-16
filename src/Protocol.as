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
  import flash.utils.ByteArray;
  import flash.errors.EOFError;
  import flash.utils.getTimer;
  
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
    
    /**
     * Send message given its Type and data
     * @param {int} bParamType Control Message Type
     * @param {int} bParamToSend Data value to send
     */
    public function send_msg(bParamType:int, bParamToSend:int):void {
      var tab:ByteArray = new ByteArray();
      tab.writeByte(bParamToSend);
      send_msg_array(bParamType, tab);
    }
    
    /**
     * Send protocol messages given their type and data byte array
     * @param {int} bParamType Control Message Type
     * @param {ByteArray} bParamToSend Data value array to send
     */
    public function send_msg_array(bParamType:int, bParamToSend:ByteArray):void {
      var header:ByteArray = new ByteArray();
      header[0] = bParamType;
      
      // 2 bytes are used to hold data length. Thus, max(data length) = 65535
      header[1] = (bParamToSend.length >> 8);
      header[2] = bParamToSend.length;
      
      // write data to Socket
      ctlSocket.writeBytes(header);
      ctlSocket.writeBytes(bParamToSend);
      ctlSocket.flush();
    }
  }
}

