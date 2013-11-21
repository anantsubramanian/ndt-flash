﻿// Copyright 2013 M-Lab
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
  import flash.errors.EOFError;
  import flash.errors.IOError;
  import flash.external.ExternalInterface;
  import flash.globalization.LocaleID;
  import flash.system.Capabilities;
  import flash.system.Security;
  import flash.net.Socket;
  import flash.utils.ByteArray;
  import mx.resources.ResourceManager;

  public class NDTUtils {
    /**
     * Function that calls a JS function through the ExternalInterface class if
     * it exists by the name specified in the parameter.
     * @param {String} functionName The name of the JS function to call.
     * @param {...} args A variable length array that contains the parameters to
     *     pass to the JS function
     */
    public static function callExternalFunction(
        functionName:String, ... args):void {
      try {
        switch (args.length) {
          case 0: ExternalInterface.call(functionName);
                  break;
          case 1: ExternalInterface.call(functionName, args[0]);
                  break;
          case 2: ExternalInterface.call(functionName, args[0], args[1]);
                  break;
        }
      } catch (e:Error) {
        // Cannot call TestResults.appendErrMsg, because it calls
        // callExternalFunction.
        // TODO: Decide what to do.
      }
    }
    /**
     * Function that reads the HTML parameter tags for the SWF file and
     * initializes the variables in the SWF accordingly.
     */
    public static function initializeFromHTML(paramObject:Object):void {
      if (NDTConstants.HTML_LOCALE in paramObject) {
        Main.locale = paramObject[NDTConstants.HTML_LOCALE];
        TestResults.appendDebugMsg("Initialized locale from HTML. Locale: "
                                   + Main.locale);
      } else {
        initializeLocale();
      }
      if (NDTConstants.HTML_USERAGENT in paramObject) {
        TestResults.ndt_test_results::userAgent =
            paramObject[NDTConstants.HTML_USERAGENT];
        TestResults.appendDebugMsg("Initialized useragent from HTML. Useragent:"
                                   + TestResults.ndt_test_results::userAgent);
      }
    }

    /**
     * Initializes the locale used by the tool to match the environment of the
     * SWF.
     */
    public static function initializeLocale():void {
      var localeId:LocaleID = new LocaleID(Capabilities.language);
      var lang:String = localeId.getLanguage();
      var region:String = localeId.getRegion();
      if (lang != null && region != null
          && (ResourceManager.getInstance().getResourceBundle(
                lang + "_" + region, NDTConstants.BUNDLE_NAME) != null)) {
        // Bundle for specified locale found, change value of locale
        Main.locale = new String(lang + "_" + region);
        TestResults.appendDebugMsg(
            "Initialized locale from Flash config. Locale: " + Main.locale);
      } else {
        TestResults.appendDebugMsg(
            "Not found ResourceBundle for locale requested in Flash config. " +
            "Using default locale: " + CONFIG::defaultLocale);
      }
    }

    /**
     * Function that adds the callbacks to allow data access from, and to allow
     * data to be sent to JavaScript.
     */
    public static function addJSCallbacks():void {
      // TODO: restrict domain to the M-Lab website / server
      Security.allowDomain("*");
      try {
        ExternalInterface.addCallback(
            "getDebugOutput", TestResults.getDebugMsg);
        ExternalInterface.addCallback(
            "getAdvanced", TestResults.getResultDetails);
        ExternalInterface.addCallback(
            "getErrors", TestResults.getErrMsg);
        ExternalInterface.addCallback(
            "getNDTvar", TestResultsUtils.getNDTVariable);
      } catch (e:Error) {
        TestResults.appendErrMsg("Container doesn't support callbacks. " +
                                 "Error: " + e);
      } catch (e:SecurityError) {
        TestResults.appendErrMsg("Security error when adding callbacks: " + e);
      }
    }

    /**
     * Reads bytes from a socket into a ByteArray and returns the number of
     * successfully read bytes.
     * @param {Socket} socket Socket object to read from.
     * @param {ByteArray} bytes ByteArray where to store the read bytes.
     * @param {uint} offset Position of the ByteArray from where to start
                            storing the read values.
     * @param {uint} byteToRead Number of bytes to read.
     * @return {int} Number of successfully read bytes.
     */
    public static function readBytes(socket:Socket, bytes:ByteArray,
                                     offset:uint, bytesToRead:uint):int {
      var bytesRead:int = 0;
      while (socket.bytesAvailable && bytesRead < bytesToRead) {
        try {
          bytes[bytesRead + offset] = socket.readByte();
        } catch (e:IOError) {
          TestResults.appendErrMsg("Error reading byte from socket: " + e);
          break;
        } catch(error:EOFError) {
          // No more data to read from the socket.
          break;
        }
        bytesRead++;
      }
      return bytesRead;
    }
  }
}

