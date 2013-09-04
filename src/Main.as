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

package {
  import flash.display.Sprite;
  import flash.events.Event;
  import flash.external.ExternalInterface;
  import flash.system.Capabilities;
  import flash.globalization.LocaleID;
  import mx.resources.ResourceBundle;
  /**
   * @author Anant Subramanian
   */
  [ResourceBundle("DisplayMessages")]
  public class Main extends Sprite {
    
    public static var guiEnabled:Boolean = false;
    public static var locale:String = CONFIG::defaultLocale;
    
    public function Main():void {
      if (stage) 
        init();
      else 
        addEventListener(Event.ADDED_TO_STAGE, init);
    }
    
    /**
     * Function that is called once the stage is initialized and an instance
     * of this class has been added to it. Sets the locale value according to
     * the SWF environment and creates an object of MainFrame class to start
     * the testing process.
     * @param {Event} The event that caused the function to be called.
     */
    private function init(e:Event = null):void {
      removeEventListener(Event.ADDED_TO_STAGE, init);
      // entry point
      CONFIG::guiEnabled {
        // if guiEnabled set to false while compiling skip GUI and start tests
        Main.guiEnabled = true;
      }
      var lId:LocaleID = new LocaleID(Capabilities.language);
      initializeLocale(lId.getLanguage(), lId.getRegion());
      stage.showDefaultContextMenu = false;
      
      var Frame:MainFrame = new MainFrame(stage.stageWidth,
                                          stage.stageHeight,
                                          NDTConstants.HOST_NAME);
      Frame.x = Frame.y = 0;
      stage.addChild(Frame);
    }
    
    /**
     * Initializes the locale variable of this class to match the environment
     * of the SWF.
     * @param {String} lang The language part of the locale
     * @param {String} region The region part of the locale
     */ 
    private function initializeLocale(lang:String, region:String):void {
      if (lang == null || region == null)
        return;
      if (NDTConstants.RMANAGER.getString(NDTConstants.BUNDLE_NAME,
                                         "test", null, lang+"_"+region) != null) {
        // Bundle for specified locale found, change value of locale
        locale = new String(lang + "_" + region);
        trace("Using locale " + locale);
      } else {
        trace("Error: ResourceBundle for provided locale not found.");
        trace("Using default " + CONFIG::defaultLocale);
      }
    }
  }
}
