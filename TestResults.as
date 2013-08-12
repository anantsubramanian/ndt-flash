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
	
	public class TestResults {
		
		/*
		
			Class that interprets the results of the tests. These results
			are stored in variables that can be accessed through JavaScript.
			
		*/
		
		// variables declaration section
		
		private static var _yTests:int;	// Requested test-suite
		
		// Section : "pub_xxx" variables. Declared
		// as private but they have getter/setter methods.
		
		private static var pub_status:String;
		private static var pub_flashVer:String;
		private static var pub_host:String;
		private static var pub_osName:String;
		private static var pub_osArch:String;
		private static var pub_AccessTech:String;
		private static var pub_clientIP:String;
		private static var pub_natBox:String;
		
		private static var pub_SACKsRcvd:int;
		private static var pub_MaxRwinRcvd:int;
		private static var pub_CurRTO:int;
		private static var pub_MaxRTO:int;
		private static var pub_MinRTO:int;
		private static var pub_MinRTT:int;
		private static var pub_MaxRTT:int;
		private static var pub_CurRwinRcvd:int;
		private static var pub_Timeouts:int;
		private static var pub_mismatch:int;
		private static var pub_congestion:int;
		private static var pub_Bad_cable:int;
		private static var pub_DupAcksOut:int;
		
		private static var pub_loss:Number;
		private static var pub_avgrtt:Number;
		private static var pub_cwndtime:Number;
		private static var pub_c2sspd:Number;
		private static var pub_s2cspd:Number;
		private static var pub_pctRcvrLimited:Number;
		private static var pub_time:Number;
		private static var pub_bytes:Number;
		
		private static var pub_TimeStamp:Date;
		
		// Section : web100 integer variables
		
		private static var MSSSent:int;
		private static var MSSRcvd:int;
		private static var _iECNEnabled:int;
		private static var _iNagleEnabled:int;
		private static var _iSACKEnabled:int;
		private static var _iTimestampsEnabled:int;
		private static var _iWinScaleRcvd:int;
		private static var _iWinScaleSent:int;
		private static var _iSumRTT:int;
		private static var _iCountRTT:int;
		private static var _iCurrentMSS:int;
		private static var _iTimeouts:int;
		private static var _iPktsRetrans:int;
		private static var _iSACKsRcvd:int;
		private static var _iMaxRwinRcvd:int;
		private static var _iDupAcksIn:int;
		private static var _iMaxRwinSent:int;
		private static var _iSndbuf:int;
		private static var _iRcvbuf:int;
		private static var _iDataPktsOut:int;
		private static var _iFastRetran:int;
		private static var _iAckPktsOut:int;
		private static var _iSmoothedRTT:int;
		private static var _iCurrentCwnd:int;
		private static var _iMaxCwnd:int;
		private static var _iSndLimTimeRwin:int;
		private static var _iSndLimTimeCwnd:int;
		private static var _iSndLimTimeSender:int;
		private static var _iDataBytesOut:int;
		private static var _iAckPktsIn:int;
		private static var _iSndLimTransRwin:int;
		private static var _iSndLimTransCwnd:int;
		private static var _iSndLimTransSender:int;
		private static var _iMaxSsthresh:int;
		private static var _iCurrentRTO:int;
		private static var _iC2sData:int;
		private static var _iC2sAck:int;
		private static var _iS2cData:int;
		private static var _iS2cAck:int;
		private static var _iPktsOut:int;
		private static var mismatch:int;
		private static var congestion:int;
		private static var bad_cable:int;
		private static var half_duplex:int;
		private static var _iCongestionSignals:int;
		private static var _iRcvWinScale:int;
		
		// Section : web100 double variables
		
		private static var _dEstimate:Number;
		private static var _dLoss:Number;
		private static var _dAvgrtt:Number;
		private static var _dWaitsec:Number;
		private static var _dTimesec:Number;
		private static var _dOrder:Number;
		private static var _dRwintime:Number;
		private static var _dSendtime:Number;
		private static var _dCwndtime:Number;
		private static var _dRttsec:Number;
		private static var _dRwin:Number;
		private static var _dSwin:Number;
		private static var _dCwin:Number;
		private static var _dSpd:Number;
		private static var _dAspd:Number;
		private static var mylink:Number;
		private static var _dSc2sspd:Number;
		private static var _dSs2cspd:Number;
		private static var _dS2cspd:Number;
		private static var _dC2sspd:Number;
		
		// Section : Misc variables
		
		private static var _sUserAgent:String;
		
		// Section : S2C Throughput Test
		
		public static var s2cspd:Number;
						
		
		public static var consoleOutput:String = "";
		public static var errMsg:String = "";
		public static var statsText:String = "";
		public static var traceOutput:String = "";
		public static var diagnosisText:String = "";
		public static var emailText:String = "";
		
		public static var _bFailed:Boolean;
		
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
			if(pub_mismatch == 0)
				return "no";
			else
				return "yes";
		}
		
		public static function get_congestion():String {
			if(pub_congestion == 1)
				return "yes";
			else
				return "no";
		}
		
		public static function get_Bad_cable():String {
			if(pub_Bad_cable == 1)
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
			if(pub_TimeStamp != null)
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
		
		// Setter methods
		
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
		
		/*
		
			Function that takes a Human readable string containing
			the results and assigns the key-value pairs to the correct
			variables.
			
			These values are then interpreted to make decisions about 
			various measurement items.
			
			@param sTestResParam
							String containing all the results
		
		*/
		public function interpretResults(sTestResParam:String):void {
			
			var tokens:Array;
			var i:int = 0;
			var sSysvar:String, sStrval:String;
			var iSysval:int;
			var dSysval2:Number, j:Number;
			var sOsName:String, sOsArch:String, sFlashVer:String, sClient:String;
			
			// extract the key-value pairs
			
			tokens = sTestResParam.split(" ");
			sSysvar = null;
			sStrval = null;
			for each(var token:String in tokens) {
				if(!(i & 1)) {
					sSysvar = tokens[i];
				}
				else {
					sStrval = tokens[i];
					diagnosisText += sSysvar + " " + sStrval + "\n";
					emailText += sSysvar + " " + sStrval + "\n%0A";
					if(sStrval.indexOf(".") == -1) {
						
						// no decimal point hence an integer
						iSysval = parseInt(sStrval);
						if(isNaN(iSysval)) {
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
			}
			
			// Read client details from the SWF environment
			sOsName = Capabilities.os;
			pub_osName = sOsName;
			
			sOsArch = Capabilities.cpuArchitecture;
			pub_osArch = sOsArch;
			
			sFlashVer = Capabilities.version;
			pub_flashVer = sFlashVer;
			
			if(sOsArch.indexOf("x86") == 0)
				sClient = DispMsgs.pc;
			else
				sClient = DispMsgs.workstation;
				
			// Calculate some variables and determine patch conditions
			// Note : Calculations now done by server and the results are
			// sent to the client for printing.
			
			if(_iCountRTT > 0) {
				
				// Now write some messages to the screen
				// Access speed / technology details added to consoleOutput
				// and mailing text. Link speed is also assigned.
				
				if(_iC2sData < NDTConstants.DATA_RATE_ETHERNET) {
					if(_iC2sData < NDTConstants.DATA_RATE_RTT) {
						
						// data was not sufficient to determine bottleneck type
						consoleOutput += DispMsgs.unableToDetectBottleneck + "\n";
						emailText += "Server unable to determine bottleneck link type.\n%0A";
						pub_AccessTech = "Connection type unknown";
					}
					else {
						// get link speed
						
						consoleOutput += DispMsgs.your + " " + sClient
										 + " " + DispMsgs.connectedTo + " ";
						emailText += DispMsgs.your + " " + sClient
									 + " " + DispMsgs.connectedTo + " ";
									 
						if(_iC2sData == NDTConstants.DATA_RATE_DIAL_UP) {
							consoleOutput += DispMsgs.dialup + "\n";
							emailText += DispMsgs.dialup + "\n%0A";
							mylink = 0.064;	// 64 kbps speed
							pub_AccessTech = "Dial-up Modem";
						}
						else {
							consoleOutput += DispMsgs.cabledsl + "\n";
							emailText += DispMsgs.cabledsl + "\n%0A";
							mylink = 3;
							pub_AccessTech = "Cable/DSL modem";
						}
					}
				}
				else {
					consoleOutput += DispMsgs.theSlowestLink + " ";
					emailText += DispMsgs.theSlowestLink + " ";
					
					switch(_iC2sData) {
						
						case NDTConstants.DATA_RATE_ETHERNET : 
								consoleOutput += DispMsgs.mbps10 
												 + "\n";
								emailText += DispMsgs.mbps10 + "\n%0A";
								mylink = 10;
								pub_AccessTech = "10 Mbps Ethernet";
								break;
								
						case NDTConstants.DATA_RATE_T3 :
								consoleOutput += DispMsgs.mbps45
												 + "\n";
								emailText += DispMsgs.mbps45 + "\n%0A";
								mylink = 45;
								pub_AccessTech = "45 Mbps T3/DS3 subnet";
								break;
								
						case NDTConstants.DATA_RATE_FAST_ETHERNET :
								consoleOutput += "100 Mbps ";
								emailText += "100 Mbps";
								mylink = 100;
								pub_AccessTech = "100 Mbps Ethernet";
								
								// Fast ethernet. Determine if half/full duplex link was found
								if(half_duplex == 0) {
									consoleOutput += DispMsgs.fullDuplex + "\n";
									emailText += DispMsgs.fullDuplex + "\n%0A";
								}
								else {
									consoleOutput += DispMsgs.halfDuplex + "\n";
									emailText += DispMsgs.halfDuplex + "\n%0A";
								}
								break;
						
						case NDTConstants.DATA_RATE_OC_12 :
								consoleOutput += DispMsgs.mbps622 + "\n";
								emailText += DispMsgs.mbps622 + "\n%0A";
								mylink = 622;
								pub_AccessTech = "622 Mbps OC-12";
								break;
								
						case NDTConstants.DATA_RATE_GIGABIT_ETHERNET :
								consoleOutput += DispMsgs.gbps1 + "\n";
								emailText += DispMsgs.gbps1 + "\n%0A";
								mylink = 1000;
								pub_AccessTech = "1.0 Gbps Gigabit Ethernet";
								break;
								
						case NDTConstants.DATA_RATE_OC_48 :
								consoleOutput += DispMsgs.gbps2_4 + "\n";
								emailText += DispMsgs.gbps2_4 + "\n%0A";
								mylink = 2400;
								pub_AccessTech = "2.4 Gbps OC-48";
								break;
								
						case NDTConstants.DATA_RATE_10G_ETHERNET :
								consoleOutput += DispMsgs.gbps10 + "\n";
								emailText += DispMsgs.gbps10 + "\n%0A";
								mylink = 10000;
								pub_AccessTech = "10 Gigabit Ethernet/OC-192";
								break;
						
						default:
								errMsg += "No _iC2sData option match";
								break;
								
					} // end switch-case
				} // end inner else
			} // end outer if
			
			// duplex mismatch
			switch(mismatch) {
				
				case NDTConstants.DUPLEX_NOK_INDICATOR: //1
						consoleOutput += DispMsgs.oldDuplexMismatch + "\n";
						emailText += DispMsgs.oldDuplexMismatch + "\n%0A"
						break;
					
				case NDTConstants.DUPLEX_SWITCH_FULL_HOST_HALF:
						consoleOutput += DispMsgs.duplexFullHalf + "\n";
						emailText += DispMsgs.duplexFullHalf + "\n%0A";
						break;
					
				case NDTConstants.DUPLEX_SWITCH_HALF_HOST_FULL:
						consoleOutput += DispMsgs.duplexHalfFull + "\n";
						emailText += DispMsgs.duplexHalfFull + "\n%0A";
						break;
					
				case NDTConstants.DUPLEX_SWITCH_FULL_HOST_HALF_POSS:
						consoleOutput += DispMsgs.possibleDuplexFullHalf + "\n";
						emailText += DispMsgs.possibleDuplexFullHalf + "\n%0A";
						break;
					
				case NDTConstants.DUPLEX_SWITCH_HALF_HOST_FULL_POSS:
						consoleOutput += DispMsgs.possibleDuplexHalfFull + "\n";
						emailText += DispMsgs.possibleDuplexHalfFull + "\n%0A";
						break;
					
				case NDTConstants.DUPLEX_SWITCH_HALF_HOST_FULL_WARN:
						consoleOutput += DispMsgs.possibleDuplexHalfFullWarning + "\n";
						emailText += DispMsgs.possibleDuplexHalfFullWarning + "\n%0A";
						break;
					
				case NDTConstants.DUPLEX_OK_INDICATOR:
						if (bad_cable == 1) {
							consoleOutput += DispMsgs.excessiveErrors + "\n";
							emailText += DispMsgs.excessiveErrors + "\n%0A";
						}
						if (congestion == 1) {
							consoleOutput += DispMsgs.otherTraffic + "\n";
							emailText += DispMsgs.otherTraffic + "\n%0A";
						}
		
						// We seem to be transmitting less than link speed possibly due to
						// a receiver window setting (i.e calculated bandwidth is greater
						// than measured throughput). Advise appropriate size
						
						// Note: All comparisons henceforth of ((window size * 2/rttsec) < mylink)
						// are along the same logic
						
						if (((2 * _dRwin) / _dRttsec) < mylink) {  // multiply by 2 to counter round-trip
								
							// link speed is in Mbps. Convert it back to kbps (*1000),
							// and bytes (/8)
							
							j = Number(((mylink * _dAvgrtt) * NDTConstants.KILO)) / NDTConstants.EIGHT / NDTConstants.KILO_BITS;
							if (j > Number(_iMaxRwinRcvd)) {
								consoleOutput += DispMsgs.receiveBufferShouldBe + " "
												 + NDTUtils.prtdbl(j) + DispMsgs.toMaximizeThroughput
												 + "\n";
								emailText += DispMsgs.receiveBufferShouldBe + " "
											 + NDTUtils.prtdbl(j) + DispMsgs.toMaximizeThroughput
											 + "\n%0A";
							}
						}
						break;
					
				default: // default for indication of no match for mismatch variable
						break;
			}
			
			// C2S throughput test: Packet queueing
			if((_yTests & NDTConstants.TEST_C2S) == NDTConstants.TEST_C2S) {
				if(_dSc2sspd < (_dC2sspd * (1.0 - NDTConstants.VIEW_DIFF))) {
					consoleOutput += DispMsgs.c2sPacketQueuingDetected + "\n";
				}
			}
			
			// S2C throughput test: Packet queueing
			if((_yTests & NDTConstants.TEST_S2C) == NDTConstants.TEST_S2C) {
				if(_dS2cspd < (_dSs2cspd * (1.0 - NDTConstants.VIEW_DIFF))) {
					consoleOutput += DispMsgs.s2cPacketQueuingDetected + "\n";
				}
			}
			
			updateStatisticsText();
		}
		
		/*
			
			Function that updates the text to be shown in the statistics
			section.
			
		*/
		
		public function updateStatisticsText():void {
			
			var iZero:int = 0;
			
			// Add client information
			statsText += "\n\t-----  " + DispMsgs.clientInfo + "------\n";
			statsText += DispMsgs.osData + " " + DispMsgs.Name + " & " 
						 + DispMsgs.version + " = " + pub_osName + ", "
						 + DispMsgs.architecture + " = " + pub_osArch + "\n";
			statsText += DispMsgs.flashData + ": " + DispMsgs.version
						 + " = " + pub_flashVer + "\n";
						 
			statsText += "\n\t------ " + DispMsgs.web100Details + " ------\n";
			
			// Now add data about access speeds / technology
			// Slightly different from the earlier switch 
			// (that added data to the results pane) in that
			// negative values are checked for too.
			
			switch(_iC2sData) {
				
				case NDTConstants.DATA_RATE_INSUFFICIENT_DATA :
						statsText += DispMsgs.insufficient + "\n";
						break;
						
				case NDTConstants.DATA_RATE_SYSTEM_FAULT :
						statsText += DispMsgs.ipcFail + "\n";
						break;
					
				case NDTConstants.DATA_RATE_RTT :
						statsText += DispMsgs.rttFail + "\n";
						break;
						
				case NDTConstants.DATA_RATE_DIAL_UP :
						statsText += DispMsgs.foundDialup + "\n";
						break;
						
				case NDTConstants.DATA_RATE_T1 :
						statsText += DispMsgs.foundDsl + "\n";
						break;
						
				case NDTConstants.DATA_RATE_ETHERNET :
						statsText += DispMsgs.found10mbps + "\n";
						break;
						
				case NDTConstants.DATA_RATE_T3 :
						statsText += DispMsgs.found45mbps + "\n";
						break;
				
				case NDTConstants.DATA_RATE_FAST_ETHERNET :
						statsText += DispMsgs.found100mbps + "\n";
						break;
						
				case NDTConstants.DATA_RATE_OC_12 :
						statsText += DispMsgs.found622mbps + "\n";
						break;
						
				case NDTConstants.DATA_RATE_GIGABIT_ETHERNET :
						statsText += DispMsgs.found1gbps + "\n";
						break;
						
				case NDTConstants.DATA_RATE_OC_48 :
						statsText += DispMsgs.found2_4gbps + "\n";
						break;
				
				case NDTConstants.DATA_RATE_10G_ETHERNET :
						statsText += DispMsgs.found10gbps + "\n";
						break;
			}
			
			// Add decisions about duplex mode, congestion & duplex mismatch
			if(half_duplex == NDTConstants.DUPLEX_OK_INDICATOR)
				statsText += DispMsgs.linkFullDpx + "\n";
			else
				statsText += DispMsgs.linkHalfDpx + "\n";
				
			if(congestion == NDTConstants.CONGESTION_NONE)
				statsText += DispMsgs.congestNo + "\n";
			else
				statsText += DispMsgs.congestYes + "\n";
				
			if(bad_cable == NDTConstants.CABLE_STATUS_OK)
				statsText += DispMsgs.cablesOk + "\n";
			else
				statsText += DispMsgs.cablesNok + "\n";
				
			if(mismatch == NDTConstants.DUPLEX_OK_INDICATOR)
				statsText += DispMsgs.duplexOk + "\n";
			else if (mismatch == NDTConstants.DUPLEX_NOK_INDICATOR) {
				statsText += DispMsgs.duplexNok + " ";
				emailText += DispMsgs.duplexNok + " ";
			}
			else if (mismatch == NDTConstants.DUPLEX_SWITCH_FULL_HOST_HALF) {
				statsText += DispMsgs.duplexFullHalf + "\n";
				emailText += DispMsgs.duplexFullHalf + "\n%0A";
			}
			else if (mismatch == NDTConstants.DUPLEX_SWITCH_HALF_HOST_FULL) {
				statsText += DispMsgs.duplexHalfFull + "\n";
				emailText += DispMsgs.duplexHalfFull + "\n%0A";
			}
			
					
			statsText += "\n" + DispMsgs.web100rtt + " = "
						 + NDTUtils.prtdbl(_dAvgrtt) + " ms; ";
			emailText += "\n%0A" + DispMsgs.web100rtt + " = "
						 + NDTUtils.prtdbl(_dAvgrtt) + " ms; ";
						 
			statsText += DispMsgs.packetsize + " = " + _iCurrentMSS + " "
						 + DispMsgs.bytes + "; " + DispMsgs.And + " \n";
			emailText += DispMsgs.packetsize + " = " + _iCurrentMSS + " "
						 + DispMsgs.bytes + "; " + DispMsgs.And + " \n%0A";
						 
			// check packet retransmissions count and update stats panel
			if(_iPktsRetrans > 0) {
				// packet retransmissions found
				statsText += _iPktsRetrans + " " + DispMsgs.pktsRetrans;
				statsText += ", " + _iDupAcksIn + " " + DispMsgs.dupAcksIn;
				statsText += ", " + DispMsgs.And + " " + _iSACKsRcvd + " "
							 + DispMsgs.sackReceived + "\n";
				emailText += _iPktsRetrans + " " + DispMsgs.pktsRetrans;
				emailText += ", " + _iDupAcksIn + " " + DispMsgs.dupAcksIn;
				emailText += ", " + DispMsgs.And + " " + _iSACKsRcvd + " "
							 + DispMsgs.sackReceived + "\n%0A";
			
			if(_iTimeouts > 0) {
				statsText += DispMsgs.connStalled + " " + _iTimeouts
							 + " " + DispMsgs.timesPktLoss + "\n";
				emailText += DispMsgs.connStalled + " " + _iTimeouts
							 + " " + DispMsgs.timesPktLoss + "\n%0A";
			}
			
			statsText += DispMsgs.connIdle + " " + NDTUtils.prtdbl(_dWaitsec)
						 + " " + DispMsgs.seconds + " ("
						 + NDTUtils.prtdbl((_dWaitsec / _dTimesec) * NDTConstants.PERCENTAGE)
						 + DispMsgs.pctOfTime + ") \n";
			emailText += DispMsgs.connIdle + " " + NDTUtils.prtdbl(_dWaitsec)
						 + " " + DispMsgs.seconds + " ("
						 + NDTUtils.prtdbl((_dWaitsec / _dTimesec) * NDTConstants.PERCENTAGE)
						 + DispMsgs.pctOfTime + ") \n%0A";
			}
			else if(_iDupAcksIn > 0) {
				// No packet loss, but packets arrived out-of-order
				statsText += DispMsgs.noPktLoss1 + " - ";
				statsText += DispMsgs.ooOrder + " "
							 + NDTUtils.prtdbl(_dOrder * NDTConstants.PERCENTAGE)
							 + DispMsgs.pctOfTime + "\n";
				statsText += DispMsgs.noPktLoss1 + " - ";
				statsText += DispMsgs.ooOrder + " "
							 + NDTUtils.prtdbl(_dOrder * NDTConstants.PERCENTAGE)
							 + DispMsgs.pctOfTime + "\n%0A";
			}
			else {
				// No packet retransmissions found
				statsText += DispMsgs.noPktLoss2 + ".\n";
				emailText += DispMsgs.noPktLoss2 + ".\n%0A";
			}
			
			// Add Packet queueing details found during C2S throughput test to the
			// stats pane. Data is displayed as percentage
			if((_yTests & NDTConstants.TEST_C2S) == NDTConstants.TEST_C2S) {
				if(_dC2sspd > _dSc2sspd) {
					if(_dSc2sspd < (_dC2sspd * (1.0 - NDTConstants.VIEW_DIFF))) {
						statsText += DispMsgs.c2s + " " + DispMsgs.qSeen
									 + ": " + NDTUtils.prtdbl(NDTConstants.PERCENTAGE * (_dC2sspd - _dSc2sspd) / _dC2sspd)
									 + "%\n";
					}
					else {
						statsText += DispMsgs.c2s + " " + DispMsgs.qSeen
								+ ": " + NDTUtils.prtdbl(NDTConstants.PERCENTAGE * (_dC2sspd - _dSc2sspd)
										/ _dC2sspd) + "%\n";
					}
				}
			}
			
			// Add packet queueing details found during S2C throughput test to
			// the statistics pane. Data is displayed as a percentage.
			
			if ((_yTests & NDTConstants.TEST_S2C) == NDTConstants.TEST_S2C) {
				if (_dSs2cspd > _dS2cspd) {
					if (_dSs2cspd < (_dSs2cspd * (1.0 - NDTConstants.VIEW_DIFF))) {
						statsText += DispMsgs.s2c + " "
									 + DispMsgs.qSeen + ": "
									 + NDTUtils.prtdbl(NDTConstants.PERCENTAGE * (_dSs2cspd - _dS2cspd)
										/ _dSs2cspd) + "%\n";
					} 
					else {
						statsText += DispMsgs.s2c + " "
									 + DispMsgs.qSeen + ": "
									 + NDTUtils.prtdbl(NDTConstants.PERCENTAGE * (_dSs2cspd - _dS2cspd)
										/ _dSs2cspd) + "%\n";
					}
				}
			}
			
			// Add connection details to the statistics pane
			
			// Is the connection receiver limited ?
			if (_dRwintime > NDTConstants.BUFFER_LIMITED) {
				statsText += DispMsgs.thisConnIs + " "
							 + DispMsgs.limitRx + " " 
							 + NDTUtils.prtdbl(_dRwintime * NDTConstants.PERCENTAGE)
							 + DispMsgs.pctOfTime + ".\n";
				emailText += DispMsgs.thisConnIs + " "
							 + DispMsgs.limitRx + " " 
							 + NDTUtils.prtdbl(_dRwintime * NDTConstants.PERCENTAGE)
							 + DispMsgs.pctOfTime + ".\n%0A";
				pub_pctRcvrLimited = _dRwintime * NDTConstants.PERCENTAGE;
			
				if (((2 * _dRwin) / _dRttsec) < mylink) {
					// multiplying by 2 to counter round-trip
					statsText += " " + DispMsgs.incrRxBuf + " ("
								 + NDTUtils.prtdbl(_iMaxRwinRcvd / NDTConstants.KILO_BITS)
								 + " KB)" + DispMsgs.willImprove + "\n";
				}
			}
			
			// Is the connection sender limited ?
			if(_dSendtime > NDTConstants.BUFFER_LIMITED) {
				statsText += DispMsgs.thisConnIs + " " + DispMsgs.limitTx
							 + " " + NDTUtils.prtdbl(_dSendtime * NDTConstants.PERCENTAGE)
							 + DispMsgs.pctOfTime + ".\n";
				emailText += DispMsgs.thisConnIs + " " + DispMsgs.limitTx
							 + " " + NDTUtils.prtdbl(_dSendtime * NDTConstants.PERCENTAGE)
							 + DispMsgs.pctOfTime + ".\n%0A";
							 
				if((2 * (_dSwin / _dRttsec)) < mylink) {
					// dividing by 2 to counter round-trip
					statsText += " " + DispMsgs.incrRxBuf + " ("
								 + NDTUtils.prtdbl(_iSndbuf / (2 * NDTConstants.KILO_BITS))
								 + " KB)" + DispMsgs.willImprove + "\n";
				}
			}
			
			// Is the connection network limited ?
				// If the congestion windows is limited more than 0.5%
				// of the time, NDT claims that the connection is network
				// limited.
			if(_dCwndtime > 0.005) {
				statsText += DispMsgs.thisConnIs + " " + DispMsgs.limitNet
							 + " " + NDTUtils.prtdbl(_dCwndtime * NDTConstants.PERCENTAGE)
							 + DispMsgs.pctOfTime + "\n";
				emailText += DispMsgs.thisConnIs + " " + DispMsgs.limitNet
							 + " " + NDTUtils.prtdbl(_dCwndtime * NDTConstants.PERCENTAGE)
							 + DispMsgs.pctOfTime + "\n%0A";
			}
			
			// Is the loss excessive ?
				// If the link speed is less than a T3, and loss
                // is greater than 1 percent, loss is determined
                // to be excessive.
			if((_dSpd < 4) && (_dLoss > 0.01))
				statsText += DispMsgs.excLoss + "\n";
			
			// Update statistics on TCP negotiated optional Performance Settings
			statsText += "\n" + DispMsgs.web100tcpOpts + "\n";
			statsText += "RFC 2018 Selective Acknowledgement: ";
			if(_iSACKEnabled == iZero)
				statsText += DispMsgs.off + "\n";
			else
				statsText += DispMsgs.On + "\n";
				
			statsText += "RFC 896 Nagle Algorithm: ";
			if(_iNagleEnabled == iZero)
				statsText += DispMsgs.off + "\n";
			else
				statsText += DispMsgs.On + "\n";
				
			statsText += "RFC 3168 Excplicit Congestion Notification: ";
			if(_iECNEnabled == iZero)
				statsText += DispMsgs.off + "\n";
			else
				statsText += DispMsgs.On + "\n";
				
			statsText += "RFC 1323 Time Stamping: ";
			if(_iTimestampsEnabled == NDTConstants.RFC_1323_DISABLED)
				statsText += DispMsgs.off + "\n";
			else
				statsText += DispMsgs.On + "\n";
				
			statsText += "RFC 1323 Window Scaling: ";
			if(_iMaxRwinRcvd < NDTConstants.TCP_MAX_RECV_WIN_SIZE)
				_iWinScaleRcvd = 0; // Max rec window size lesser than TCP's max
									// value, so no scaling requested
									
			// According to RFC1323, Section 2.3 the max valid value of iWinScaleRcvd is 14.
			// NDT uses 20 for this, leaving for now in case it is an error value. May need
			// to be inspected again.
			
			if((_iWinScaleRcvd == 0) || (_iWinScaleRcvd > 20))
				statsText += DispMsgs.off + "\n";
			else
				statsText += DispMsgs.On + "; " + DispMsgs.scalingFactors
							 + " -  " + DispMsgs.server + "=" + _iWinScaleRcvd
							 + ", " + DispMsgs.client + "=" + _iWinScaleSent + "\n";
			
			statsText += "\n";
			// End tcp negotiated performance settings
			
			// TODO: SFW Results, More details pane & Middlebox results
		}
		
		// Routine to store integer and double values received from the server
		// into their respective variables.		
		
		/*
		
			Method to save integer values of various 'keys' from the test results
			String into corresponding integer variables.
			
			@param sSysvarParam
						String key name
						
			@param iSysvalParam
						value for this key name
						
		*/
		
		public function saveIntValues(sSysvarParam:String, iSysvalParam:int):void {
			
			// Values saved in variables : SumRTT CountRTT CurrentMSS Timeouts
			// PktsRetrans SACKsRcvd DupAcksIn MaxRwinRcvd MaxRwinSent Sndbuf
			// Rcvbuf DataPktsOut SndLimTimeRwin SndLimTimeCwnd SndLimTimeSender
			
			if(sSysvarParam == "MSSSent:")
				MSSSent = iSysvalParam;
			else if(sSysvarParam == "MSSRcvd:")
				MSSRcvd = iSysvalParam;
			else if(sSysvarParam == "ECNEnabled:")
				_iECNEnabled = iSysvalParam;
			else if(sSysvarParam == "NagleEnabled:")
				_iNagleEnabled = iSysvalParam;
			else if(sSysvarParam == "SACKEnabled:")
				_iSACKEnabled = iSysvalParam;
			else if(sSysvarParam == "TimestampsEnabled:")
				_iTimestampsEnabled = iSysvalParam;
			else if(sSysvarParam == "WinScaleRcvd:")
				_iWinScaleRcvd = iSysvalParam;
			else if(sSysvarParam == "WinScaleSent:")
				_iWinScaleSent = iSysvalParam;
			else if(sSysvarParam == "SumRTT:")
				_iSumRTT = iSysvalParam;
			else if(sSysvarParam == "CountRTT:")
				_iCountRTT = iSysvalParam;
			else if(sSysvarParam == "CurMSS:")
				_iCurrentMSS = iSysvalParam;
			else if(sSysvarParam == "Timeouts:")
				_iTimeouts = iSysvalParam;
			else if(sSysvarParam == "PktsRetrans:")
				_iPktsRetrans = iSysvalParam;
			else if(sSysvarParam == "SACKsRcvd:") {
				_iSACKsRcvd = iSysvalParam;
				pub_SACKsRcvd = _iSACKsRcvd;
			} else if(sSysvarParam == "DupAcksIn:")
				_iDupAcksIn = iSysvalParam;
			else if(sSysvarParam == "MaxRwinRcvd:") {
				_iMaxRwinRcvd = iSysvalParam;
				pub_MaxRwinRcvd = _iMaxRwinRcvd;
			} else if(sSysvarParam == "MaxRwinSent:")
				_iMaxRwinSent = iSysvalParam;
			else if(sSysvarParam == "Sndbuf:")
				_iSndbuf = iSysvalParam;
			else if(sSysvarParam == "X_Rcvbuf:")
				_iRcvbuf = iSysvalParam;
			else if(sSysvarParam == "DataPktsOut:")
				_iDataPktsOut = iSysvalParam;
			else if(sSysvarParam == "FastRetran:")
				_iFastRetran = iSysvalParam;
			else if(sSysvarParam == "AckPktsOut:")
				_iAckPktsOut = iSysvalParam;
			else if(sSysvarParam == "SmoothedRTT:")
				_iSmoothedRTT = iSysvalParam;
			else if(sSysvarParam == "CurCwnd:")
				_iCurrentCwnd = iSysvalParam;
			else if(sSysvarParam == "MaxCwnd:")
				_iMaxCwnd = iSysvalParam;
			else if(sSysvarParam == "SndLimTimeRwin:")
				_iSndLimTimeRwin = iSysvalParam;
			else if(sSysvarParam == "SndLimTimeCwnd:")
				_iSndLimTimeCwnd = iSysvalParam;
			else if(sSysvarParam == "SndLimTimeSender:")
				_iSndLimTimeSender = iSysvalParam;
			else if(sSysvarParam == "DataBytesOut:")
				_iDataBytesOut = iSysvalParam;
			else if(sSysvarParam == "AckPktsIn:")
				_iAckPktsIn = iSysvalParam;
			else if(sSysvarParam == "SndLimTransRwin:")
				_iSndLimTransRwin = iSysvalParam;
			else if(sSysvarParam == "SndLimTransCwnd:")
				_iSndLimTransCwnd = iSysvalParam;
			else if(sSysvarParam == "SndLimTransSender:")
				_iSndLimTransSender = iSysvalParam;
			else if(sSysvarParam == "MaxSsthresh:")
				_iMaxSsthresh = iSysvalParam;
			else if(sSysvarParam == "CurRTO:") {
				_iCurrentRTO = iSysvalParam;
				pub_CurRTO = _iCurrentRTO;
			} else if(sSysvarParam == "MaxRTO:")
				pub_MaxRTO = iSysvalParam;
			else if(sSysvarParam == "MinRTO:")
				pub_MinRTO = iSysvalParam;
			else if(sSysvarParam == "MinRTT:")
				pub_MinRTT = iSysvalParam;
			else if(sSysvarParam == "MaxRTT:")
				pub_MaxRTT = iSysvalParam;
			else if(sSysvarParam == "CurRwinRcvd:")
				pub_CurRwinRcvd = iSysvalParam;
			else if(sSysvarParam == "Timeouts:")
				pub_Timeouts = iSysvalParam;
			else if(sSysvarParam == "c2sData:")
				_iC2sData = iSysvalParam;
			else if(sSysvarParam == "c2sAck:")
				_iC2sAck = iSysvalParam;
			else if(sSysvarParam == "s2cData:")
				_iS2cData = iSysvalParam;
			else if(sSysvarParam == "s2cAck:")
				_iS2cAck = iSysvalParam;
			else if(sSysvarParam == "PktsOut:")
				_iPktsOut = iSysvalParam;
			else if(sSysvarParam == "mismatch:") {
				mismatch = iSysvalParam;
				pub_mismatch = mismatch;
			} else if(sSysvarParam == "congestion:") {
				congestion = iSysvalParam;
				pub_congestion = congestion;
			} else if(sSysvarParam == "bad_cable:") {
				bad_cable = iSysvalParam;
				pub_Bad_cable = bad_cable;
			} else if(sSysvarParam == "half_duplex:")
				half_duplex = iSysvalParam;
			else if(sSysvarParam == "CongestionSignals:")
				_iCongestionSignals = iSysvalParam;
			else if(sSysvarParam == "RcvWinScale:") {
				if(_iRcvWinScale > 15)
					_iRcvWinScale = 0;
				else
					_iRcvWinScale = iSysvalParam;
			}
		}
		
		/*
		
			Method to save double values of various 'keys' from the test results
			string into corresponding double variables.
			
			@param sSysvarParam
						key name String
			
			@param dSysvalParam
						value for this key name
						
		*/
		
		public function saveDblValues(sSysvarParam:String, dSysvalParam:Number):void {
			
			if(sSysvarParam == "bw:")
				_dEstimate = dSysvalParam;
			else if(sSysvarParam == "loss:") {
				_dLoss = dSysvalParam;
				pub_loss = _dLoss;
			} else if(sSysvarParam == "avgrtt:") {
				_dAvgrtt = dSysvalParam;
				pub_avgrtt = _dAvgrtt;
			} else if(sSysvarParam == "waitsec:")
				_dWaitsec = dSysvalParam;
			else if(sSysvarParam == "timesec:")
				_dTimesec = dSysvalParam;
			else if(sSysvarParam == "order:")
				_dOrder = dSysvalParam;
			else if(sSysvarParam == "rwintime:")
				_dRwintime = dSysvalParam;
			else if(sSysvarParam == "sendtime:")
				_dSendtime = dSysvalParam;
			else if(sSysvarParam == "cwndtime:") {
				_dCwndtime = dSysvalParam;
				pub_cwndtime = _dCwndtime;
			} else if(sSysvarParam == "rttsec:")
				_dRttsec = dSysvalParam;
			else if(sSysvarParam == "rwin:")
				_dRwin = dSysvalParam;
			else if(sSysvarParam == "swin:")
				_dSwin = dSysvalParam;
			else if(sSysvarParam == "cwin:")
				_dCwin = dSysvalParam;
			else if(sSysvarParam == "spd:")
				_dSpd = dSysvalParam;
			else if(sSysvarParam == "aspd:")
				_dAspd = dSysvalParam;
		}
		
		public function TestResults(_sTestResults:String, testSuite:int) {
			// constructor code
			
			_yTests = testSuite;
			
			interpretResults(_sTestResults);
		}
	}
	
}
