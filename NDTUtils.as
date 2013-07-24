package  {
	
	public class NDTUtils {

		/*
		
			Class that defines utility methods used by the NDT.
		
		*/
		
		/*
			Utility method to print a double value upto the
			hundereth place.
			
			@param paramDblToFormat
						Double number to format
						
			@return String value of double number
		*/
		public static function prtdbl(paramDblToFormat:Number):String {
			var str:String = null;
			var i:int;
			
			if(paramDblToFormat == 0) {
				return("0");
			}
			
			str = paramDblToFormat.toString();
			i = str.indexOf(".");
			i += 3;
			if(i > str.length) {
				i -= 1;
			}
			if(i > str.length) {
				i -= 1;
			}
			return (str.substr(0, i));
		}
	}
	
}
