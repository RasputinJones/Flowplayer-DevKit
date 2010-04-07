/*
 * This file is part of Flowplayer, http://flowplayer.org
 *
 * By: Daniel Rossi, <electroteque@gmail.com>
 * Copyright (c) 2009 Electroteque Multimedia
 *
 * Released under the MIT License:
 * http://www.opensource.org/licenses/mit-license.php
 */
package org.flowplayer.shareembed {
    import flash.events.MouseEvent;
    import flash.text.AntiAliasType;
    import flash.text.TextField;

    import org.flowplayer.model.DisplayPluginModel;
    import org.flowplayer.util.Arrange;
    import org.flowplayer.view.Flowplayer;
    import org.flowplayer.view.StyleableSprite;

    /**
     * @author danielr
     */
    internal class Tab extends StyleableSprite {

        private var _player:Flowplayer;
        private var _plugin:DisplayPluginModel;
        public var _field:TextField
        private var _text:String;

        public function Tab(plugin:DisplayPluginModel, player:Flowplayer, text:String, style:Object) {
            super("viral-tab", player, player.createLoader());
            rootStyle = style;

            _plugin = plugin;
            _player = player;
            _text = text;
            createTextField(text);
            this.addEventListener(MouseEvent.CLICK, onThisClicked);
        }

        override protected function onResize():void {
            _field.width = _field.textWidth + 5;
            _field.height = _field.textHeight + 3;
            Arrange.center(_field, width);
            _field.y = 5;
        }

        public function get html():String {
            return _text;
        }

        private function createTextField(htmlText:String):void {
            log.debug("creating text field for text " + htmlText);
            if (_field) {
                removeChild(_field);
            }

            _field = _player.createTextField(10);
            _field.htmlText = htmlText;
            _field.selectable = false;
            _field.height = 20;
            _field.x = 5;

            _field.antiAliasType = AntiAliasType.ADVANCED;
            addChild(_field);
        }

        public function onThisClicked(event:MouseEvent):void {
            ShareEmbed(_plugin.getDisplayObject()).setActiveTab(html);
        }

        public function closePanel():void {
            _player.animationEngine.fadeOut(this, 0, closePanel2);
        }

        public function closePanel2():void {
            ShareEmbed(_plugin.getDisplayObject()).removeChild(this);
        }

    }
}