package 
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.system.Capabilities;

	
	/**
	 * ...
	 * @author Anant Subramanian
	 */
	public class Main extends Sprite 
	{
		
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			stage.showDefaultContextMenu = false;

			var hostname:String =  "utility.mlab.mlab1v4.nuq0t.measurement-lab.org"; //"127.0.0.1"; - Changed for testing purposes
			var clientID:String = "swf";

			function passedParams(Hostname:String, Clientid:String):void
			{
				if(Hostname) {
					hostname  = Hostname;
				}
				if(Clientid) {
					clientID = Clientid;
				}
			}

			/*if(ExternalInterface.available) {
				ExternalInterface.addCallback("passParameters", passedParams);
			}*/

			var Frame:MainFrame = new MainFrame(stage.stageWidth, stage.stageHeight, this, hostname, clientID, true);

			Frame.x = Frame.y = 0;

			stage.addChild(Frame);
		}
		
	}
	
}
