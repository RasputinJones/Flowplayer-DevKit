/**
 * flowplayer.playlist 3.0.7. Flowplayer JavaScript plugin.
 * 
 * This file is part of Flowplayer, http://flowplayer.org
 *
 * Author: Tero Piirainen, <info@flowplayer.org>
 * Copyright (c) 2008 Flowplayer Ltd
 *
 * Dual licensed under MIT and GPL 2+ licenses
 * SEE: http://www.opensource.org/licenses
 * 
 * Date: 2009-02-16 06:51:28 -0500 (Mon, 16 Feb 2009)
 * Revision: 1454 
 */ 
(function($) {
	
	$f.addPlugin("bwcheck", function(container, options) {


		// self points to current Player instance
		var self = this;	
	
		
		var opts = {
			selectedBitrateClass: 'bitrate-selected',
			activeClass: 'bitrate-active',
			bitrateInfoClass:'bitrate-info',
			disabledClass: 'bitrate-disabled',
			bwCheckPlugin: 'bwcheck',
			template: '<a href="${bitrate}">${bitrate} k</a>',
			disabledText: '(not valid with this player size )',
			fadeTime: 500,
			seperator: ""
		};		
		
		$.extend(opts, options);
		
		var wrap = container;
		

		
		var template = null;
		var labels = null;
		var plugin = self.getPlugin(opts.bwCheckPlugin) || null;
		
		
		var els = null;
		
		
//{{{ "private" functions
				
		function parseTemplate(values) {
			var el = template; 
	
			$.each(values, function(key, val) {	
				if (key=="bitrate" && labels) {
					var label = (plugin && labels.length > 0 && labels[val] ? labels[val] : val + " k");
					if (label) {
						el = el.replace("$\{label\}", label).replace("$%7B" +key+ "%7D", label);
					}
				}
				el = el.replace("$\{" +key+ "\}", val).replace("$%7B" +key+ "%7D", val);			
			}); 
			
			return el;
		}
		

		function buildBitrateList() {
			wrap.fadeOut(opts.fadeTime).empty();
		
			
			labels = plugin.getLabels();
			var widthCheck = (plugin.getSelectionStrategy() == "default");
			var containerWidth = $("#" + self.id()).width();
			
			
			var index = 0;
			$.each(self.getClip().bitrates, function() { 
				var el = parseTemplate(this);
				el = $(el);	
				el.attr("index",this.bitrate);
		
				
				
				if (this.width > containerWidth && widthCheck) {
					
					
					if (el.is('a')) {
						el.removeAttr("href");
						el.addClass(opts.disabledClass);
					}
					
					if (el.is('input')) {
						el.attr("disabled");
						el.addClass(opts.disabledClass);
					}
					el.find('a').removeAttr("href").addClass(opts.disabledClass);
					el.find('input').attr("disabled",true).addClass(opts.disabledClass);
			
					wrap.append(el);
					wrap.append(" " + opts.disabledText + " ");
				} else {
					el.addClass(opts.activeClass);
					el.click(function() {	
						el.removeClass(opts.activeClass);
						
						wrap.children().removeClass(opts.selectedBitrateClass).addClass(opts.activeClass);
						el.addClass(opts.selectedBitrateClass);
						play($(this).attr("index"));
						if ($(this).is('a')) return false;
					});
					wrap.append(el);
				}
				
				if (index < self.getClip().bitrates.length - 1) wrap.append(opts.seperator);
				index++;
			});				
			
			
			
			//if the parent div wrapper is set to display:none fade in the parent
			if (wrap.parent().css('display') == "none") {
				wrap.show();
				wrap.parent('div').fadeIn(opts.fadeTime);
			} else {
				wrap.fadeIn(opts.fadeTime);
			}
		} 

		function play(bitrate)  {
			if (!plugin) return false;
			
			plugin.setBitrate(bitrate);
		
			return false;
		}	
		
		
		function clearCSS() {
			els.removeClass(opts.bitrateClass);
			els.removeClass(opts.selectedBitrateClass);
			els.removeClass(opts.bitrateInfoClass);			
		}
		

//}}}  
		
		 
		/* setup playlists with onClick handlers */ 
		
		// internal playlist
		function showBitrateList() {
	
			wrap = $(wrap);
			if (self.getClip().bitrates.length > 0) {
				
				template = wrap.is(":empty") ? opts.template : wrap.html(); 
				
				
				
				buildBitrateList();			

			} 
		}
		
		function setupEvents() {
			  if (plugin) {
				 plugin.onStreamSwitch(function(mappedBitrate, streamName, oldStreamName) {
					 //getEl(mappedBitrate.bitrate).removeClass(opts.bitrateClass);
					 //getEl(mappedBitrate.bitrate).addClass(opts.selectedBitrateClass);
					 alert("yes");
			 	 });
		
			 	 plugin.onBwDone(function(mappedBitrate, detectedBitrate) {
			 		//getEl(mappedBitrate.bitrate).removeClass(opts.bitrateClass);
					//getEl(mappedBitrate.bitrate).addClass(opts.selectedBitrateClass);
			 		 alert("yes");
			 		//wrap.filter("[index=" + mappedBitrate.bitrate + "]").hide();
			 	 });
			 
			  }
		}
		
		
		// onBeforeBeginBegin
		self.onBeforeBegin(function(clip) {
			showBitrateList();
			setupEvents();
		});	
		
		
		
		// onUnload
		self.onUnload(function() {
			//clearCSS();		
		});
		
		
		// onClipAdd
		self.onClipAdd(function(clip, index) {	
			//els.eq(index).before(toString(clip));			
			//bindClicks(); 
		});		
		
		return self;
		
	});
		
})(jQuery);		