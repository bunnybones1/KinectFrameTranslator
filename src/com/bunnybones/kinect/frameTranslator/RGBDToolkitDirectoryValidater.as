package com.bunnybones.kinect.frameTranslator 
{
	import flash.events.FileListEvent;
	import flash.filesystem.File;
	/**
	 * ...
	 * @author Tomasz Dysinski
	 */
	public class RGBDToolkitDirectoryValidater 
	{
		
		public function RGBDToolkitDirectoryValidater() 
		{
			
		}
		
		static public function validate(directory:File):Boolean 
		{
			directory.addEventListener(FileListEvent.DIRECTORY_LISTING, onDirectoryListing);
			directory.getDirectoryListingAsync();
			return true;
		}
		
		static private function onDirectoryListing(e:FileListEvent):void 
		{
			var file:File = e.target as File;
			file.removeEventListener(FileListEvent.DIRECTORY_LISTING, onDirectoryListing);
			var depthDirectory:File;
			for each(var file:File in e.files) {
				trace(file.name);
				if (file.isDirectory && file.name == "depth")
					depthDirectory = file;
			}
		}
		
	}

}