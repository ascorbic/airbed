/**
 * Airbed - Adobe AIR CouchDB Client Library
 * 
 * @author Matt Kane
 * @license The MIT license.
 * @copyright Copyright (c) 2010 CLEVR Ltd
 */

package com.clevr.airbed.events {
	
	import com.adobe.webapis.events.ServiceEvent;
	import flash.events.Event;
	
	/**
	 * Respresents the result from a CouchDB server
	 */
	public class CouchEvent extends ServiceEvent {

		public static const COMPLETE:String = "couchComplete";
		public static const ERROR:String = "couchError";
		public static const CHANGE:String = "couchChange";
		public static const TIMEOUT:String = "couchTimeout";

		public function CouchEvent(type:String, bubbles:Boolean=true, cancelable:Boolean=false) {
			super(type, bubbles, cancelable);
		}
		
		public override function clone():Event {
			var out:CouchEvent = new CouchEvent(type, bubbles, cancelable);
			out.data = data;

			return out;
		}
	}

}