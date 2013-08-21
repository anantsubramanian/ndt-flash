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
    private var ctlSocket:Socket = null;
    
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
    
    /**
     * Populate Message byte array with specific number of bytes of data from
     * socket
     * @param {Message} msgParam Message object to be populated
     * @param {int} iParamAmount Specified number of bytes to be read
     * @return {int} Number of bytes populated
     */
    public function readn(msgParam:Message, iParamAmount:int):int {
      var read:int = 0;
      var tmp:int;
      msgParam.initBodySize(iParamAmount);
      while (read != iParamAmount) {
        tmp = readBytesAndReturn(ctlSocket, msgParam._yaBody,
                                 read, iParamAmount - read);
        if (tmp <= 0) {
          // end of file 
          return read;
        }
        read += tmp;
      }
      return read;
    }
    
    /**
     * Reads bytes into a byte array and returns the number of successfully read
     * bytes. Equivalent of the Java function read(bytes [], offset, length)
     * @param {Socket} socket Socket object to read from
     * @param {ByteArray} bytes Byte array to read bytes into
     * @param {uint} offset Offset value to start
     * @param {uint} len Length to be read
     * @return {int} The number of successfully read bytes
     */
    public function readBytesAndReturn(socket:Socket, bytes:ByteArray,
                                       offset:uint, len:uint):int {
      var b:ByteArray = new ByteArray();
      var bytesread:int = -1;
      
      if (len == 0)
        return 0;
      if(socket.bytesAvailable > 0)
        bytesread = 0;
      while (socket.bytesAvailable && bytesread < len) {
        b[bytesread] = socket.readByte();
        bytesread++;
      }
      for (var count:int = 0; count < bytesread; count++) {
        bytes[count + offset] = b[count];
      }
      return bytesread;
    }
    
    /**
     * Receive message at end-point of socket
     * @param {Message} msgParam Message object to read data into
     * @return {int} Values:
     *    a) Success - value=0 : successfully read expected number of bytes.
     *    b) Error   - value=1 : error reading ctrl-message length and data type
     *                           itself, since NDTP-control packet has to be
     *                           atleast 3 octets long.
     *                 value=3 : error, mismatch between 'length' field of ctrl-
     *                           -message and actual data read.
     */
    public function recv_msg(msgParam:Message):int {
      var Length:int;
      if (readn(msgParam, 3) != 3) {
        return 1;
      }
      
      var yaMsgBody:ByteArray = msgParam.getBody();
      msgParam.setType(yaMsgBody[0]);
      // Get data length
      Length = (int(yaMsgBody[1]) & 0xFF) << 8;
      Length += int(yaMsgBody[2]) & 0xFF;
      if (readn(msgParam, Length) != Length) {
        return 3;
      }
      return 0;
    }
  }
}

