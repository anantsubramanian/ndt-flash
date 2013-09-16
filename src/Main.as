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
  import flash.globalization.LocaleID;
  import flash.system.Capabilities;
  import mx.resources.ResourceBundle;
  import mx.resources.ResourceManager;
  /**
   * @author Anant Subramanian
   */

  [ResourceBundle("DisplayMessages")]
  public class Main extends Sprite {
    public static var guiEnabled:Boolean = CONFIG::guiEnabled;
    public static var locale:String = CONFIG::defaultLocale;
    public static var gui:GUI;

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
      initializeLocale();
      var frame:MainFrame = new MainFrame(NDTConstants.SERVER_HOSTNAME);

      stage.showDefaultContextMenu = false;
      if (guiEnabled) {
        gui = new GUI(stage.stageWidth, stage.stageHeight, frame);
        this.addChild(gui);
      } else {
        // If guiEnabled compiler flag set to false start tests immediately
        frame.dottcp();
      }
    }
    
    /**
     * Initializes the locale variable of this class to match the environment
     * of the SWF.
     */ 
    private function initializeLocale():void {
      var localeId:LocaleID = new LocaleID(Capabilities.language);
      var lang:String = localeId.getLanguage();
      var region:String = localeId.getRegion();
      if (lang != null && region != null
          && (ResourceManager.getInstance().getResourceBundle(
                lang + "_" + region, NDTConstants.BUNDLE_NAME) != null)) {
        // Bundle for specified locale found, change value of locale
        locale = new String(lang + "_" + region);
        trace("Using locale " + locale);
      } else {
        trace("Error: ResourceBundle for provided locale not found.");
        trace("Using default locale " + CONFIG::defaultLocale);
      }
    }
  }
}
