package com.bunnybones.kinect.frameTranslator
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FileListEvent;
	import flash.filesystem.File;
	
	/**
	 * ...
	 * @author Tomasz Dysinski
	 */
	public class Main extends Sprite 
	{
		
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		private function onAddedToStage(e:Event):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			init();
		}
		
		private function init():void 
		{
			browseForDirectory();
		}
		
		private function browseForDirectory():void 
		{
			var file:File = new File();
			file.addEventListener(Event.CANCEL, onBrowseForDirectoryCancel);
			file.addEventListener(Event.SELECT, onBrowseForDirectorySelect);
			file.browseForDirectory("Select a base dir of RGBDToolkit TAKES to process");
		}
		
		private function onBrowseForDirectoryCancel(e:Event):void 
		{
			var file:File = e.target as File;
			deinitListenersOnFile(file);
		}
		
		private function deinitListenersOnFile(file:File):void 
		{
			file.removeEventListener(Event.SELECT, onBrowseForDirectorySelect);
			file.removeEventListener(Event.CANCEL, onBrowseForDirectoryCancel);
		}
		
		private function onBrowseForDirectorySelect(e:Event):void 
		{
			var file:File = e.target as File;
			deinitListenersOnFile(file);
			file.addEventListener(FileListEvent.DIRECTORY_LISTING, onDirectoryListing);
			file.getDirectoryListingAsync();
		}
		
		private function onDirectoryListing(e:FileListEvent):void 
		{
			var file:File = e.target as File;
			file.removeEventListener(FileListEvent.DIRECTORY_LISTING, onDirectoryListing);
			var directoriesToProcess:Vector.<File> = new Vector.<File>
			for each(var file:File in e.files) {
				if (file.isDirectory) directoriesToProcess.push(file);
			}
			processDirectories(directoriesToProcess);
		}
		
		private function processDirectories(directories:Vector.<File>):void 
		{
			validateFilter(directories);	//removes directories that aren't TAKE folders from RGBDToolkit
			processTakes(directories);		//processes each folder
		}
		
		private function validateFilter(directories:Vector.<File>):void 
		{
			for (var i:int = directories.length-1; i >= 0; i--) 
			{
				var directory:File = directories[i];
				if (!RGBDToolkitDirectoryValidater.validate(directory)) directories.splice(i, 1);
			}
		}
		
		private function processTakes(directories:Vector.<File>):void 
		{
			RGBDToolkitDirectoryProcessor.singleton.addEventListener(Event.COMPLETE, onProcessorComplete);
			for each(var directory:File in directories) {
				RGBDToolkitDirectoryProcessor.singleton.process(directory);
			}
		}
		
		private function onProcessorComplete(e:Event):void 
		{
			trace("DONE!");
		}
		
	}
	
}