package com.bunnybones.kinect.frameTranslator 
{
	import air.update.net.FileDownloader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	/**
	 * ...
	 * @author Tomasz Dysinski
	 */
	public class RGBDToolkitDirectoryProcessor extends EventDispatcher
	{
		private var queue:Vector.<File>;
		private var destinationDirectory:File;
		private var initd:Boolean;
		private var currentTake:Take;
		private var initing:Boolean;
		static public var _singleton:RGBDToolkitDirectoryProcessor;
		
		public function RGBDToolkitDirectoryProcessor() 
		{
		}
		
		public function process(directory:File):void 
		{
			if (!initd) init();
			queue.push(directory);
			bumpProcess();
		}
		
		private function init():void 
		{
			if (!initing) {
				queue = new Vector.<File>;
				secureDestinationDirectory();
				initing = true;
			}
		}
		
		private function secureDestinationDirectory():void 
		{
			var file:File = new File();
			file.addEventListener(Event.SELECT, onDestinationDirectorySelect);
			file.addEventListener(Event.CANCEL, onDestinationDirectoryCancel);
			file.browseForDirectory("Select destination base directory for renders");
		}
		
		private function onDestinationDirectoryCancel(e:Event):void 
		{
			var file:File = e.target as File;
			deinitListenersOnFile(file);
		}
		
		private function deinitListenersOnFile(file:File):void 
		{
			file.removeEventListener(Event.SELECT, onDestinationDirectorySelect);
			file.removeEventListener(Event.CANCEL, onDestinationDirectoryCancel);
		}
		
		private function onDestinationDirectorySelect(e:Event):void 
		{
			destinationDirectory = e.target as File;
			deinitListenersOnFile(destinationDirectory);
			initd = true;
			bumpProcess();
		}
		
		private function bumpProcess():void 
		{
			if (!initd) return;
			if (!currentTake) {
				if (queue.length > 0) {
					var srcDir:File = queue.shift();
					var dstDir:File = destinationDirectory.resolvePath(srcDir.name);
					var take:Take = new Take(srcDir, dstDir, dstDir.url.substring(dstDir.url.lastIndexOf("/")+1, dstDir.url.length));
					take.addEventListener(Event.COMPLETE, onTakeProcessComplete);
					take.process();
					currentTake = take;
				} else {
					dispatchEvent(new Event(Event.COMPLETE));
				}
			}
		}
		
		private function onTakeProcessComplete(e:Event):void 
		{
			var take:Take = e.target as Take;
			take.removeEventListener(Event.COMPLETE, onTakeProcessComplete);
			currentTake = null;
			bumpProcess();
		}
		
		static public function get singleton():RGBDToolkitDirectoryProcessor 
		{
			if (!_singleton) _singleton = new RGBDToolkitDirectoryProcessor();
			return _singleton;
		}
	}

}