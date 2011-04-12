/*****************************************************************************
 *
 * NagVisShape.js - This class handles the visualisation of shape objects
 *
 * Copyright (c) 2004-2011 NagVis Project (Contact: info@nagvis.org)
 *
 * License:
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 *****************************************************************************/
 
/**
 * @author	Lars Michelsen <lars@vertical-visions.de>
 */


var NagVisShape = NagVisStatelessObject.extend({
	constructor: function(oConf) {
		// Call parent constructor;
		this.base(oConf);
	},
	
	/**
	 * PUBLIC parse()
	 *
	 * Parses the object
	 *
	 * @return	String		HTML code of the object
	 * @author	Lars Michelsen <lars@vertical-visions.de>
	 */
	parse: function () {
		var oContainerDiv;
		
		// Create container div
		oContainerDiv = document.createElement('div');
		oContainerDiv.setAttribute('id', this.conf.object_id);
		oContainerDiv.appendChild(this.parseShape());
		
		// When this is an update, remove the object first
		this.remove();
		
		var oMap = document.getElementById('map');
		if(oMap) {
			this.parsedObject = oMap.appendChild(oContainerDiv);
			oMap = null;
		}
		
		oContainerDiv = null;

		// Enable the controls when the object is not locked
		if(!this.bIsLocked)
			this.parseControls();
	},
	
	/**
	 * Parses the shape
	 *
	 * @return	String	String with Html Code
	 * @author	Lars Michelsen <lars@vertical-visions.de>
	 */
	parseShape: function () {
		var oIconDiv = document.createElement('div');
		oIconDiv.setAttribute('id', this.conf.object_id+'-icondiv');
		oIconDiv.setAttribute('class', 'icon');
		oIconDiv.setAttribute('className', 'icon');
		oIconDiv.style.top = this.conf.y+'px';
		oIconDiv.style.left = this.conf.x+'px';
		oIconDiv.style.zIndex = this.conf.z;
		
		var oIcon = document.createElement('img');
		oIcon.setAttribute('id', this.conf.object_id+'-icon');

		// Extract external URLs
		if(this.conf.icon.match(/^\[(.*)\]$/))
			this.conf.icon = this.conf.icon.replace(/^\[(.*)\]$/, '$1');
		else
			this.conf.icon = oGeneralProperties.path_shapes + this.conf.icon;
		
		if(this.conf.icon.indexOf('?') !== -1) {
			oIcon.src = this.conf.icon+'&_t='+iNow;
		} else {
			oIcon.src = this.conf.icon+'?_t='+iNow;
		}
		
		oIcon.alt = this.conf.type;
		
		if(this.conf.url && this.conf.url !== '') {
			var oIconLink = document.createElement('a');
			oIconLink.href = this.conf.url;
			oIconLink.target = this.conf.url_target;
			oIconLink.appendChild(oIcon);
			oIcon = null;
			
			oIconDiv.appendChild(oIconLink);
			oIconLink = null;
		} else {
			oIconDiv.appendChild(oIcon);
			oIcon = null;
		}
		
		return oIconDiv;
	},
	
	parseHoverMenu: function () {
		this.getHoverMenu(this.conf.object_id+'-icon');
	},

	parseShapeControls: function () {
	    this.parseControlDrag(0,   this.parseCoord(this.conf.x, 'x'), this.parseCoord(this.conf.y, 'y'),  5, -15, 10);
	    this.parseControlDelete(1, this.parseCoord(this.conf.x, 'x'), this.parseCoord(this.conf.y, 'y'), 20, -15, 10);
	    this.parseControlModify(2, this.parseCoord(this.conf.x, 'x'), this.parseCoord(this.conf.y, 'y'), 35, -15, 10);

	    // Simply make it dragable. Maybe will be extended in the future...
	    makeDragable([this.conf.object_id+'-drag-0'], this.saveObject, this.moveObject);
	}
});
