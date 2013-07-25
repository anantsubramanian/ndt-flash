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
	
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.text.*;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.ui.Mouse;
	import com.greensock.TweenLite;
	import com.greensock.easing.*;
	import flash.events.Event;
	import flash.net.*;
	import flash.display.DisplayObjectContainer;
	
	public class GUI extends Sprite{
		
		/*
		
			Class that contains the GUI elements.
			Can be removed if not necessary.
			
		*/
		
		// variables declaration section
		
		private var stagewidth:int;
		private var stageheight:int;
		private var parentObject:MainFrame;
		
		private var Progress_bar:progressBar;
		private var Mlab_logo:mLabLogo;
		private var Mlab_url:String = "http://www.measurementlab.net";
		private var Url_request:URLRequest;
		private var Start_button:MovieClip;
			private var Hover:startHover;
			private var No_hover:startNoHover;
		
		private var About_text_format:TextFormat;			
		private var Learn_text_format:TextFormat;		
		private var About_ndt_text:TextField;		
		private var Learn_more_text:TextField;		
		private var Learn_text_container:Sprite;
		
		// event listener functions
		
		function rollOverLearn(e:MouseEvent):void {
			Learn_text_container.alpha = 0.80;
			Learn_more_text.textColor = 0x000000;
		}
		
		function rollOutLearn(e:MouseEvent):void {
			Learn_text_container.alpha = 1;
			Learn_more_text.textColor = 0xFFFFFF;
		}
		
		function clickLearnText(e:MouseEvent):void {
			try {
				navigateToURL(Url_request);
			}
			
			catch (error:Error) {
				trace(error);
				// do nothing
			}
		}
		
		function rollOverStart(e:MouseEvent):void {
			if(Start_button.getChildAt(0)) {
			   Start_button.removeChildAt(0);
			}
			Start_button.addChild(Hover);	 
		}
		
		function rollOutStart(e:MouseEvent):void {
			if(Start_button.getChildAt(0)) {
			   Start_button.removeChildAt(0);
			}
			Start_button.addChild(No_hover);
		}
		
		function clickStart(e:MouseEvent):void {
			hideInitialScreen();
			
			parentObject.dottcp();			
		}
		
		// end initial event-listener functions
		
		// animation functions
		
		function startUpAnimation():void {
			
			Mlab_logo.alpha = 0;
			Start_button.alpha = 0;
			About_ndt_text.alpha = 0;
			Learn_text_container.alpha = 0;
		
			TweenLite.to(Mlab_logo, 0.75, {alpha:1, ease:Linear.easeNone});
			TweenLite.to(About_ndt_text, 0.75, {alpha:1, ease:Linear.easeNone});
			TweenLite.to(Learn_text_container, 0.75, {alpha:1, ease:Linear.easeNone});
			TweenLite.to(Start_button, 0.75, {alpha:1, ease:Linear.easeNone});
		
		}
		
		function hideInitialScreen():void {
			
			TweenLite.to(Mlab_logo, 0.25, {alpha:0, ease:Linear.easeNone});
			TweenLite.to(About_ndt_text, 0.25, {alpha:0, ease:Linear.easeNone});
			TweenLite.to(Learn_text_container, 0.25, {alpha:0, ease:Linear.easeNone});
			TweenLite.to(Start_button, 0.25, {alpha:0, ease:Linear.easeNone});
			
			if(this.getChildByName("Mlab_logo")) {
				this.removeChild(Mlab_logo);   
			}
			if(this.getChildByName("About_ndt_text")) {
				this.removeChild(About_ndt_text);   
			}
			if(this.getChildByName("Learn_text_container")) {
				this.removeChild(Learn_text_container);   
			}
			if(this.getChildByName("Start_button")) {
				this.removeChild(Start_button);   
			}
			
			// removing initial event listeners
			
			Learn_text_container.removeEventListener(MouseEvent.ROLL_OVER, rollOverLearn);
			Learn_text_container.removeEventListener(MouseEvent.ROLL_OUT, rollOutLearn);
			Learn_text_container.removeEventListener(MouseEvent.CLICK, clickLearnText);
			Start_button.removeEventListener(MouseEvent.ROLL_OVER, rollOverStart);
			Start_button.removeEventListener(MouseEvent.ROLL_OUT, rollOutStart);
			Start_button.removeEventListener(MouseEvent.CLICK, clickStart);
			Learn_text_container.buttonMode = false;
			Start_button.buttonMode = false;
		
		}
		
		public function waitMessage():void {
			var waitF:TextField = new TextField();
			waitF.width = stagewidth;
			waitF.text = "Please Wait ~15 sec for results.";
			this.addChild(waitF);
		}
		
		// temporary function to display results
		public function displayResults():void {
			while(this.numChildren) {
				this.removeChildAt(0);
			}
			var textF:TextField = new TextField();
			textF.width = stagewidth;
			textF.height = stageheight;
			this.addChild(textF);
			textF.text = "Console Output Produced : \n\n" + TestResults.consoleOutput + "\n";
			textF.appendText("Statistics : \n" + TestResults.statsText + "\n");
			textF.appendText("Trace Output Produced : \n\n" + TestResults.traceOutput + "\n");
			textF.appendText("Errors (blank lines indicate no errors) : \n\n" + TestResults.errMsg + "\n");
			textF.appendText("Received web100vars : \n" + TestS2C._sTestResults); 
		}

		public function GUI(stageW:int, stageH:int, Parent:MainFrame) {
			// constructor code
			
			stagewidth  = stageW;
			stageheight = stageH;
			parentObject = Parent;
			
			// variables initialization
			
			Progress_bar = new progressBar();
			Mlab_logo = new mLabLogo();
			Url_request = new URLRequest(Mlab_url);
			Start_button = new MovieClip();
				Hover = new startHover();
				No_hover = new startNoHover();
				Start_button.addChild(No_hover); // by default mouse is not hovering over the button 
				Start_button.buttonMode = true;
			
			About_text_format = new TextFormat();
				About_text_format.size = 18;
				About_text_format.align = TextFormatAlign.CENTER;
				About_text_format.color = 0x000000;
				
			Learn_text_format = new TextFormat();
				//Learn_text_format.size = 15;
				Learn_text_format.align = TextFormatAlign.CENTER;
				Learn_text_format.color = 0xFFFFFF;
				Learn_text_format.underline = true;
				
			About_ndt_text = new TextField();
			About_ndt_text.defaultTextFormat = About_text_format;
			About_ndt_text.width = 0.75 * stagewidth;
			About_ndt_text.height = 0.40 * stageheight;
			About_ndt_text.wordWrap = true;
			About_ndt_text.selectable = false;
			About_ndt_text.text = "Network Diagnostic Tool (NDT) provides a sophisticated speed and diagnostic test." + 
								  " An NDT test reports more than just the upload and download speeds — it also attempts" +
								  "to determine what, if any, problems limited these speeds, differentiating between" +
								  "computer configuration and network infrastructure problems. While the diagnostic messages" +
								  "are most useful for expert users, they can also help novice users by allowing them to" +
								  "provide detailed trouble reports to their network administrator.";
								  
			Learn_more_text = new TextField();
				Learn_more_text.width = 225;
				Learn_more_text.height = 20;
				Learn_more_text.defaultTextFormat = Learn_text_format;
				Learn_more_text.text = "Learn more about Measurement Lab";
				Learn_more_text.selectable = false;
				
			Learn_text_container = new Sprite();
				Learn_text_container.addChild(Learn_more_text);
				Learn_text_container.buttonMode = true;
				Learn_text_container.mouseChildren = false;
				
			// positioning objects on stage using a relative layout
	
			Progress_bar.x = stagewidth / 2;
			Progress_bar.y = stageheight / 2;
			Mlab_logo.x = stagewidth / 2;
			Mlab_logo.y = Mlab_logo.height;
			About_ndt_text.x = 0.125 * stagewidth;
			About_ndt_text.y = 2 * (Mlab_logo.y);
			Learn_text_container.x = (stagewidth / 2) - (Learn_text_container.width / 2);
			Learn_text_container.y = About_ndt_text.y + About_ndt_text.height;
			Start_button.x = (stagewidth / 2) - (Start_button.width / 2);
			Start_button.y = Learn_text_container.y + Learn_text_container.height + (Start_button.height / 2);
			
			
			// adding objects to the display object
			
			this.addChild(Mlab_logo);
			this.addChild(About_ndt_text);
			this.addChild(Learn_text_container);
			this.addChild(Start_button);
			
			startUpAnimation(); // to be removed if not required
			
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
