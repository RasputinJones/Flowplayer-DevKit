/*
 * This file is part of Flowplayer, http://flowplayer.org
 *
 * By: Daniel Rossi, <electroteque@gmail.com>
 * Copyright (c) 2008 Electroteque Multimedia
 *
 * Released under the MIT License:
 * http://www.opensource.org/licenses/mit-license.php
 */
 
package org.flowplayer.bwcheck.servers
{

	import flash.net.Responder;
	
	import org.red5.flash.bwcheck.BandwidthDetection;
	
	public class WowzaServerClientBandwidth extends BandwidthDetection
	{
		private var info:Object = new Object();
		private var res:Responder;
		private var _counter:int = 0;
		
		public function WowzaServerClientBandwidth()
		{
			res = new Responder(onResult, onStatus);
		}
		
		public function onBWCheck(obj:Object):Boolean
		{
			dispatchStatus(obj);
			return true;
		}
			
		public function onBWDone(kbitDown:int, deltaDown:int, deltaTime:int, latency:int):void 
		{ 
			var obj:Object = new Object();
			obj.kbitDown = kbitDown;
			obj.delatDown = deltaDown;
			obj.deltaTime = deltaTime;
			obj.latency = latency;
			dispatchComplete(obj);
		} 
		
		
		override public function start():void
		{
			nc.client = this;
			nc.call(_service,res);
		}
		
		protected function onResult(obj:Object):void
		{
			dispatchStatus(obj);
				
		}
		
		protected function onStatus(obj:Object):void
		{
			switch (obj.code)
			{
				case "NetConnection.Call.Failed":
					dispatchFailed(obj);
				break;
			}

		}
	}
}