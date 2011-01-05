/* * This file is part of Flowplayer, http://flowplayer.org * * By: Daniel Rossi, <electroteque@gmail.com>, Anssi Piirainen Flowplayer Oy * Copyright (c) 2009 Electroteque Multimedia, Flowplayer Oy * * Released under the MIT License: * http://www.opensource.org/licenses/mit-license.php */package org.flowplayer.bwcheck.config {    import flash.system.Capabilities;    import org.flowplayer.model.DisplayProperties;    import org.flowplayer.model.DisplayPropertiesImpl;    import org.flowplayer.util.PropertyBinder;    import org.flowplayer.ui.AutoHideConfig;    import org.flowplayer.ui.ButtonConfig;    import org.flowplayer.ui.DockConfig;    import org.flowplayer.cluster.ClusterConfig;    import org.flowplayer.bwcheck.BitrateItem;    public class Config extends ClusterConfig {        private var _switchOnFullscreen:Boolean = true;        private var _maxWidth:Number = -1;        private var _rememberBitrate:Boolean = false;        private var _bitrateProfileName:String = "bitrateProfile";        private var _dynamicBuffer:Boolean = false;        private var _dynamic:Boolean = false;        private var _cacheExpiry:Number = 24 * 60 * 60;        private var _checkOnStart:Object = null;        private var _qos:QosRulesConfig = new QosRulesConfig();        private var _live:Boolean = false;        private var _hdIcon:Boolean = true;                private var _dock:DockConfig = new DockConfig();        private var _icons:IconConfig = new IconConfig();        public function set switchOnFullscreen(value:Boolean):void {            _switchOnFullscreen = value;        }        public function get switchOnFullscreen():Boolean {            return _switchOnFullscreen;        }        public function get maxWidth():Number {            return _maxWidth;        }        public function set maxWidth(width:Number):void {            _maxWidth = width;        }        public function set rememberBitrate(value:Boolean):void {            _rememberBitrate = value;        }        public function get rememberBitrate():Boolean {            return _rememberBitrate;        }        public function set dynamic(value:Boolean):void {            _dynamic = value;        }        public function get dynamic():Boolean {            return Capabilities.version.split(' ')[1].split(",")[0] >= 10 && _dynamic;        }        public function set bitrateProfileName(value:String):void {            _bitrateProfileName = value;        }        public function get bitrateProfileName():String {            return _bitrateProfileName;        }        public function set dynamicBuffer(value:Boolean):void {            _dynamicBuffer = value;        }        public function get dynamicBuffer():Boolean {            return _dynamicBuffer;        }        public function get cacheExpiry():Number {            return _cacheExpiry;        }        public function set cacheExpiry(value:Number):void {            _cacheExpiry = value;        }        public function get checkOnStart():Boolean {            if (_checkOnStart != null) return _checkOnStart as Boolean;            return ! dynamic;        }        public function set checkOnStart(value:Boolean):void {            _checkOnStart = value;        }        public function setQos(value:Object):void {            new PropertyBinder(_qos).copyProperties(value);        }        public function get qos():QosRulesConfig {            return _qos;        }        public function get live():Boolean {            return _live;        }        public function set hdIcon(value:Boolean):void {            _hdIcon = value;        }                public function get hdIcon():Boolean {            return _hdIcon;        }        public function set live(value:Boolean):void {            _live = value;        }                public function set icons(config:Object):void {            new PropertyBinder(_icons.buttons).copyProperties(config);        }                public function get iconConfig():ButtonConfig {            return _icons.buttons;        }                public function set dock(config:Object):void {            new PropertyBinder(_dock.displayProperties).copyProperties(config);        }                public function get dockConfig():DockConfig {            return _dock;        }    }}