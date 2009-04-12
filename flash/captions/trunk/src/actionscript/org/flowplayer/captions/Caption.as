/* * This file is part of Flowplayer, http://flowplayer.org * * By: Daniel Rossi, <electroteque@gmail.com> * Copyright (c) 2009 Electroteque Multimedia * * Released under the MIT License: * http://www.opensource.org/licenses/mit-license.php */package org.flowplayer.captions {    import flash.events.MouseEvent;import flash.geom.Rectangle;import org.flowplayer.captions.parsers.JSONParser;	import org.flowplayer.captions.parsers.SRTParser;	import org.flowplayer.captions.parsers.TTXTParser;	import org.flowplayer.controller.ResourceLoader;    import org.flowplayer.layout.LayoutEvent;import org.flowplayer.model.Clip;	import org.flowplayer.model.ClipEvent;	import org.flowplayer.model.DisplayPluginModel;    import org.flowplayer.model.DisplayProperties;import org.flowplayer.model.DisplayPropertiesImpl;import org.flowplayer.model.PlayerEvent;	import org.flowplayer.model.Plugin;	import org.flowplayer.model.PluginModel;	import org.flowplayer.util.PropertyBinder;	import org.flowplayer.view.AbstractSprite;	import org.flowplayer.view.FlowStyleSheet;	import org.flowplayer.view.Flowplayer;	import org.flowplayer.view.Styleable;		import flash.utils.clearInterval;	import flash.utils.setInterval;			/**	 * A Subtitling and Captioning Plugin. Supports the following:	 * <ul>	 * <li>Loading subtitles from the Timed Text or Subrip format files.</li>	 * <li>Styling text from styles set in the Time Text format files.</li>	 * <li>Loading subtitles or cuepoints from a JSON config.</li>	 * <li>Loading subtitles or cuepoints from embedded FLV cuepoints.</li>	 * <li>Controls an external content plugin.</li>	 * <li>Working with the Javascript captions plugin, it enables a scrolling cuepoint thumbnail menu.</li>	 * </ul>	 * <p>	 * To setup an external subtitle caption file the config would look like so:	 * 	 * captionType: 'external'	 * 	 * For Timed Text	 *	 * captionUrl: 'timedtext.xml'	 * 	 * For Subrip	 * 	 * captionUrl: 'subrip.srt'	 * 	 * <p>	 * To enable the captioning to work properly a caption target must link to a content plugin like so:	 * 	 * captionTarget: 'content'	 * 	 * Where content is the config for a loaded content plugin.	 *	 * <p>	 * 	 * To be able to customised the subtitle text a template string is able to tell the captioning plugin	 * which text property is to be used for the subtitle text which is important for embedded cuepoints. It also	 * enables to add extra properties to the text like so:	 * 	 * template: '{text} {time} {custom}' 	 * 	 * <p>	 * To enable simple formatting of text if Timed Text has style settings, 	 * only "fontStyle", "fontWeight" and "textAlign" properties are able to be set like so:	 * 	 * simpleFormatting: true	 * 	 * @author danielr	 */	public class Caption extends AbstractSprite implements Plugin, Styleable {		private var _captions:Array = new Array();		private var _player:Flowplayer;		private var _model:PluginModel;		private var _captionView:*;		private var _config:Config;		private var _styles:FlowStyleSheet;		private var _viewModel:DisplayPluginModel;		private var _captionInterval:int;		private var template:String;        private var _button:CCButton;				public function Caption() {				}				/**		 * Sets the plugin model. This gets called before the plugin		 * has been added to the display list and before the player is set.		 * @param plugin		 */		public function onConfig(plugin:PluginModel):void {			_model = plugin;			_config = new PropertyBinder(new Config(), null).copyProperties(plugin.config) as Config;			if (plugin.config) {				//log.debug("config object received with html " + plugin.config.html + ", stylesheet " + plugin.config.stylesheet);				_captions = _config.captions;							//	_html = plugin.config.html;			}		}				public function hasCaptionFile():Boolean		{			var clips:Array = _player.playlist.clips;			for (var i:Number = 0; i < clips.length; i++) {				var clip:Clip = clips[i] as Clip;				if (clip.customProperties && clip.customProperties["captionUrl"]) {					return true;				}			}			return false;		}				public function hasCaptions():Boolean		{			return _captions.length > 0;		}				/**		 * Sets the Flowplayer interface. The interface is immediately ready to use, all		 * other plugins have been loaded an initialized also.		 * @param player		 */		public function onLoad(player:Flowplayer):void {			_player = player;			_player.playlist.onCuepoint(onCuepoint);			_player.playlist.onBegin(onBegin);						if (! _config.captionTarget) {				throw Error("No captionTarget defined in the configuration");			}			_viewModel = _player.pluginRegistry.getPlugin(_config.captionTarget) as DisplayPluginModel;			_captionView = _viewModel.getDisplayObject();			_player.onLoad(onPlayerInitialized);									if (hasCaptionFile()) {				loadCaptionFiles();			} else {			    _model.dispatchOnLoad();			}		}		private function onPlayerInitialized(event:PlayerEvent):void {		    initCaptionView();            if (_config.button) {                _button = new CCButton(_player);                _player.addToPanel(_button, _config.button);                _button.addEventListener(MouseEvent.CLICK, function(event:MouseEvent):void {                    _player.togglePlugin(_config.captionTarget);                });            }		}        private function onPlayerResized(event:LayoutEvent):void {            log.debug("onPlayerResized");            _button.x = _captionView.x + _captionView.width + 3;            _button.y = _captionView.y;        }				private function loadCaptionFiles():void {			var clips:Array = _player.playlist.clips;			for (var i:Number = 0; i < clips.length; i++) {				var clip:Clip = _player.playlist.clips[i] as Clip;				var captionUrl:String = clip.customProperties ? clip.customProperties["captionUrl"] : null; 				if (captionUrl) {					loadCaptionFile(clip, captionUrl);				}			}		}		/**		 * Loads a new stylesheet and changes the style from the loaded sheet.		 */		 [External]		public function loadCaptions(clipIndex:int, captionURL:String):void {			if (! captionURL) return;			log.info("loading captions from "+ captionURL);			loadCaptionFile(_player.playlist.clips[clipIndex], captionURL);		}				/**		 * Sets style properties.		 */		public function css(styleProps:Object = null):Object {			var result:Object = _captionView.css(styleProps);			return result;		}		protected function loadCaptionFile(clip:Clip, captionFile:String = null):void {			var loader:ResourceLoader = _player.createLoader();			if (captionFile) {				log.info("loading captions from file " + captionFile);				loader.addTextResourceUrl(captionFile);			}					loader.load(null, function(loader:ResourceLoader):void {				parseCuePoints(clip, captionFile, loader.getContent(captionFile));			});		}				protected function parseCuePoints(clip:Clip, captionFile:String, captionData:*):void		{            log.debug("captions file loaded, parsing cuepoints");		   	_styles = _captionView.style;			try {				if (_captions.length > 0)				{					var json:JSONParser = new JSONParser();					json.styles = _styles;					clip.addCuepoints(json.parse(_captions));					_captionView.style = json.styles;				} else if (captionData && captionFile.substr(-3) == CaptionFileTypes.TTXT) {                    log.debug("parsing Timed Text captions");					var tt:TTXTParser = new TTXTParser();					tt.simpleFormatting = _config.simpleFormatting;	        		tt.styles = _styles;	        		clip.addCuepoints(tt.parse(XML(captionData)));	        		_captionView.style = tt.styles;				} else if (captionData && captionFile.substr(-3) == CaptionFileTypes.SRT) {                    log.debug("parsing SubRip captions");					var srt:SRTParser = new SRTParser();					srt.styles = _styles;					clip.addCuepoints(srt.parse(String(captionData)));					_captionView.style = _styles;				} else {                    throw new Error("Unrecognized captions file extension");                }			} catch (e:Error) {				log.error(e.message);			}				_model.dispatchOnLoad();		}				protected function onBegin(event:ClipEvent):void {			if (_config.showCaptions && _captionView) {				_player.animationEngine.fadeIn(_viewModel.getDisplayObject(),1000);			}		}				protected function parseTemplate(values:Object):String		{									for (var key:Object in values) {				if (typeof values[key] == 'object')				{						parseTemplate(values[key]);				} else {					template = template.replace("{" + key + "}", values[key]);				}			}			if (values.time >= 0) {				template = template.replace("{time}", values.time);			}						return template;		}				protected function clearCaption():void		{			if (_captionInterval == -1) return;			clearInterval(_captionInterval);			_captionInterval = -1;			_captionView.html = "";		}				protected function onCuepoint(event:ClipEvent):void {			log.debug("onCuepoint", event.info.parameters);						var clip:Clip = event.target as Clip;			var captionsDisabledForClip:Boolean = clip.customProperties && clip.customProperties.hasOwnProperty("showCaptions") && ! clip.customProperties["showCaptions"]; 			if (captionsDisabledForClip) {				return;			}						if (clip.customProperties && clip.customProperties.hasOwnProperty("captionUrl")) {				var cue:Object = event.info;				if (! cue.hasOwnProperty("captionType") || cue["captionType"] != "external") {					// we are using a captions file and this cuepoint is not from the file					return;				}			}						clearInterval(_captionInterval);			_captionInterval = -1;			template = _config.template;			var bgColor:String = (_captionView.style.getStyle("." + event.info.parameters.style).backgroundColor ? _captionView.style.getStyle("." + event.info.parameters.style).backgroundColor			: _captionView.style.rootStyle.backgroundColor);			_captionView.css({backgroundColor: bgColor});			_captionView.html = "<p class='"+event.info.parameters.style+"'>" + (template ? parseTemplate(event.info) : event.info.parameters.text) + "</p>";		    if (Number(event.info.parameters.end) > 0) _captionInterval = setInterval(clearCaption, Number(event.info.parameters.end));	    		}		protected function initCaptionView():void {						log.debug("creating content view");			if (_config.captionTarget)			{				log.info("Loading caption target plugin: " + _config.captionTarget);												if (_config.autoLayout)				{					_captionView.css(getDefaultConfig());				}			} else {				throw new Error("No caption target specified, please configure a Content plugin instance to be used as target");			}			_viewModel.alpha = 0;		}				public override function set alpha(value:Number):void {			super.alpha = value;			if (!_captionView) return;			_captionView.alpha = value;		}		public function getDefaultConfig():Object {			return { bottom: 25, width: '80%'};		}				public function animate(styleProps:Object):Object {			return _captionView.animate(styleProps);		}			}}