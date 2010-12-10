/**
 * Airbed - Adobe AIR CouchDB Client Library
 * 
 * @author Matt Kane
 * @license The MIT license.
 * @copyright Copyright (c) 2010 CLEVR Ltd
 */

package com.clevr.airbed {
	import com.adobe.crypto.SHA1;
	import flash.net.NetworkInfo;
	import flash.net.NetworkInterface;
	import flash.desktop.NativeApplication;
	import flash.system.Capabilities;
	
	public class UUID extends Object {
		private static var macAddress:String;
		private static var index:Number = 0;
		
		/**
		 *	Generates a uuid to use as a document _id.
		 *	This uses the machine's MAC address if available, as well as time, application id and an incrementing index. 
		 */
		public static function generate():String {
			if(!macAddress) {
				if(NetworkInfo.isSupported) {
					var ni:Vector.<NetworkInterface> = NetworkInfo.networkInfo.findInterfaces();
					for (var i:int = 0; i < ni.length; i++)	{
						if(ni[i].hardwareAddress) {
							macAddress = ni[i].hardwareAddress;
							break;
						}
					}
				}
				if(!macAddress) {
					/* No MAC address available. We'll have to use something else. */
					macAddress = SHA1.hash( Capabilities.serverString + Math.random().toString());					
				}
			}
			
			return SHA1.hash(new Date().time.toString() + '-' + macAddress + '-' + NativeApplication.nativeApplication.applicationID + '-' + index++);			
		}
		
	}
	
}

