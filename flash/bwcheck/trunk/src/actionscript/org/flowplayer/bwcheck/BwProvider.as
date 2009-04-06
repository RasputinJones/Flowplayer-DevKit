/*     *    Copyright 2009 Daniel Rossi, Flowplayer Oy * *    This file is part of FlowPlayer. * *    FlowPlayer is free software: you can redistribute it and/or modify *    it under the terms of the GNU General Public License as published by *    the Free Software Foundation, either version 3 of the License, or *    (at your option) any later version. * *    FlowPlayer is distributed in the hope that it will be useful, *    but WITHOUT ANY WARRANTY; without even the implied warranty of *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the *    GNU General Public License for more details. * *    You should have received a copy of the GNU General Public License *    along with FlowPlayer.  If not, see <http://www.gnu.org/licenses/>. */package org.flowplayer.bwcheck {	import flash.events.NetStatusEvent;	import flash.net.NetConnection;	import flash.net.NetStream;	import flash.net.NetStreamPlayOptions;	import flash.net.NetStreamPlayTransitions;	import flash.net.SharedObject;	import flash.utils.Timer;	import mx.utils.StringUtil;	import org.flowplayer.bwcheck.event.DynamicStreamEvent;	import org.flowplayer.bwcheck.servers.FMSServerClientBandwidth;	import org.flowplayer.bwcheck.servers.HttpServerClientBandwidth;	import org.flowplayer.bwcheck.servers.WowzaServerClientBandwidth;	import org.flowplayer.controller.ClipURLResolver;	import org.flowplayer.controller.StreamProvider;	import org.flowplayer.model.Clip;	import org.flowplayer.model.ClipEvent;	import org.flowplayer.model.Plugin;	import org.flowplayer.model.PluginEventType;	import org.flowplayer.model.PluginModel;	import org.flowplayer.util.Log;	import org.flowplayer.util.PropertyBinder;	import org.flowplayer.view.Flowplayer;	import org.red5.flash.bwcheck.IBandwidthDetection;	import org.red5.flash.bwcheck.ServerClientBandwidth;	import org.red5.flash.bwcheck.events.BandwidthDetectEvent;	import org.flowplayer.cluster.RTMPCluster;	/**	 * A RTMP stream provider with fallback and clustering support. Supports following:	 * <ul>	 * <li>Starting in the middle of the clip's timeline using the clip.start property.</li>	 * <li>Stopping before the clip file ends using the clip.duration property.</li>	 * <li>Ability to combine a group of clips into one gapless stream.</li>	 * <li>Ability to fallback to a list of servers in a cluster server farm.</li>	 * <li>Ability to recognise, store and leave out any failed servers for a given time.</li>	 * <li>Ability to randomly connect to a server in the servers list mimicking a round robin connection.</li>	 * <li>Works with a traditional load balancing appliance by feeding its host at the top of the list, and direct connections to the servers happen on fallback.</li>	 * </ul>	 * <p>	 * Stream group is configured in a clip like this:	 * <code>	 * { streams: [ { url: 'metacafe', duration: 20 }, { url: 'honda_accord', start: 10, duration: 20 } ] }	 * </code>	 * The group is played back seamlessly as one gapless stream. The individual streams in a group can	 * be cut out from a larger file using the 'start' and 'duration' properties as shown in the example above.	 * 	 * <p> 	 * To enable server fallback a hosts config property is required in the plugins config like this:	 * 	 * hosts: [	 *	       'rtmp://server1.host.com/myapp',	 *	       'rtmp://server2.host.com/myapp',	 *	       'rtmp://server3.host.com/myapp',	 *	      ]	 * 	 * <p>	 * To enable the fallback feature to store (client side) failed servers to prevent reattempting those connections the failureExpiry config property is required like so:	 * failureExpiry: 3000,	 * 	 * <p> This tells the feature to wait for 3000 milliseconds before allowing connection attempts again. 	 * 	 * <p>	 * To enable round robin connections the loadBalanceServers config property requires to be enabled like so:	 * 	 * loadBalanceServers: true	 * 	 * <p>	 * Advanced configurations for the fallback feature can be enabled like so:	 * 	 * connectTimeout: 5000,	 * connectCount: 3	 * encoding: 0	 * 	 * <p> connectTimeout is the time in milliseconds before each reconnection attempt.	 * connectCount is the ammount of times connection reattmps will occur before giving up.	 * encoding is the AMF encoding version either 0 or 3 for AMF3.	 * 	 * <p> Two custom events a fired during connection attempts and fallback, these are:	 * 	 * <ul>	 * <li>RTMPEventType.RECONNECTED - onReconnect</li>	 * <li>RTMPEventType.FAILED - onFailed</li>	 * </ul>	 * 	 * @author danielr	 */	public class BwProvider implements ClipURLResolver, Plugin  {		private var _config:BWConfig;		private var log:Log = new Log(this);		private var _connection:NetConnection;		private var _netStream:NetStream;		private var _resolveSuccessListener:Function;		private var _failureListener:Function;		private var _clip:Clip;		private var _rest:Array;		private var _startAfterConnect:Boolean;		private var _hasDetectedBW:Boolean = false;		private var _detectionClass:Class;		private var _serviceMethod:String;        // TODO: refactor all bitrateProfile releated stuff to a new class called, for example "BitrateStorage" 		private var _bitrateProfile:SharedObject = SharedObject.getLocal("bitrateProfile","/");		private var _ncURI:String;		private var _provider:StreamProvider;		protected var _infoTimer:Timer;		private var _start:Number = 0;        private var _model:PluginModel;        protected var _rtmpCluster:RTMPCluster;        protected var _dynamicStream:DynamicStream;        protected var _host:String;        protected var _originalClipUrl:String;        protected var _oldStreamName:String;        private var _player:Flowplayer;        private var _resolving:Boolean;        public function onConfig(model:PluginModel):void {            log.debug("onConfig");            _config = new PropertyBinder(new BWConfig(), null).copyProperties(model.config) as BWConfig;            model.dispatchOnLoad();            _model = model;            _rtmpCluster = new RTMPCluster(_config);            _rtmpCluster.onFailed(onFailed);            _dynamicStream = new DynamicStream(_config);        }        public function onLoad(player:Flowplayer):void {            _player = player;        }        protected function hasDetectedBW():Boolean		{            if (! _config.rememberBitrate) return false;			if (_bitrateProfile.data.chosenBitrate || _hasDetectedBW) return true;			return false;		}		public function set onFailure(listener:Function):void {			_failureListener = listener;		}						protected function onFailed(event:ClipEvent):void		{			log.info("Connections failed");            dispatch("onFailed");		}        private function dispatch(event:String):void {            _model.dispatch(PluginEventType.PLUGIN_EVENT, event, _rtmpCluster.currentHost, _rtmpCluster.currentHostIndex);        }				/**		 * Start the bandwidth check connection depending on the serverType.		 * By default the FMS implementation requires a true property to the first of the connection arguments.		 * The other server implementations don't require this as they use AMF service callback methods.		 */		public function doBWConnect():void		{			_connection = new NetConnection();			_connection.addEventListener(NetStatusEvent.NET_STATUS, _onConnectionStatus);			_connection.close();            _connection.client = new NullNetConnectionClient();            _host = _rtmpCluster.host;            // set a listener to be used if connection fails, will connect to another host in the cluster            _rtmpCluster.onReconnected(onRTMPReconnect);            _rtmpCluster.start();            dispatch("onConnect");            log.debug("serverType is " + _config.serverType);            switch(_config.serverType)                {                case "fms":                        _connection.connect(_host, true);                        break;                case "wowza":                        _connection.connect(_host);                        break;                case "http":                        _connection.connect(null);                        break;                default:                        _connection.connect(null);                        break;            }		}		public function handeNetStatusEvent(event:NetStatusEvent):Boolean		{			return true;		}				protected function _onConnectionStatus(event:NetStatusEvent):void {						if (!hasDetectedBW())			{				switch (event.info.code) 				{					//connection is successful stop any reconnection attempts					case "NetConnection.Connect.Success":					    _rtmpCluster.stop();						doDetection();						//stopReconnect();					break;					//connection has failed, reattempt using the fallback system					case "NetConnection.Connect.Failed":						log.info("Couldnt connect to " + _connection.uri);					break;					//connection has closed					case "NetConnection.Connect.Closed":							break;				}			}		}					/**		 * Determine the server type to choose which way to handle the bandwidth detection and run the detection.		 */		protected function doDetection():void		{			log.debug("detecting bandwidth");			//dispatchEvent(new ClipEvent(BWDetectEventType.DETECT_START));            var detect:IBandwidthDetection;			switch(_config.serverType)			{                case "fms":					detect = new FMSServerClientBandwidth();				    break;				case "wowza":					detect = new WowzaServerClientBandwidth();				    break;				case "http":					detect = new HttpServerClientBandwidth();					HttpServerClientBandwidth(detect).url = _host;				    break;				default:						detect = new ServerClientBandwidth();					detect.service = "bwCheckService.onServerClientBWCheck";			}            detect.addEventListener(BandwidthDetectEvent.DETECT_COMPLETE, onServerClientComplete);            detect.addEventListener(BandwidthDetectEvent.DETECT_STATUS, onServerClientStatus);            detect.addEventListener(BandwidthDetectEvent.DETECT_FAILED, onDetectFailed);            detect.connection = _connection;            detect.start();		}				/**		 * Called when a detection has failed		 */		public function onDetectFailed(event:BandwidthDetectEvent):void		{			event.stopPropagation();			log.error("\n Detection failed with error: " + event.info.application + " " + event.info.description);			//dispatchEvent(new ClipEvent(BWDetectEventType.DETECT_FAILED));		}				/**		 * Called when a detection has completed and set the bandwidth properties from the returned values		 */		 		public function onServerClientComplete(event:BandwidthDetectEvent):void		{			event.stopPropagation();			log.info("\n\n kbit Down: " + event.info.kbitDown + " Delta Down: " + event.info.deltaDown + " Delta Time: " + event.info.deltaTime + " Latency: " + event.info.latency);			_hasDetectedBW = true;						// Set the detected bandwidth			var bitrate:Number = event.info.kbitDown;			var mappedBitrate:Number = getMappedBitrate(bitrate);			log.debug("bitrate (kbitDown) " + bitrate);			log.info("mapped to bitrate " + mappedBitrate);			// Store the bitrate to prevent further bitrate detections			rememberBitrate(mappedBitrate, bitrate);			//dispatchEvent(new ClipEvent(BWDetectEventType.DETECT_COMPLETE));			_connection.close();			_connection.client = new NullNetConnectionClient();	            _connection.connect(_ncURI && _ncURI != "null" ? _ncURI : null);            onBandwidthDetected(mappedBitrate, bitrate);        }		/*        private function getMappedBitrate(bitrate:Number):Number {            return getBitrate(bitrate, _config.bitrates, _config.defaultBitrate, _config.closestRateInterval);        }*/                private function getMappedBitrate(bitrate:Number):Number {       		return getBitrate(bitrate, _config.bitrates, _config.defaultBitrate, _config.closestRateInterval);        }        private function onBandwidthDetected(mappedBitrate:Number, detectedBitrate:Number):void {            // check if we are resolving or just switching streams based on detected BW            if (_resolving) {                changeStreamNames(mappedBitrate);                _resolveSuccessListener(_clip);                _resolving = false;                            } else if (_player.isPlaying() || _player.isPaused()) {                switchStream(mappedBitrate);                            } else {                changeStreamNames(mappedBitrate);            }            log.debug("dispatching onBwDone, mapped bitrate: " + mappedBitrate + " detected bitrate " + detectedBitrate + " url: " + _clip.url);            _model.dispatch(PluginEventType.PLUGIN_EVENT, "onBwDone", _clip.url, mappedBitrate, detectedBitrate);        }        private function changeStreamNames(bitrate:Number):void {            _oldStreamName = _clip.url;            _clip.resolvedUrl = getClipUrl(bitrate);        }        private function switchStream(bitrate:Number):void {            changeStreamNames(bitrate);            if (_config.dynamic) {                var options:NetStreamPlayOptions = new NetStreamPlayOptions();                if (_oldStreamName) {                    options.oldStreamName = _oldStreamName;                    options.transition = NetStreamPlayTransitions.SWITCH;                } else {                    options.transition = NetStreamPlayTransitions.RESET;                }                options.streamName = _clip.url;                //if (!_config.switchCurrentPosition) options.start = 0;                log.debug("calling play2");                _model.dispatch(PluginEventType.PLUGIN_EVENT, "onStreamSwitch", bitrate, options.streamName,  options.oldStreamName);                _netStream.play2(options);            } else {                log.debug("calling play");                _netStream.play(_clip.url, _config.switchCurrentPosition ? _netStream.time : 0, _clip.duration > 0 ? _clip.duration : -1);            }        }						/**		 * Called during the bitrate detection checking and return its status		 */		public function onServerClientStatus(event:BandwidthDetectEvent):void		{				if (event.info) {				log.info("\n count: "+event.info.count+ " sent: "+event.info.sent+" timePassed: "+event.info.timePassed+" latency: "+event.info.latency+" cumLatency: " + event.info.cumLatency);				//dispatchEvent(new ClipEvent(BWDetectEventType.DETECT_STATUS));			}		}				protected function onRTMPReconnect():void		{            dispatch("onConnectFailed");            _rtmpCluster.setFailedServer(_host);            _connection.close();            doBWConnect();			log.info("Attempting reconnection");		}				/**		 * Determine the chosen bitrate from a given list of bitrates		 * The default bitrate is chosen on fallback of choosing a rate.		 * The highest possible rate is chosen if a clients bandwidth is above or below the highest rate determined by the closestRateInterval config property.		 */		 /*		protected function getBitrate(kBDown:int, bitrates:Array, defaultBitrate:Number, closestRateInterval:int):Number		{			var bitrate:Number = defaultBitrate;			var rates:Array = bitrates.concat();				rates.sort(Array.NUMERIC, Array.DESCENDING).reverse()						var largest_rate:Number = rates[0];									for (var i:int = 0; i < rates.length; i++) {				if (kBDown >= Number(largest_rate))				{					bitrate = largest_rate;					return bitrate;				} else if (kBDown >= (rates[i] - closestRateInterval)) {					bitrate = rates[i];					return bitrate;				} else if (kBDown < Number(rates[i])) {					bitrate = rates[i];				}			}			return bitrate;		}*/				protected function getBitrate(kBDown:int, bitrates:*, defaultBitrate:Number, closestRateInterval:int):Number		{			var bitrate:Number;			var largest_rate:Number = bitrates[0];			var curStreamID:int = 0;						for (var i:int = 0; i < bitrates.length; i++) {				if (kBDown >= Number(largest_rate))				{					curStreamID = 0;					break;				} else if (kBDown >= (bitrates[i] - closestRateInterval)) {					curStreamID = i;					break;				} else if (kBDown < Number(bitrates[i])) {					curStreamID = i;				}			}						bitrate = bitrates[curStreamID];			return (bitrate ? bitrate : defaultBitrate);		}						/**		 * Store the detection and chosen bitrate if the rememberBitrate config property is set.		 */		protected function rememberBitrate(chosenBitrate:Number, detectedBitrate:int):void		{            log.debug("remembering bitrate " + chosenBitrate);			if (_config.rememberBitrate) {				_bitrateProfile.data.chosenBitrate = chosenBitrate;			}		}        /**         * Callback from DynamicStream.         * @param event         * @return         */        protected function onSwitchStream(event:DynamicStreamEvent):void		{			switchStream(_config.bitrates[event.info.streamID]);		}				public function resolve(provider:StreamProvider, clip:Clip, successListener:Function):void {            log.debug("resolve " + clip);			//_bitrateProfile.clear();            _resolving = true;			_provider = provider;			_connection = provider.netConnection;			_netStream = provider.netStream;			_resolveSuccessListener = successListener;			_clip = clip;			_start = _netStream.time;			_originalClipUrl = _clip.url;						if (_config.dynamic) 			{				_dynamicStream.addEventListener(DynamicStreamEvent.SWITCH_STREAM, onSwitchStream);				_dynamicStream.netStream = _netStream;				_clip.onStart(_dynamicStream.onStart);				_clip.onStop(_dynamicStream.onStop);				_clip.onBufferEmpty(_dynamicStream.onBufferEmpty);				_clip.onBufferFull(_dynamicStream.onBufferFull);				_clip.onSeek(_dynamicStream.onSeek);				_clip.onPause(_dynamicStream.onPause);				_clip.onResume(_dynamicStream.onResume);				_clip.onError(_dynamicStream.onError);			}								_ncURI = _connection.uri;			if (!hasDetectedBW())			{				doBWConnect();			} else {                var bitrate:Number = _bitrateProfile.data.chosenBitrate;                log.info("using remembered bitrate " + bitrate);                onBandwidthDetected(getMappedBitrate(bitrate), bitrate);							}		}				protected function  getClipUrl(mappedBitrate:Number):String		{			var name:String;			var ext:String;			if (_originalClipUrl.lastIndexOf(".") > 0)			{				name = _originalClipUrl.substring(0,_originalClipUrl.lastIndexOf("."));				ext = _originalClipUrl.substring(_originalClipUrl.lastIndexOf(".") + 1,_originalClipUrl.length);			} else {				name = _originalClipUrl;				ext = "";			}			var file:String = StringUtil.substitute(_config.urlPattern, name, mappedBitrate, ext);			log.info("Resolved stream url: " + file);				return file;		}				public static function isRtmpUrl(url:String):Boolean {			return url && url.toLowerCase().indexOf("rtmp") == 0;		}        private function checkCurrentClip():Boolean {            var clip:Clip = _player.playlist.current;            if (_clip == clip) return true;                        if (clip.urlResolvers.indexOf(_model.name) < 0) {                return false;            }            _clip = clip;            _originalClipUrl = _clip.url;            return true;        }        [External]        public function checkBandwidth():void    	{            log.debug("checkBandwidth");            if (! checkCurrentClip()) return;            _start = _provider ? _provider.time : 0;            //            if (_netStream) {            //			    _netStream.close();            //            }            _bitrateProfile.data.detectedBitrate = null;            _bitrateProfile.data.chosenBitrate = null;            _hasDetectedBW = false;            doBWConnect();        }		[External]		public function changeBitrate(bitrate:Number):void		{            log.debug("changeBitrate");            if (! checkCurrentClip()) return;            rememberBitrate(getMappedBitrate(Number(bitrate)), _bitrateProfile.data.detectedBitrate);                        if (_player.isPlaying() || _player.isPaused()) {                switchStream(bitrate);            }		}        public function getDefaultConfig():Object {            return null;        }    }}