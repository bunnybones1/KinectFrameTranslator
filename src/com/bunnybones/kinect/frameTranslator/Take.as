package com.bunnybones.kinect.frameTranslator 
{
	import air.update.net.FileDownloader;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.JPEGEncoderOptions;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.FileListEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.display.PNGEncoderOptions;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.CompressionAlgorithm;
	import flash.utils.Dictionary;
	
	/**
	 * ...
	 * @author Tomasz Dysinski
	 */
	public class Take extends EventDispatcher
	{
		static public const MILLIS_PER_SECOND:Number = 1000;
		static public const DEBUG:Boolean = true;
		private var srcDirectory:File;
		private var dstDirectory:File;
		private var srcFrames:Vector.<File>;
		private var srcMillisLookup:Vector.<int>;
		private var retimedFrameLookup:Vector.<int>;
		private var name:String;
		private var cacheBitmapData:BitmapData;
		private var renderFileRelations:Dictionary;
		private var lastSrcFile:File;
		private var srcFilesToRender:Vector.<File>;
		private var srcFileByLoaderInfo:Dictionary;
		
		public function Take(srcDirectory:File, dstDirectory:File, name:String = "footage") 
		{
			this.name = name;
			this.srcDirectory = srcDirectory;
			this.dstDirectory = dstDirectory;
			renderFileRelations = new Dictionary();
			srcFileByLoaderInfo = new Dictionary();
			srcFilesToRender = new Vector.<File>;
		}
		
		public function process():void 
		{
			srcDirectory = srcDirectory.resolvePath("depth");
			if (!dstDirectory.exists) dstDirectory.createDirectory();
			dstDirectory = dstDirectory.resolvePath("normalized");
			if (!dstDirectory.exists) dstDirectory.createDirectory();
			srcDirectory.addEventListener(FileListEvent.DIRECTORY_LISTING, onSrcFramesListing);
			srcDirectory.getDirectoryListingAsync();
		}
		
		private function onSrcFramesListing(e:FileListEvent):void 
		{
			srcDirectory.removeEventListener(FileListEvent.DIRECTORY_LISTING, onSrcFramesListing);
			srcFrames = new Vector.<File>;
			for (var i:int = 0; i < e.files.length; i++) 
			{
				var file:File = e.files[i];
				if (file.name.indexOf("_millis_") != -1 && file.name.indexOf(".png") != -1) {
					srcFrames.push(file);
				}
			}
			
			srcMillisLookup = new Vector.<int>();
			
			for (var i:int = 0; i < srcFrames.length; i++) 
			{
				var name:String = srcFrames[i].name;
				var start:int = name.indexOf("millis_") + 7;
				var end:int = name.indexOf(".png");
				var frameString:String = name.substring(start, end);
				if(DEBUG) trace(int(frameString));
				srcMillisLookup[i] = int(frameString);
			}
			
			generateFootage(30);
		}
		
		private function generateFootage(fps:Number):void 
		{
			var frame:int = -1;
			var idealFrameDuration:Number = MILLIS_PER_SECOND / fps;
			var lastSrcFrameUsed:int = 0;
			retimedFrameLookup = new Vector.<int>;
			while (lastSrcFrameUsed < srcMillisLookup.length-1)
			{
				frame++;
				var millis:int = frame * idealFrameDuration;
				while (millis > srcMillisLookup[lastSrcFrameUsed])
				{
					lastSrcFrameUsed++;
					if (lastSrcFrameUsed >= srcMillisLookup.length) break;
				}
				if(DEBUG) trace(frame + ": " + lastSrcFrameUsed);
				retimedFrameLookup.push(lastSrcFrameUsed);
			}
			
			var lastIndex:int = -1;
			var index:int;
			for (var i:int = 0; i < retimedFrameLookup.length; i++) 
			{
				index = retimedFrameLookup[i];
				if (index != lastIndex && index < srcFrames.length) {
					var srcFile:File = srcFrames[index];
					addFileToSrcQueue(srcFile);
				}
				var dstFile:File = dstDirectory.resolvePath(name + "_" + StringUtils.fixedWidthInt(i, 6) + ".png");
				if(!dstFile.exists) addFileToDstQueue(dstFile);
				lastIndex = index;
			}
			bumpProcess();
		}
		
		private function bumpProcess():void 
		{
			if (srcFilesToRender.length > 0) {
				var currentSrcFile:File = srcFilesToRender.shift();
				var dstFiles:Vector.<File> = renderFileRelations[currentSrcFile];
				if (dstFiles.length == 0) {
					if (DEBUG) trace("2:WARNING: No destinations for current frame");
					bumpProcess();
				} else {
					processCache(currentSrcFile);
				}
			} else {
				if (DEBUG) trace("finished rendering all frames");
				dispatchEvent(new Event(Event.COMPLETE));
			}
		}
		
		private function addFileToDstQueue(dstFile:File):void 
		{
			//adds dstFile to last srcFile
			var dstFiles:Vector.<File> = renderFileRelations[lastSrcFile];
			dstFiles.push(dstFile);
		}
		
		private function addFileToSrcQueue(srcFile:File):void 
		{
			lastSrcFile = srcFile;
			srcFilesToRender.push(srcFile);
			renderFileRelations[srcFile] = new Vector.<File>;
		}
		
		private function processCache(srcFile:File):void 
		{
			if(DEBUG) trace("updating cache");
			openSource(srcFile);
		}
		
		private function openSource(srcFile:File):void 
		{
			if(DEBUG) trace("opening image");
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onSrcOpenComplete);
			loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onSrcOpenProgress);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onSrcOpenIOError);
			srcFileByLoaderInfo[loader.contentLoaderInfo] = srcFile;
			loader.load(new URLRequest(srcFile.url));
		}
		
		private function onSrcOpenIOError(e:IOErrorEvent):void 
		{
			if(DEBUG) trace("error!");
			var loaderInfo:LoaderInfo = e.target as LoaderInfo;
			deinitLoader(loaderInfo);
		}
		
		private function onSrcOpenProgress(e:ProgressEvent):void 
		{
			if(DEBUG) trace(e.bytesLoaded / e.bytesTotal);
		}
		
		private function onSrcOpenComplete(e:Event):void 
		{
			if(DEBUG) trace("complete!" );
			var loaderInfo:LoaderInfo = e.target as LoaderInfo;
			deinitLoader(loaderInfo);
			
			var srcBitmap:Bitmap = loaderInfo.content as Bitmap;
			cacheBitmapData = new BitmapData(srcBitmap.width, srcBitmap.height);
			cacheBitmapData.draw(srcBitmap.bitmapData);
			ImageProcessor.process(cacheBitmapData);
			
			saveCache(renderFileRelations[srcFileByLoaderInfo[loaderInfo]]);
			bumpProcess();
		}
		
		private function deinitLoader(loaderInfo:LoaderInfo):void 
		{
			loaderInfo.addEventListener(Event.COMPLETE, onSrcOpenComplete);
			loaderInfo.addEventListener(ProgressEvent.PROGRESS, onSrcOpenProgress);
			loaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onSrcOpenIOError);
		}
		
		private function saveCache(dstFiles:Vector.<File>):void 
		{
			if(DEBUG) trace("saving last cached image");
			var fileStream:FileStream = new FileStream();
			for (var i:int = 0; i < dstFiles.length; i++) 
			{
				fileStream.openAsync(dstFiles[i], FileMode.WRITE);
				var byteArray:ByteArray = new ByteArray();
				var compressor:PNGEncoderOptions = new PNGEncoderOptions();
				cacheBitmapData.encode(cacheBitmapData.rect, compressor, byteArray);
				fileStream.writeBytes(byteArray);
				fileStream.close();
			}
		}
		
	}

}