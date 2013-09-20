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
    private var parentObject:NDTPController;

    [Embed(source="../assets/mlab-logo.png")]
    private var mLabLogo:Class;
    private var Mlab_logo:DisplayObject;
    private var Mlab_url:String = "http://www.measurementlab.net";
    private var Url_request:URLRequest;
    [Embed(source="../assets/hover.png")]
    private var hover:Class;
    [Embed(source="../assets/noHover.png")]
    private var noHover:Class;
    private var Start_button:MovieClip;
      private var hoverButton:DisplayObject;
      private var noHoverButton:DisplayObject;
    private var Learn_text_container:Sprite;
    private var Learn_more_text:TextField;
    private var Learn_more_format:TextFormat;
    private var About_text_format:TextFormat;
    private var About_ndt_text:TextField;
    private static var consoleText:TextField;

    // results display variables
    private var resultsField:TextField;
    private var resultsTextFormat:TextFormat;
    private var resultsRect:MovieClip;
    private var statsButton:MovieClip;
    private var mainResult:MovieClip;
    private var errorsButton:MovieClip;
    private var diagnosticsButton:MovieClip;
    private var scrollBar:Sprite;
    private var scrollBlock:Sprite;
    [Embed(source="../assets/scrollUp.png")]
    private var scrollUp:Class;
    [Embed(source="../assets/scrollDown.png")]
    private var scrollDown:Class;
    private var scrollUpButton:MovieClip;
    private var scrollDownButton:MovieClip;
    private var blur:BlurFilter;

    // Tween variables
    private var fadeEffect:Fade;

    // event listener functions
    private function clickLearnText(e:MouseEvent):void {
      try {
        navigateToURL(Url_request);
      } catch (error:Error) {
        TestResults.appendErrMsg(error.toString());
      }
    }

    private function rollOverStart(e:MouseEvent):void {
      if (!(Start_button.getChildAt(0) is TextField)) {
         Start_button.removeChildAt(0);
      }
      Start_button.addChildAt(hoverButton, 0);
    }

    private function rollOutStart(e:MouseEvent):void {
      if (!(Start_button.getChildAt(0) is TextField)) {
         Start_button.removeChildAt(0);
      }
      Start_button.addChildAt(noHoverButton, 0);
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
      parentObject.startNDTTest();
    }

    private function rollOverResult(e:MouseEvent):void {
      if(!(e.target.getChildAt(0) is TextField))
        e.target.removeChildAt(0);
      hoverButton = new hover();
      hoverButton.width *= 0.25;
      hoverButton.height *= 0.25;
      e.target.addChildAt(hoverButton,0);
    }

    private function rollOutResult(e:MouseEvent):void {
      if(!(e.target.getChildAt(0) is TextField))
        e.target.removeChildAt(0);
      noHoverButton = new noHover();
      noHoverButton.width *= 0.25;
      noHoverButton.height *= 0.25;
      e.target.addChildAt(noHoverButton,0);
    }

    private function clickMainResult(e:MouseEvent):void {
      fadeEffect.play([resultsField, scrollBlock], true);
      resultsField.text = TestResults.getDebugMsg();
      resultsField.scrollV = 0;
      fadeEffect.end();
      scrollBlock.height = scrollBar.height / resultsField.maxScrollV;
      scrollBlock.y = 0;
      fadeEffect.play([resultsField, scrollBlock]);
    }
    private function clickStats(e:MouseEvent):void {
      fadeEffect.play([resultsField, scrollBlock], true);
      resultsField.text = TestResults.getDebugMsg();
      resultsField.scrollV = 0;
      fadeEffect.end();
      scrollBlock.height = scrollBar.height / resultsField.maxScrollV;
      scrollBlock.y = 0;
      fadeEffect.play([resultsField, scrollBlock]);
    }
    private function clickDiagnostics(e:MouseEvent):void {
      fadeEffect.play([resultsField, scrollBlock], true);
      resultsField.text = TestResults.getDiagnosisText();
      resultsField.scrollV = 0;
      fadeEffect.end();
      scrollBlock.height = 2 * scrollBar.height / resultsField.maxScrollV;
      scrollBlock.y = 0;
      fadeEffect.play([resultsField, scrollBlock]);
    }
    private function clickErrors(e:MouseEvent):void {
      fadeEffect.play([resultsField], true);
      resultsField.text = TestResults.getErrMsg();
      resultsField.scrollV = 0;
      fadeEffect.end();
      scrollBlock.height = scrollBar.height / resultsField.maxScrollV;
      scrollBlock.y = 0;
      fadeEffect.play([resultsField, scrollBlock]);
    }
    private function scrollBarMove(e:MouseEvent):void {
      var scrollTo:int =
        int((Number(resultsField.maxScrollV) / scrollBar.height) * mouseY);
      if (resultsField.scrollV != scrollTo)
      {
        resultsField.scrollV = scrollTo;
        scrollBlock.y =
          (Number(scrollBar.height) / resultsField.maxScrollV) * scrollTo;
      }
    }
    private function moveScrollBlock(e:MouseEvent):void {
      scrollBar.removeEventListener(MouseEvent.CLICK, scrollBarMove);
      scrollBar.addEventListener(MouseEvent.MOUSE_MOVE, startDragging);
    }
    private function startDragging(e:MouseEvent):void {
      scrollBlock.y = mouseY - scrollBlock.height / 2;
    }
    private function stopScrollBlock(e:MouseEvent):void {
      scrollBar.removeEventListener(MouseEvent.MOUSE_MOVE, startDragging);
      var scrollTo:int =
        int((Number(resultsField.maxScrollV) / scrollBar.height) * mouseY);
      if (resultsField.scrollV != scrollTo)
      {
        resultsField.scrollV = scrollTo;
        scrollBlock.y =
          (Number(scrollBar.height) / resultsField.maxScrollV) * scrollTo;
      }
      else
        scrollBlock.y =
          (Number(scrollBar.height) / resultsField.maxScrollV) * resultsField.scrollV;
      scrollBar.addEventListener(MouseEvent.CLICK, scrollBarMove);
    }
    private function scrollResults(e:MouseEvent):void {
      if (resultsField.scrollV == resultsField.maxScrollV)
      {
        scrollBlock.y = scrollBar.height - scrollBlock.height;
        return;
      }
      else if (resultsField.scrollV == 1)
      {
        scrollBlock.y = 0;
        return;
      }
      else if (resultsField.scrollV > resultsField.maxScrollV
          || resultsField.scrollV < 0)
        return;
      scrollBlock.y =
          (Number(scrollBar.height) / resultsField.maxScrollV) * resultsField.scrollV;
    }
    private function scrollResultsUp(e:MouseEvent):void {
      resultsField.scrollV--;
      scrollResults(e);
    }
    private function scrollResultsDown(e:MouseEvent):void {
      resultsField.scrollV++;
      scrollResults(e);
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
      resultsTextFormat.font = "Verdana";
      resultsTextFormat.size = 12;
      resultsTextFormat.color = 0x000000;

      resultsField = new TextField();
      resultsField.defaultTextFormat = resultsTextFormat;
      resultsField.x = (0.275*stagewidth);
      resultsField.y = 0.05 * stageheight;
      resultsField.width = (0.725*stagewidth);
      resultsField.height = 0.90*stageheight;
      resultsField.wordWrap = true;
      this.addChild(resultsRect);
      this.addChild(resultsField);
      if (TestResults.ndt_test_results::ndtTestFailed)
        resultsField.appendText("Test Failed! View errors for more details.\n");
      else
        resultsField.appendText("\n" + TestResults.getDebugMsg() + "\n");

      var tempText:TextField = new TextField();
      resultsTextFormat.size = 18;
      resultsTextFormat.font = "Comic Sans";
      resultsTextFormat.bold = true;
      resultsTextFormat.color = 0xFFFFFF;
      resultsTextFormat.align = TextFormatAlign.CENTER;
      tempText.defaultTextFormat = resultsTextFormat;
      tempText.text = "Results";

      var diff:Number = stageheight / 3;

      // Results Button
      noHoverButton = new noHover();
      noHoverButton.width *= 0.25;
      noHoverButton.height *= 0.25;
      tempText.width = 0.75 * noHoverButton.width;
      tempText.height = 0.50 * noHoverButton.height;
      mainResult = new MovieClip();
      mainResult.addChild(noHoverButton);
      mainResult.mouseChildren = false;
      tempText.x = noHoverButton.width/2 - tempText.width/2;
      tempText.y = noHoverButton.height/2 - tempText.height/2;
      mainResult.addChild(tempText);

      // Details Button
      noHoverButton = new noHover();
      noHoverButton.width *= 0.25;
      noHoverButton.height *= 0.25;
      tempText = new TextField();
      tempText.defaultTextFormat = resultsTextFormat;
      tempText.text = "Details";
      tempText.width = 0.75 * noHoverButton.width;
      tempText.height = 0.50 * noHoverButton.height;
      statsButton = new MovieClip();
      statsButton.addChild(noHoverButton);
      statsButton.mouseChildren = false;
      tempText.x = noHoverButton.width/2 - tempText.width/2;
      tempText.y = noHoverButton.height/2 - tempText.height/2;
      statsButton.addChild(tempText);

      // Advanced Button
      noHoverButton = new noHover();
      noHoverButton.width *= 0.25;
      noHoverButton.height *= 0.25;
      tempText = new TextField();
      tempText.defaultTextFormat = resultsTextFormat;
      tempText.text = "Advanced";
      tempText.width = 0.75 * noHoverButton.width;
      tempText.height = 0.50 * noHoverButton.height;
      diagnosticsButton = new MovieClip();
      diagnosticsButton.addChild(noHoverButton);
      diagnosticsButton.mouseChildren = false;
      tempText.x = noHoverButton.width/2 - tempText.width/2;
      tempText.y = noHoverButton.height/2 - tempText.height/2;
      diagnosticsButton.addChild(tempText);

      // Errors Button
      if (TestResults.getErrMsg() != "") {
        tempText = new TextField();
        noHoverButton = new noHover();
        noHoverButton.width *= 0.25;
        noHoverButton.height *= 0.25;
        tempText.defaultTextFormat = resultsTextFormat;
        tempText.text = "Errors";
        tempText.width = 0.75 * noHoverButton.width;
        tempText.height = 0.50 * noHoverButton.height;
        errorsButton = new MovieClip();
        errorsButton.addChild(noHoverButton);
        errorsButton.mouseChildren = false;
        tempText.x = noHoverButton.width/2 - tempText.width/2;
        tempText.y = noHoverButton.height/2 - tempText.height/2;
        errorsButton.addChild(tempText);
        diff = stageheight / 4;
      }

      // create scrollbar
      scrollBar = new Sprite();
      scrollBar.graphics.beginFill(0x808080, 0.35);
      scrollBar.graphics.drawRect(0, 0, 8, stageheight - 30);
      scrollBar.graphics.endFill();
      scrollBar.x = stagewidth - 8;
      scrollBar.y = 15;
      scrollBlock = new Sprite();
      scrollBlock.graphics.beginFill(0xC0C0C0, 0.50);
      scrollBlock.graphics.drawRect(1, 0, 6, scrollBar.height/resultsField.maxScrollV);
      scrollBlock.graphics.endFill();

      scrollUpButton = new MovieClip();
      scrollDownButton = new MovieClip();
      scrollUpButton.x = stagewidth - 8;
      scrollUp.y = 0;
      scrollUpButton.addChild(new scrollUp());
      scrollUpButton.width = 8;
      scrollUpButton.height = 15;
      scrollUpButton.buttonMode = true;
      scrollDownButton.x = stagewidth - 8;
      scrollDownButton.y = stageheight - 15;
      scrollDownButton.addChild(new scrollDown());
      scrollDownButton.width = 8;
      scrollDownButton.height = 15;
      scrollDownButton.buttonMode = true;

      scrollBar.addChild(scrollBlock);
      this.addChild(scrollUpButton);
      this.addChild(scrollDownButton);
      scrollBar.mouseChildren = true;
      scrollBar.buttonMode = true;
      scrollBar.addEventListener(MouseEvent.CLICK, scrollBarMove);
      scrollBlock.addEventListener(MouseEvent.MOUSE_DOWN, moveScrollBlock);
      scrollBlock.addEventListener(MouseEvent.MOUSE_UP, stopScrollBlock);
      scrollUpButton.addEventListener(MouseEvent.CLICK, scrollResultsUp);
      scrollDownButton.addEventListener(MouseEvent.CLICK, scrollResultsDown);
      resultsField.addEventListener(MouseEvent.MOUSE_WHEEL, scrollResults);

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
      this.addChild(scrollBar);

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
       @param {NDTPController} Parent The class in which the object of GUI
          was created.
     */
    public function GUI(stageW:int, stageH:int, Parent:NDTPController) {
      stagewidth  = stageW;
      stageheight = stageH;
      parentObject = Parent;

      // variables initialization
      Mlab_logo = new mLabLogo();
      Url_request = new URLRequest(Mlab_url);
      Start_button = new MovieClip();
        hoverButton = new hover();
        hoverButton.width *= 0.40;
        hoverButton.height *= 0.40;
        hoverButton.x -= hoverButton.width / 2;
        hoverButton.y -= hoverButton.height / 2;
        noHoverButton = new noHover();
        noHoverButton.width *= 0.40;
        noHoverButton.height *= 0.40;
        noHoverButton.x -= noHoverButton.width / 2;
        noHoverButton.y -= noHoverButton.height / 2;
        var startText:TextField = new TextField();
        var startTextFormat:TextFormat = new TextFormat();
        startTextFormat.size = 26;
        startTextFormat.font = "Comic Sans";
        startTextFormat.bold = true;
        startTextFormat.align = TextFormatAlign.CENTER;
        startTextFormat.color = 0xFFFFFF;
        startText.defaultTextFormat = startTextFormat;
        startText.width = noHoverButton.width;
        startText.height = 30;
        startText.x -= startText.width / 2;
        startText.y -= startText.height / 2;
        startText.text = "Start";
        Start_button.addChild(noHoverButton);
        Start_button.addChild(startText);
        Start_button.mouseChildren = false;
        Start_button.buttonMode = true;
      About_text_format = new TextFormat();
        About_text_format.size = 14;
        About_text_format.font = "Verdana";
        About_text_format.align = TextFormatAlign.CENTER;
        About_text_format.color = 0x000000;
      Learn_more_format = new TextFormat();
        Learn_more_format.size = 14;
        Learn_more_format.underline = true;
        Learn_more_format.font = "Verdana";
        Learn_more_format.align = TextFormatAlign.CENTER;
        Learn_more_format.color = 0x000000;
      Learn_more_text = new TextField();
        Learn_more_text.defaultTextFormat = Learn_more_format;
        Learn_more_text.width = 0.50 * stagewidth;
        Learn_more_text.height = 22;
        Learn_more_text.text = "Learn more about Measurement Lab";
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
        Learn_text_container.addChild(Learn_more_text);
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
      Start_button.y = Learn_text_container.y + 4*Learn_text_container.height;

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
      Learn_text_container.addEventListener(MouseEvent.CLICK, clickLearnText);
      Start_button.addEventListener(MouseEvent.ROLL_OVER, rollOverStart);
      Start_button.addEventListener(MouseEvent.ROLL_OUT, rollOutStart);
      Start_button.addEventListener(MouseEvent.CLICK, clickStart);
    }
  }
}

