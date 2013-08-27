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
  /**
   * @author Anant Subramanian
   */
  public class Main extends Sprite {
    public function Main():void {
      if (stage) 
        init();
      else 
        addEventListener(Event.ADDED_TO_STAGE, init);
    }
    
    private function init(e:Event = null):void {
      removeEventListener(Event.ADDED_TO_STAGE, init);
      // entry point
      stage.showDefaultContextMenu = false;
      var Frame:MainFrame = new MainFrame(stage.stageWidth,
                                          stage.stageHeight,
                                          NDTConstants.HOST_NAME,
                                          true);
      Frame.x = Frame.y = 0;
      stage.addChild(Frame);
    }
  }
}
