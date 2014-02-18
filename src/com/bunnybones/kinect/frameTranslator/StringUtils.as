package com.bunnybones.kinect.frameTranslator 
{
	/**
	 * ...
	 * @author Tomasz Dysinski
	 */
	public class StringUtils 
	{
		
		public function StringUtils() 
		{
			
		}
		
		static public function fixedWidthInt(value:int, totalDigits:int = 1):String
		{
			var string:String = value.toString();
			while (string.length < totalDigits) string = "0" + string;
			return string;
		}
		
	}

}