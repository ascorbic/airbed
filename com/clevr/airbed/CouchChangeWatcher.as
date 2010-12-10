/**
 * Airbed - Adobe AIR CouchDB Client Library
 * 
 * @author Matt Kane
 * @license The MIT license.
 * @copyright Copyright (c) 2010 CLEVR Ltd
 */

package com.clevr.airbed {

	import flash.net.URLStream;
	import flash.events.ProgressEvent;
	import com.clevr.airbed.events.CouchEvent;
	import com.adobe.serialization.json.JSON;
	import flash.events.TimerEvent;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	
	[Event(name="couchError", type="com.clevr.airbed.events.CouchEvent")]

	[Event(name="couchTimeout", type="com.clevr.airbed.events.CouchEvent")]

	[Event(name="couchChange", type="com.clevr.airbed.events.CouchEvent")]

	public class CouchChangeWatcher extends URLStream {
		
		private var _buffer:String;
		private var _timer:Timer;

		public function CouchChangeWatcher() {
			super();
		}        
		
		override public function load(request:URLRequest):void {
			_buffer = "";
			_timer = new Timer(60000);
			_timer.addEventListener(TimerEvent.TIMER, heartbeatTimout);
			addEventListener(ProgressEvent.PROGRESS, onProgress);
			addEventListener(Event.COMPLETE, onComplete);
			addEventListener(IOErrorEvent.IO_ERROR, onError);
			addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);

			try {
				super.load(request);
			} catch (e:Error) {
				var event:CouchEvent = new CouchEvent(CouchEvent.ERROR);
				event.data = {error: e.name, message: e.message};
				dispatchEvent(event);
				return;
			}	
			_timer.start();
		}
		
		private function heartbeatTimout(event:TimerEvent):void {
			var e:CouchEvent = new CouchEvent(CouchEvent.TIMEOUT);
			if(connected) {				
				close();
			}
			dispatchEvent(e);
		}
		
		private function handleData():void {
			if(bytesAvailable) {
				var newString:String = readUTFBytes(bytesAvailable);
				_buffer = _buffer.concat(newString);
			}
			var nl:int = _buffer.indexOf("\n");
			
			if(nl > -1) {
				_timer.reset();
				_timer.start();
				
				if(nl > 0) {
					/* Get the first change notification */
					var gotData:String = _buffer.slice(0, nl);
					_buffer = _buffer.substring(nl + 1);
					handleNotification(gotData);
					return;
				}
				_buffer = _buffer.substring(1);
			}
			
		}
		
		private function onError(error:Event):void {
			var e:CouchEvent = new CouchEvent(CouchEvent.ERROR);
			e.data = {error: error.type};
			dispatchEvent(e);
		}
		
		private function handleNotification(data:String):void {
			var obj:Object = JSON.decode(data);
			if (obj) {
				var e:CouchEvent;
				if(obj.error) {
					e = new CouchEvent(CouchEvent.ERROR);
				} else {
					e = new CouchEvent(CouchEvent.CHANGE);
				}
				e.data = obj;
				dispatchEvent(e);
			}
			/* We might have more */
			handleData();
		}
		
		private function onProgress(event:ProgressEvent):void {
			handleData();
		}

		private function onComplete(event:Event):void {
			handleData();
		}

	}

}