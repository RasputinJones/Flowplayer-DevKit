/*
 * This file is part of Flowplayer, http://flowplayer.org
 *
 * By: Anssi Piirainen, <support@flowplayer.org>
 * Copyright (c) 2009 Flowplayer Ltd
 *
 * Released under the MIT License:
 * http://www.opensource.org/licenses/mit-license.php
 */

package org.flowplayer.rtmp {
    import flash.events.NetStatusEvent;
    import flash.net.NetConnection;

    import org.flowplayer.util.Log;

    public class Connector {
        private var log:Log = new Log(this); 
        private var _url:String;
        private var _successListener:Function;
        private var _connectionClient:Object;
        private var _connection:NetConnection;
        private var _failureListener:Function;

        public function Connector(url:String, connectionClient:Object, onSuccess:Function, onFailure:Function) {
            _url = url;
            _connectionClient = connectionClient;
            _successListener = onSuccess;
            _failureListener = onFailure;
        }

        public function connect(objectEncoding:uint, ... rest):void {
            log.debug(this +"::connect()");
            _connection = new NetConnection();
            _connection.proxyType = "best";
            _connection.objectEncoding = objectEncoding;

            if (_connectionClient) {
                _connection.client = _connectionClient;
            }
            _connection.addEventListener(NetStatusEvent.NET_STATUS, onConnectionStatus);

            log.debug("netConnectionUrl is " + _url);
            if (rest.length > 0) {
                _connection.connect(_url, rest);
            } else {
                _connection.connect(_url);
            }
        }

        private function onConnectionStatus(event:NetStatusEvent):void {
            log.debug(this + "::onConnectionStatus() " + event.info.code);

            if (event.info.code == "NetConnection.Connect.Success") {
                if (_successListener != null) {
                    _successListener(this, _connection);
                } else {
                    log.debug("this connector is stopped, will not call successListener");
                }

            } else if (["NetConnection.Connect.Failed", "NetConnection.Connect.Rejected", "NetConnection.Connect.AppShutdown", "NetConnection.Connect.InvalidApp"].indexOf(event.info.code) >= 0) {
                if (_failureListener != null) {
                    _failureListener();
                }
            }
        }

        public function stop():void {
            log.debug("stop()");
            _connection.close();
            _successListener = null;
        }

        public function toString():String {
            return "Connector, [" + _url + "]";
        }
    }
}