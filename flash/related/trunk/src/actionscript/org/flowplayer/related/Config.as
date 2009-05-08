/*
 * This file is part of Flowplayer, http://flowplayer.org
 *
 * By: Daniel Rossi, <electroteque@gmail.com>
 * Copyright (c) 2009 Electroteque Multimedia
 *
 * Released under the MIT License:
 * http://www.opensource.org/licenses/mit-license.php
 */
 
package org.flowplayer.related
{
	public class Config {
		
		// max amount of visible items
		private var _items:int = 4;
		
		/*
			by default related videos are shown on clip's onFinish event
			specifying false here this does not happen and user can open
			related videos programmatically using the API
		*/
		private var _showOnFinish:Boolean = true;
		
		/*
			default URL for fetching videos, can be overridden on a clip.
			all clip properties can be used in generating query string
				
			all clips (including related clips) fetch related videos from this URL. 
			if no  related clips are returned then related videos are not shown
		*/
		private var _related:String;
		
		/*
			by default these clip properties are used in rendering items: 
			[thumbnail, title, duration],  but these can be tweaked with 
			following configuration properties
		*/
		// name of the image property on a clip
		private var _image:String = 'thumbnail';
		
		// name of a title property
		private var _title:String = 'title';
		
		// optional subtitle 
		private var _subTitle:String;
		
		// by default video URL is not shown
		private var _showUrl:Boolean = false;
		
		// screen display properties when plugin is shown
		private var _screen:Object;
		
		/*
			position, size and opacity when plugin is shown
			all display properties are supported (provide good defaults)
		*/
			
		private var _bottom:int = 10;
		private var _left:int = 10;
		private var _height:int = 100;
		
		
		public function get items():int {
			return _items;
		}
		
		public function set items(items:int):void {
			_items = items;
		}
		
		public function get showOnFinish():Boolean {
			return _showOnFinish;
		}
		
		public function set showOnFinish(showOnFinish:Boolean):void {
			_showOnFinish = showOnFinish;
		}
		
		public function get related():String {
			return _related;
		}
		
		public function set related(related:String):void {
			_related = related;
		}
		
		public function get image():String {
			return _image;
		}
		
		public function set image(image:String):void {
			_image = image;
		}
		
		public function get title():String {
			return _title;
		}
		
		public function set title(title:String):void {
			_title = title;
		}
		
		public function get subTitle():String {
			return _subTitle;
		}
		
		public function set subTitle(subTitle:String):void {
			_subTitle = subTitle;
		}
		
		public function get showUrl():Boolean {
			return _showUrl;
		}
		
		public function set showUrl(showUrl:Boolean):void {
			_showUrl = showUrl;
		}
		
		public function get screen():Object {
			return _screen;
		}
		
		public function set screen(screen:Object):void {
			_screen = screen;
		}
		
		public function get bottom():int {
			return _bottom;
		}
		
		public function set bottom(bottom:int):void {
			_bottom = bottom;
		}
		
		public function get left():int {
			return _left;
		}
		
		public function set left(left:int):void {
			_left = left;
		}
		
		public function get height():int {
			return _height;
		}
		
		public function set height(height:int):void {
			_height = height;
		}
		
		
		
	}
}


