/**
 * Airbed - Adobe AIR CouchDB Client Library
 * 
 * @author Matt Kane
 * @license The MIT license.
 * @copyright Copyright (c) 2010 CLEVR Ltd
 */
package com.clevr.airbed {
	
	import flash.events.EventDispatcher;
	import flash.net.URLRequestMethod;
	import flash.net.URLRequest;
	import flash.net.URLLoader;
	import com.clevr.airbed.events.CouchEvent;
	import flash.events.Event;
	import flash.utils.Dictionary;
	import flash.net.URLLoaderDataFormat;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.HTTPStatusEvent;
	import flash.net.URLRequestHeader;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.net.FileReference;
	import flash.events.DataEvent;
	import com.brokenfunction.json.encodeJson;
	import com.brokenfunction.json.decodeJson;

	[Event(name="couchComplete", type="com.clevr.airbed.events.CouchEvent")]
	
	[Event(name="couchError", type="com.clevr.airbed.events.CouchEvent")]

	[Event(name="couchTimeout", type="com.clevr.airbed.events.CouchEvent")]

	[Event(name="couchChange", type="com.clevr.airbed.events.CouchEvent")]
	
	
	public class CouchServer extends EventDispatcher {



		public var baseUrl:String;
		public var session:Object;
		private var _loggedIn:Boolean = false;
		private var cookie:String;
		private var username:String;
		private var password:String;
		private var sessionTimer:Timer;
		
		public function get loggedIn():Boolean {
			return _loggedIn;
		}
		
		protected var _changeWatchers:Dictionary;//<CouchChangeWatcher>
		
		/**
		 * Respresents a CouchDB server instance
		 * 
		 * @param baseUrl The root of the server. e.g. http://127.0.0.1:5984/ 
		 */
		
		public function CouchServer(baseUrl:String){
			super();
			this.baseUrl = baseUrl;		
			this._changeWatchers = new Dictionary();	
		}
		
		
		/**
		 * Sends a PUT request to the server
		 * 
		 * @param path The path to the document on the server, including database name if appropriate
		 * @param data The object to send to the server. This will b e JSON-encoded
		 * @param onComplete A function called on success. Should have signature callback(event:CouchEvent, loader:URLLoader):void
		 * @param onError A function called on error. Should have signature callback(event:CouchEvent, loader:URLLoader):void
		 * 
		 * @return The URLLoader
		 */
		public function put(path:String, data:Object = null, onComplete:Function = null, onError:Function = null):URLLoader {
			return request("PUT", path, data, onComplete, onError);
		}
		
		/**
		 * Sends a DELETE request to the server. 
		 * Called del because delete is a reserved word.
		 * 
		 * @param path The path to the document on the server, including database name if appropriate
		 * @param onComplete A function called on success. Should have signature callback(event:CouchEvent, loader:URLLoader):void
		 * @param onError A function called on error. Should have signature callback(event:CouchEvent, loader:URLLoader):void
		 * 
		 * @return The URLLoader
		 */
		public function del(path:String, onComplete:Function = null, onError:Function = null):URLLoader {
			return request("DELETE", path, null, onComplete, onError);
		}

		/**
		 * Sends a GET request to the server
		 * 
		 * @param path The path to the document on the server, including database name if appropriate
		 * @param onComplete A function called on success. Should have signature callback(event:CouchEvent, loader:URLLoader):void
		 * @param onError A function called on error. Should have signature callback(event:CouchEvent, loader:URLLoader):void
		 * 
		 * @return The URLLoader
		 */
		public function get(path:String, onComplete:Function = null, onError:Function = null):URLLoader {
			return request("GET", path, null, onComplete, onError);
		}
		
		/**
		 * Sends a POST request to the server
		 * 
		 * @param path The path to the document on the server, including database name if appropriate
		 * @param data The object to send to the server. This will b e JSON-encoded
		 * @param onComplete A function called on success. Should have signature callback(event:CouchEvent, loader:URLLoader):void
		 * @param onError A function called on error. Should have signature callback(event:CouchEvent, loader:URLLoader):void
		 * 
		 * @return The URLLoader
		 */
		public function post(path:String, data:Object = null, onComplete:Function = null, onError:Function = null):URLLoader {
			return request("POST", path, data, onComplete, onError);
		}
		
		
		/**
		 * Sends a request to the server
		 * 
		 * @param method The HTTP verb. Should be one of GET, POST, DELETE, PUT
		 * @param path The path to the document on the server, including database name if appropriate
		 * @param data The object to send to the server. This will be JSON-encoded
		 * @param onComplete A function called on success. Should have signature callback(event:CouchEvent, loader:URLLoader):void
		 * @param onError A function called on error. Should have signature callback(event:CouchEvent, loader:URLLoader):void
		 * 
		 * @return The URLLoader
		 */
		public function request(method:String, path:String, data:Object=null, onComplete:Function = null, onError:Function = null):URLLoader {
			var req:URLRequest = new URLRequest(baseUrl + path);
			req.manageCookies = false;
			if(loggedIn) {
				req.requestHeaders = new Array(
					new URLRequestHeader('Cookie', cookie),
					new URLRequestHeader('X-CouchDB-WWW-Authenticate', 'Cookie')
				);
			}
			req.method = method;
			if(data !== null) {
				req.contentType = 'application/json';
				req.data = encodeJson(data);
			}
			
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			
			loader.addEventListener(Event.COMPLETE, function(event:Event):void {
				var obj:Object = decodeJson(event.target.data);				
				
				var e:CouchEvent;
				
				if (!obj || obj.error) {
					e = new CouchEvent(CouchEvent.ERROR);
					e.data = obj;
					
					if (onError != null) {
						onError(e, loader);
					}
					
				} else {
					e = new CouchEvent(CouchEvent.COMPLETE);
					e.data = obj;
					
					if (onComplete != null) {
						onComplete(e, loader);
					}					
				}
				
				dispatchEvent(e);
				
			});
			
			try {
				loader.load(req);
			} catch (e:Error) {
				var event:CouchEvent = new CouchEvent(CouchEvent.ERROR);
				event.data = {error: e.name, message: e.message};
				dispatchEvent(event);
			}	
			return loader;
		}


		/**
		 * Uploads and attaches a file to a document.
		 * 
		 * @param targetDocument The full path to the target document including database, relative to the base url. This must already exist.
		 * @param revision The current revision id of the target document.
		 * @param fileName The target filename, e.g. image.jpg
		 * @param mimeType The mimetype of the file. e.g. image/jpeg
		 * @param file The file to upload.
		 * @param onComplete The function to call after a successful upload. Passed a CouchEvent and FileReference.
		 * @param onError Function
		 */
		public function upload(targetDocument:String, revision:String, fileName:String, mimeType:String, file:FileReference, onComplete:Function = null, onError:Function = null):void {
			var req:URLRequest = new URLRequest(baseUrl + targetDocument + '/' + escape(fileName) + '?rev=' + revision);
			req.manageCookies = false;
			if(loggedIn) {
				req.requestHeaders = new Array(
					new URLRequestHeader('Cookie', cookie),
					new URLRequestHeader('X-CouchDB-WWW-Authenticate', 'Cookie')
				);
			}
			req.method = "PUT";
			
			file.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, function(event:DataEvent):void {
				trace(event.data);
				var obj:Object = decodeJson(event.data);	
				
				var e:CouchEvent;
				
				if (!obj || obj.error) {
					e = new CouchEvent(CouchEvent.ERROR);
					e.data = obj;
					
					if (onError != null) {
						onError(e, file);
					}
					
				} else {
					e = new CouchEvent(CouchEvent.COMPLETE);
					e.data = obj;
					
					if (onComplete != null) {
						onComplete(e, file);
					}					
				}
				
				dispatchEvent(e);
				
			});
			
			try {
				file.uploadUnencoded(req);
			} catch (e:Error) {
				var event:CouchEvent = new CouchEvent(CouchEvent.ERROR);
				event.data = {error: e.name, message: e.message};
				dispatchEvent(event);
			}	
		}
		

		
		/**
		 * Connects to a server and starts watching for changes.
		 * 
		 * @param database Name of the database to watch
		 * @param reconnectOnTimeout Whether we should attempt to reconnect we timeout
		 */
		public function watchChanges(database:String, reconnectOnTimeout:Boolean = true):void {
			get(database, function(e:CouchEvent, l:URLLoader):void {
				var seq:Number = e.data.update_seq;
				doWatchChanges(seq, database, reconnectOnTimeout);
			});
		}
		
		private function doWatchChanges(seq:Number, database:String, reconnectOnTimeout:Boolean = true):void {
			removeWatch(database);
			if(isNaN(seq)) {
				seq=0;
			}
			var watcher:CouchChangeWatcher = new CouchChangeWatcher();
			var req:URLRequest = new URLRequest(baseUrl + database + "/_changes?feed=continuous&heartbeat=30000&since=" + seq);
			if(loggedIn) {
				req.requestHeaders = new Array(
					new URLRequestHeader('Cookie', cookie),
					new URLRequestHeader('X-CouchDB-WWW-Authenticate', 'Cookie')
				);
			}
			
			watcher.addEventListener(CouchEvent.CHANGE, function(event:CouchEvent):void {
				dispatchEvent(event);
			});
			
			watcher.addEventListener(CouchEvent.TIMEOUT, function(event:CouchEvent):void {
				if(reconnectOnTimeout) {
					watchChanges(database);
				}
				dispatchEvent(event);
			});
			watcher.addEventListener(CouchEvent.ERROR, function(event:CouchEvent):void {
				dispatchEvent(event);
			});
			watcher.load(req);
			_changeWatchers[database] = watcher;
			
		}
		
		/**
		 * Closes and deletes a database change watcher.
		 * 
		 * @param database String
		 */
		public function removeWatch(database:String):void {
			if(!_changeWatchers || !_changeWatchers.hasOwnProperty(database)) {
				return;
			}
			
			var watcher:CouchChangeWatcher = _changeWatchers[database] as CouchChangeWatcher;
			if(watcher) {
				if (watcher.connected) {
					watcher.close();
				}
				delete _changeWatchers[database];
			}
		}
		
		/**
		 * Gets a session object from the server and stores it in the session property.
		 * 
		 * @param onSuccess If provided, this is called when the session is loaded. Passed a CouchEvent.
		 */
		public function getSessionInfo(onSuccess:Function = null):void {
			get('_session', function(e:CouchEvent, l:URLLoader):void {
				session = e.data;
				if(onSuccess != null) {
					onSuccess(e);
				}
			});
		}
		
		/**
		 * Logs the user in. 
		 * If successful, stores the session cookie. This cookie will then be used in all subsequent requests.
		 * 
		 * @param username 
		 * @param password 
		 * @param renew  If non-zero, renews the session after this number of seconds. Default is 300 (5 minutes).
		 * @param onSuccess Called after a successful login when the session info is available. Passed a CouchEvent.
		 */
		public function login(username:String, password:String, onSuccess:Function = null, renew:int = 300):void {
			
			var req:URLRequest = new URLRequest(baseUrl + '_session');
			req.method = "POST";
			req.contentType = 'application/x-www-form-urlencoded';
			req.data = 'username=' + escape(username) + '&password=' + escape(password);
			req.manageCookies = false;
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			
			if(renew > 0) {
				sessionTimer = new Timer(renew * 1000, 1);
				sessionTimer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void {
					login(username, password, onSuccess, renew);
				});
				sessionTimer.start();
			}
			
			var self:CouchServer = this;
			loader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, function(event:HTTPStatusEvent):void {
				for each (var item:Object in event.responseHeaders) {
					if (item.hasOwnProperty('name') && item.name == 'Set-Cookie') {
						var crumbs:Array = item.value.split(';'); 
						self.cookie = crumbs[0];
						self.username = username;
						self.password = password;
						self._loggedIn = true;
						getSessionInfo(onSuccess);
						break;
					}
				}
			});
			try {
				loader.load(req);
			} catch (e:Error) {
				var event:CouchEvent = new CouchEvent(CouchEvent.ERROR);
				event.data = {error: e.name, message: e.message};
				dispatchEvent(event);
				return;
			}	
			
			
		}
		
		
	}
	
}