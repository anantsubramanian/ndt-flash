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
  import flash.display.Graphics;
  import flash.display.MovieClip;
  import flash.text.TextField;
  import flash.text.*;
  import flash.display.Sprite;
  import flash.events.MouseEvent;
  import flash.ui.Mouse;
  import flash.events.Event;
  import flash.net.*;
  import flash.display.DisplayObjectContainer;
  import flash.display.DisplayObject;
  import flash.filters.BlurFilter;
  import spark.effects.*;
  
  /**
   * Class that creates a Flash GUI for the tool. This is optional and
   * can be disabled in the 'Main' class.
   */
  public class GUI extends Sprite{    
    // variables declaration section
    private var stagewidth:int;
    private var stageheight:int;
    private var parentObject:MainFrame;
    
    [Embed(source="../assets/mlab-logo.png")]
    private var mLabLogo:Class;
    private var Mlab_logo:DisplayObject;
    private var Mlab_url:String = "http://www.measurementlab.net";
    private var Url_request:URLRequest;
    private var Start_button:MovieClip;
      [Embed(source="../assets/Start_hover.png")]
      private var startHover:Class;
      private var Hover:DisplayObject;
      [Embed(source="../assets/Start_nohover.png")]
      private var startNoHover:Class;
      private var No_hover:DisplayObject;
    
    private var Learn_text_container:Sprite;
      [Embed(source="../assets/Learn_nohover.png")]
      private var learnNoHover:Class;
      private var Learn_noHover:DisplayObject;
      [Embed(source="../assets/Learn_hover.png")]
      private var learnHover:Class;
      private var Learn_Hover:DisplayObject;
    private var About_text_format:TextFormat;   
    private var About_ndt_text:TextField;
    private static var consoleText:TextField;
    
    // results display variables
    private var resultsField:TextField;
    private var resultsTextFormat:TextFormat;
    private var resultsRect:MovieClip;
    [Embed(source="../assets/Result_button.png")]
    private var resultButton:Class;
    private var buttonDisplayObject:DisplayObject;
    [Embed(source="../assets/Result_overbutton.png")]
    private var overResultButton:Class;
    private var overButtonObject:DisplayObject;
    private var statsButton:MovieClip;
    private var mainResult:MovieClip;
    private var errorsButton:MovieClip;
    private var diagnosticsButton:MovieClip;
    [Embed(source="../assets/Scroll_up.png")]
    private var ScrollUp:Class;
    private var scrollUpObject:DisplayObject;
    private var scrollUp:MovieClip;
    [Embed(source="../assets/Scroll_down.png")]
    private var ScrollDown:Class;
    private var scrollDownObject:DisplayObject;
    private var scrollDown:MovieClip;
    private var blur:BlurFilter;
    
    // Tween variables
    private var fadeEffect:Fade;
    
    // event listener functions
    private function rollOverLearn(e:MouseEvent):void {
      if(Learn_text_container.getChildAt(0))
      {
        Learn_text_container.removeChildAt(0);
      }
      Learn_text_container.addChild(Learn_Hover);
    }
    
    private function rollOutLearn(e:MouseEvent):void {
      if(Learn_text_container.getChildAt(0))
      {
        Learn_text_container.removeChildAt(0);
      }
      Learn_text_container.addChild(Learn_noHover);
    }
    
    private function clickLearnText(e:MouseEvent):void {
      try {
        navigateToURL(Url_request);
      } catch (error:Error) {
        trace(error);
      }
    }
    
    private function rollOverStart(e:MouseEvent):void {
      if (Start_button.getChildAt(0)) {
         Start_button.removeChildAt(0);
      }
      Start_button.addChild(Hover);   
    }
    
    private function rollOutStart(e:MouseEvent):void {
      if (Start_button.getChildAt(0)) {
         Start_button.removeChildAt(0);
      }
      Start_button.addChild(No_hover);
    }
    
    private function clickStart(e:MouseEvent):void {
      hideInitialScreen();
      consoleText = new TextField();
      consoleText.text = "\n\n";
      consoleText.wordWrap = true;
      consoleText.width = stagewidth;
      consoleText.height = stageheight;
      this.addChild(consoleText);
      // Start tests
      parentObject.dottcp();
    }
    
    private function rollOverResult(e:MouseEvent):void {
      if(!(e.target.getChildAt(0) is TextField))
        e.target.removeChildAt(0);
      overButtonObject = new overResultButton();
      overButtonObject.width *= 0.25;
      overButtonObject.height *= 0.25; 
      e.target.addChildAt(overButtonObject,0);
    }
    
    private function rollOutResult(e:MouseEvent):void {
      if(!(e.target.getChildAt(0) is TextField))
        e.target.removeChildAt(0);
      buttonDisplayObject = new resultButton();
      buttonDisplayObject.width *= 0.25;
      buttonDisplayObject.height *= 0.25; 
      e.target.addChildAt(buttonDisplayObject,0);
    }
    
    private function clickMainResult(e:MouseEvent):void {
      fadeEffect.play([resultsField], true);
      resultsField.text = TestResults.getConsoleOutput();
      resultsField.scrollV = 0;
      fadeEffect.end();
      fadeEffect.play([resultsField]);
    }
    private function clickStats(e:MouseEvent):void {
      fadeEffect.play([resultsField], true);
      resultsField.text = TestResults.getStatsText();
      resultsField.scrollV = 0;
      fadeEffect.end();
      fadeEffect.play([resultsField]);
    }
    private function clickDiagnostics(e:MouseEvent):void {
      fadeEffect.play([resultsField], true);
      resultsField.text = TestResults.getDiagnosisText();
      resultsField.scrollV = 0;
      fadeEffect.end();
      fadeEffect.play([resultsField]);
    }
    private function clickErrors(e:MouseEvent):void {
      fadeEffect.play([resultsField], true);
      resultsField.text = TestResults.getErrMsg();
      resultsField.scrollV = 0;
      fadeEffect.end();
      fadeEffect.play([resultsField]);
    }
    private function vScrollDown(e:MouseEvent):void {
      resultsField.scrollV++;
    }
    private function vScrollUp(e:MouseEvent):void {
      resultsField.scrollV--;
    }
    // end event-listener functions
    
    // animation functions 
    private function startUpAnimation():void {
      Mlab_logo.alpha = 0;
      Start_button.alpha = 0;
      About_ndt_text.alpha = 0;
      Learn_text_container.alpha = 0;
      fadeEffect.play([Mlab_logo, About_ndt_text, 
                      Learn_text_container, Start_button]);
    }
    
    private function hideInitialScreen():void {
      fadeEffect.end();
      fadeEffect.play([Mlab_logo, About_ndt_text, 
                      Learn_text_container, Start_button], true);
            
      if (this.getChildByName("Mlab_logo")) {
        this.removeChild(Mlab_logo);   
      }
      if (this.getChildByName("About_ndt_text")) {
        this.removeChild(About_ndt_text);   
      }
      if (this.getChildByName("Learn_text_container")) {
        this.removeChild(Learn_text_container);   
      }
      if (this.getChildByName("Start_button")) {
        this.removeChild(Start_button);   
      }
      
      // removing initial event listeners
      Learn_text_container.removeEventListener(MouseEvent.ROLL_OVER,
                                               rollOverLearn);
      Learn_text_container.removeEventListener(MouseEvent.ROLL_OUT, 
                                               rollOutLearn);
      Learn_text_container.removeEventListener(MouseEvent.CLICK, 
                                               clickLearnText);
      Start_button.removeEventListener(MouseEvent.ROLL_OVER, rollOverStart);
      Start_button.removeEventListener(MouseEvent.ROLL_OUT, rollOutStart);
      Start_button.removeEventListener(MouseEvent.CLICK, clickStart);
      Learn_text_container.buttonMode = false;
      Start_button.buttonMode = false;
    }
    
    /**
     * Function that adds text to the TextField that is displaying
     * the console output while the tests are running.
     * @param {String} sParam The text to be added to the TextField
     */
    public static function addConsoleOutput(sParam:String):void {
      consoleText.appendText(sParam);
    }
    
    /**
     * Function that creates and populates the Results screen
     */
    public function displayResults():void {
      fadeEffect.play([consoleText], true);
      while (this.numChildren) {
        this.removeChildAt(0);
      }
      resultsRect = new MovieClip();
      resultsRect.graphics.beginFill(0);
      resultsRect.x = 0.25 * stagewidth;
      resultsRect.graphics.drawRect(0, 0, 0.75*stagewidth, stageheight);
      resultsRect.graphics.endFill();
      resultsRect.alpha = 0.125;
      resultsRect.filters = [blur];
      
      resultsTextFormat = new TextFormat();
      resultsTextFormat.size = 14;
      resultsTextFormat.color = 0xFFFFFF;
      
      resultsField = new TextField();
      resultsField.defaultTextFormat = resultsTextFormat;
      resultsField.x = (0.275*stagewidth);
      resultsField.y = 0.05 * stageheight;
      resultsField.width = (0.725*stagewidth);
      resultsField.height = 0.90*stageheight;
      resultsField.wordWrap = true;
      this.addChild(resultsRect);
      this.addChild(resultsField);
      if (TestResults.get_bFailed())
        resultsField.appendText("Test Failed! View errors for more details.\n");
      else
        resultsField.appendText("\n" + TestResults.getConsoleOutput() + "\n");  
      var tempText:TextField = new TextField();
      resultsTextFormat.size = 18;
      resultsTextFormat.align = TextFormatAlign.CENTER;
      tempText.defaultTextFormat = resultsTextFormat;
      tempText.text = "Results";
      
      var diff:Number = stageheight / 3;
      
      // Results Button
      buttonDisplayObject = new resultButton();
      buttonDisplayObject.width *= 0.25;
      buttonDisplayObject.height *= 0.25;
      tempText.width = 0.75 * buttonDisplayObject.width;
      tempText.height = 0.50 * buttonDisplayObject.height;
      mainResult = new MovieClip();
      mainResult.addChild(buttonDisplayObject);
      mainResult.mouseChildren = false;
      tempText.x = buttonDisplayObject.width/2 - tempText.width/2;
      tempText.y = buttonDisplayObject.height/2 - tempText.height/2;
      mainResult.addChild(tempText);
      
      // Statistics Button
      tempText = new TextField();
      buttonDisplayObject = new resultButton();
      buttonDisplayObject.width *= 0.25;
      buttonDisplayObject.height *= 0.25;
      tempText.defaultTextFormat = resultsTextFormat;
      tempText.text = "Statistics";
      tempText.width = 0.75 * buttonDisplayObject.width;
      tempText.height = 0.50 * buttonDisplayObject.height;
      statsButton = new MovieClip();
      statsButton.addChild(buttonDisplayObject);
      statsButton.mouseChildren = false;
      tempText.x = buttonDisplayObject.width/2 - tempText.width/2;
      tempText.y = buttonDisplayObject.height/2 - tempText.height/2;
      statsButton.addChild(tempText);
      
      // Diagnostics Button
      tempText = new TextField();
      buttonDisplayObject = new resultButton();
      buttonDisplayObject.width *= 0.25;
      buttonDisplayObject.height *= 0.25;
      tempText.defaultTextFormat = resultsTextFormat;
      tempText.text = "Diagnostics";
      tempText.width = 0.75 * buttonDisplayObject.width;
      tempText.height = 0.50 * buttonDisplayObject.height;
      diagnosticsButton = new MovieClip();
      diagnosticsButton.addChild(buttonDisplayObject);
      diagnosticsButton.mouseChildren = false;
      tempText.x = buttonDisplayObject.width/2 - tempText.width/2;
      tempText.y = buttonDisplayObject.height/2 - tempText.height/2;
      diagnosticsButton.addChild(tempText);
      
      // Errors Button
      if (TestResults.getErrMsg() != "") {
        tempText = new TextField();
        buttonDisplayObject = new resultButton();
        buttonDisplayObject.width *= 0.25;
        buttonDisplayObject.height *= 0.25;
        tempText.defaultTextFormat = resultsTextFormat;
        tempText.text = "Errors";
        tempText.width = 0.75 * buttonDisplayObject.width;
        tempText.height = 0.50 * buttonDisplayObject.height;
        errorsButton = new MovieClip();
        errorsButton.addChild(buttonDisplayObject);
        errorsButton.mouseChildren = false;
        tempText.x = buttonDisplayObject.width/2 - tempText.width/2;
        tempText.y = buttonDisplayObject.height/2 - tempText.height/2;
        errorsButton.addChild(tempText);
        diff = stageheight / 4;
      }
      
      scrollUpObject = new ScrollUp();
      scrollUp = new MovieClip();
      scrollUp.addChild(scrollUpObject);
      scrollUp.buttonMode = true;
      scrollDownObject = new ScrollDown();
      scrollDown = new MovieClip();
      scrollDown.addChild(scrollDownObject);
      scrollDown.buttonMode = true;
      scrollUp.width *= 0.25;
      scrollUp.height *= 0.25;  
      scrollUp.x = stagewidth - scrollUp.width;
      scrollUp.y = 0;    
      scrollDown.width *= 0.25;
      scrollDown.height *= 0.25;
      scrollDown.x = stagewidth - scrollDown.width;
      scrollDown.y = stageheight - scrollDown.height;
            
      mainResult.y = 0.05 * stageheight;
      statsButton.y = mainResult.y + diff;
      diagnosticsButton.y = statsButton.y + diff;
      if (errorsButton)
        errorsButton.y = diagnosticsButton.y  + diff;
      mainResult.buttonMode = true;
      statsButton.buttonMode = true;
      diagnosticsButton.buttonMode = true;
      if (errorsButton)
        errorsButton.buttonMode = true;  
      
      this.addChild(mainResult);
      this.addChild(statsButton);
      this.addChild(diagnosticsButton);
      if (errorsButton)
        this.addChild(errorsButton);
      this.addChild(scrollUp);
      this.addChild(scrollDown);
      
      scrollUp.addEventListener(MouseEvent.CLICK, vScrollUp);
      scrollDown.addEventListener(MouseEvent.CLICK, vScrollDown);
      
      mainResult.addEventListener(MouseEvent.ROLL_OVER, rollOverResult);
      statsButton.addEventListener(MouseEvent.ROLL_OVER, rollOverResult);
      diagnosticsButton.addEventListener(MouseEvent.ROLL_OVER, rollOverResult);
      if (errorsButton)
        errorsButton.addEventListener(MouseEvent.ROLL_OVER, rollOverResult);
      
      mainResult.addEventListener(MouseEvent.ROLL_OUT, rollOutResult);
      statsButton.addEventListener(MouseEvent.ROLL_OUT, rollOutResult);
      diagnosticsButton.addEventListener(MouseEvent.ROLL_OUT, rollOutResult);
      if (errorsButton)
        errorsButton.addEventListener(MouseEvent.ROLL_OUT, rollOutResult);
        
      mainResult.addEventListener(MouseEvent.CLICK, clickMainResult);
      statsButton.addEventListener(MouseEvent.CLICK, clickStats);
      diagnosticsButton.addEventListener(MouseEvent.CLICK, clickDiagnostics);
      if (errorsButton)
        errorsButton.addEventListener(MouseEvent.CLICK, clickErrors);
    }
    
    /**
       Constructor of the GUI class. Initializes the objects and positions
       them on the screen using a relative layout.
       @param {int} stageW Width of the stage to which the GUI is added
       @param {int} stageH Height of the stage
       @param {MainFrame} Parent The class in which the object of GUI
          was created.
     */
    public function GUI(stageW:int, stageH:int, Parent:MainFrame) {
      stagewidth  = stageW;
      stageheight = stageH;
      parentObject = Parent;
      
      // variables initialization
      Mlab_logo = new mLabLogo();
      Url_request = new URLRequest(Mlab_url);
      Start_button = new MovieClip();
        Hover = new startHover();
        Hover.width *= 0.40;
        Hover.height *= 0.40;
        Hover.x -= Hover.width / 2;
        Hover.y -= Hover.height / 2;
        No_hover = new startNoHover();
        No_hover.width *= 0.40;
        No_hover.height *= 0.40;
        No_hover.x -= No_hover.width / 2;
        No_hover.y -= No_hover.height / 2;
        Start_button.addChild(No_hover); 
        Start_button.buttonMode = true;
      About_text_format = new TextFormat();
        About_text_format.size = 17;
        About_text_format.align = TextFormatAlign.CENTER;
        About_text_format.color = 0x000000;  
      Learn_noHover = new learnNoHover();
        Learn_noHover.width *= 0.30;
        Learn_noHover.height *= 0.30;
      Learn_Hover = new learnHover();
        Learn_Hover.width *= 0.30;
        Learn_Hover.height *= 0.30;
      About_ndt_text = new TextField();
      About_ndt_text.defaultTextFormat = About_text_format;
      About_ndt_text.width = 0.75 * stagewidth;
      About_ndt_text.height = 0.40 * stageheight;
      About_ndt_text.wordWrap = true;
      About_ndt_text.selectable = false;
      About_ndt_text.text = "Network Diagnostic Tool (NDT) provides a "
                            + "sophisticated speed and diagnostic test. An NDT "
                            + "test reports more than just the upload and "
                            + "download speeds — it also attempts to determine "
                            + "what, if any, problems limited these speeds, "
                            + "differentiating between computer configuration "
                            + "and network infrastructure problems. While the "
                            + "diagnostic messages are most useful for expert "
                            + "users, they can also help novice users by "
                            + "allowing them to provide detailed trouble "
                            + "reports to their network administrator.";
                  
      Learn_text_container = new Sprite();
        Learn_text_container.addChild(Learn_noHover);
        Learn_text_container.buttonMode = true;
        Learn_text_container.mouseChildren = false;
      blur = new BlurFilter(16.0, 0, 1);
      // positioning objects on stage using a relative layout
      Mlab_logo.x = (stagewidth/2) - (Mlab_logo.width/2);
      Mlab_logo.y = 0.125*Mlab_logo.height;
      About_ndt_text.x = 0.125 * stagewidth;
      About_ndt_text.y = (Mlab_logo.y) + 1.125*Mlab_logo.height;
      Learn_text_container.x = (stagewidth/2) - (Learn_text_container.width/2);
      Learn_text_container.y = About_ndt_text.y + About_ndt_text.height;
      Start_button.x = (stagewidth / 2);
      Start_button.y = Learn_text_container.y + 2.25*Learn_text_container.height;
            
      // adding objects to the GUI Container
      this.addChild(Mlab_logo);
      this.addChild(Start_button);
      this.addChild(Learn_text_container);
      this.addChild(About_ndt_text);
      
      // Initialize tween variables
      fadeEffect = new Fade();
      fadeEffect.alphaFrom = 0.0;
      fadeEffect.alphaTo = 1.0;
      fadeEffect.duration = 500;
      startUpAnimation();
      
      // Initial Event Listeners
      Learn_text_container.addEventListener(MouseEvent.ROLL_OVER, rollOverLearn);
      Learn_text_container.addEventListener(MouseEvent.ROLL_OUT, rollOutLearn);
      Learn_text_container.addEventListener(MouseEvent.CLICK, clickLearnText);
      Start_button.addEventListener(MouseEvent.ROLL_OVER, rollOverStart);
      Start_button.addEventListener(MouseEvent.ROLL_OUT, rollOutStart);
      Start_button.addEventListener(MouseEvent.CLICK, clickStart);
    }
  }
}

