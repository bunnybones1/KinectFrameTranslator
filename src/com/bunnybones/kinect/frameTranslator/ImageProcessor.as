package com.bunnybones.kinect.frameTranslator 
{
	import flash.display.BitmapData;
	import flash.display.Shader;
	import flash.filters.ShaderFilter;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Tomasz Dysinski
	 */
	public class ImageProcessor 
	{
		static private var origin:Point = new Point();
		
		[Embed(source="filters/DeinterlaceKinectFrameToMonochrome.pbj", mimeType="application/octet-stream")]
		static private var pixelBenderFilter:Class;
		static private var shader:Shader = new Shader(new pixelBenderFilter());
		static private var filter:ShaderFilter = new ShaderFilter(shader);
		
		public function ImageProcessor() 
		{
			
		}
		
		static public function process(bitmapData:BitmapData):void 
		{
			bitmapData.applyFilter(bitmapData, bitmapData.rect, origin, filter);
		}
		
	}

}