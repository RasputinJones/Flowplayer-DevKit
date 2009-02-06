/* * This file is part of Flowplayer, http://flowplayer.org * * By: Anssi Piirainen, <support@flowplayer.org> *Copyright (c) 2008, 2009 Flowplayer Oy * * Released under the MIT License: * http://www.opensource.org/licenses/mit-license.php */package org.flowplayer.controls {	import org.flowplayer.util.Log;	
	
	import com.adobe.utils.StringUtil;			/**	 * @author api	 */	public class Style {		private var log:Log = new Log(this);
		// this holds style properties used by the StyleableSprite class (superclass of our Controls class)		private var _bgStyle:Object;				private var _style:Object = new Object();				public function addStyleProps(obj:Object):Object {			for (var propName:String in _style) {				obj[propName] = _style[propName];			}			return obj;		}		public function set bgStyle(styleObj:Object):void {			log.debug("setting bgStyle");			_bgStyle = styleObj;		}		public function get bgStyle():Object {			log.debug("getting bgStyle");			return _bgStyle;		}		public function get durationColor():Number {			return decodeColor(_style["durationColor"]);		}		public function setDurationColor(color:String):void {			_style["durationColor"] = color;		}		// setters are not accessors, because they have different parameter type		public function setTimeColor(color:String):void {			_style["timeColor"] = color;		}				public function get timeColor():Number {			return decodeColor(_style["timeColor"]);		}				public function get bufferColor():Number {			return decodeColor(_style["bufferColor"]);		}				public function setBufferColor(color:String):void {			_style["bufferColor"] = color;		}				public function setBufferGradient(gradient:String):void {			_style["bufferGradient"] = gradient;		}				public function get bufferGradient():Array {			return decodeGradient(_style["bufferGradient"]);		}				public function get buttonColor():Number {			return decodeColor(_style["buttonColor"]);		}				public function get buttonColorRGB():Array {			return toRgb(buttonColor);		}				public function setButtonColor(color:String):void {			_style["buttonColor"] = color;		}				public function setButtonOverColor(button:String):void {			_style["buttonOverColor"] = button;		}				public function get buttonOverColor():Number {			return decodeColor(_style["buttonOverColor"]);		}				public function get buttonOverColorRGB():Array {			return toRgb(buttonOverColor);		}				public function get sliderColor():Number {			return decodeColor(_style["sliderColor"]);		}				public function get sliderGradient():Array {			return decodeGradient(_style["sliderGradient"]);		}				public function setSliderColor(color:String):void {			_style["sliderColor"] = color;		}				public function setSliderGradient(gradient:String):void {			_style["sliderGradient"] = gradient;		}				public function get progressColor():Number {			return decodeColor(_style["progressColor"]);		}				public function setProgressColor(color:String):void {			_style["progressColor"] = color;		}				public function get tooltipColor():Number {			return decodeColor(_style["tooltipColor"]);		}				public function setTooltipColor(color:String):void {			_style["tooltipColor"] = color;		}				public function get tooltipTextColor():Number {			return decodeColor(_style["tooltipTextColor"]);		}				public function setTooltipTextColor(color:String):void {			_style["tooltipTextColor"] = color;		}				public function setProgressGradient(gradient:String):void {			_style["progressGradient"] = gradient;		}				public function get progressGradient():Array {			return decodeGradient(_style["progressGradient"]);		}				private function decodeGradient(value:Object, defVal:String = "medium"):Array {			if (! value) return decodeGradient(defVal);			if (value is Array) return value as Array;			if (value == "none") return null;			if (value == "high") return [.1, 0.5, .1];			if (value == "medium") return [0, .25, 0];			return decodeGradient(defVal);		}				private function decodeColor(color:Object, defVal:Number = 0xffffff):Number {			if (! color) return defVal;			if (color is Number) return color as Number;			if (color is String) {				var colorStr:String = StringUtil.trim(color as String);				if (colorStr.indexOf("#") == 0) {					return parseInt("0x" + colorStr.substr(1));				}				if (colorStr.indexOf("0x") == 0) {					return parseInt(colorStr);				}				if (colorStr == "transparent") {					return -1;				}			}			return defVal;		}				private function toRgb(color:Number):Array {			return [ (color >> 16) & 0xFF, (color >> 8) & 0xFF, color & 0xFF ];		}	}}