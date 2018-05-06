package haxepunk.layout;

import haxepunk.HXP;
import haxepunk.Entity;
import haxepunk.EntityList;

/**
 * An EntityList which can reposition its entities on resize.
 */
class LayoutGroup extends EntityList<Entity>
{
	public var childLayoutType:LayoutType = LayoutType.Stack;
	/* Amount of spacing between children. Used for Horizontal/Vertical/Grid. */
	public var spacing:MeasurementRange;

	public var layoutX:MeasurementRange;
	public var layoutY:MeasurementRange;
	public var layoutWidth:Null<MeasurementRange> = null;
	public var layoutHeight:Null<MeasurementRange>;

	public var layoutTop(default, set):MeasurementRange;
	inline function set_layoutTop(m:MeasurementRange) { anchorY = 0; return layoutY = m; }

	public var layoutBottom(default, set):MeasurementRange;
	inline function set_layoutBottom(m:MeasurementRange) { anchorY = 1; return layoutY = m; }

	public var layoutLeft(default, set):MeasurementRange;
	inline function set_layoutLeft(m:MeasurementRange) { anchorX = 0; return layoutX = m; }

	public var layoutRight(default, set):MeasurementRange;
	inline function set_layoutRight(m:MeasurementRange) { anchorX = 1; return layoutX = m; }

	public var layoutCenterX(default, set):MeasurementRange;
	inline function set_layoutCenterX(m:MeasurementRange) { anchorX = 0.5; return layoutX = m; }

	public var layoutCenterY(default, set):MeasurementRange;
	inline function set_layoutCenterY(m:MeasurementRange) { anchorY = 0.5; return layoutY = m; }

	var anchorX:Float = 0;
	var anchorY:Float = 0;

	/**
	 * Shortcut to set padding on all sides.
	 */
	public var padding(default, set):MeasurementRange;
	inline function set_padding(m:MeasurementRange)
	{
		return padding = paddingLeft = paddingRight = paddingTop = paddingBottom = m;
	}

	/**
	 * Shortcut to set horizontal padding.
	 */
	public var paddingX(default, set):MeasurementRange;
	inline function set_paddingX(m:MeasurementRange)
	{
		return paddingX = paddingLeft = paddingRight = m;
	}

	/**
	 * Shortcut to set vertical padding.
	 */
	public var paddingY(default, set):MeasurementRange;
	inline function set_paddingY(m:MeasurementRange)
	{
		return paddingY = paddingTop = paddingBottom = m;
	}

	public var paddingTop:MeasurementRange;
	public var paddingBottom:MeasurementRange;
	public var paddingLeft:MeasurementRange;
	public var paddingRight:MeasurementRange;

	/**
	 * If this LayoutGroup wraps another Entity and has a width/height set,
	 * the wrapped entity will be resized. Otherwise, this LayoutGroup will
	 * be resized to the wrapped entity's size.
	 */
	public var wraps:Null<Entity>;

	/**
	 * @param	wraps			If provided, this LayoutGroup wraps this Entity
	 * @param	childLayoutType	How child entities should be arranged.
	 * @param	width			Amount of available width to fill.
	 * @param	height			Amount of available height to fill.
	 */
	public function new(
		?wraps:Entity,
		?childLayoutType:LayoutType=LayoutType.Stack,
		?width:Measurement,
		?height:Measurement
	)
	{
		super();

		layoutX = layoutY = 0;
		layoutWidth = width;
		layoutHeight = height;
		paddingTop = paddingBottom = paddingLeft = paddingRight = 0;
		spacing = 0;

		this.wraps = wraps;
		this.childLayoutType = childLayoutType;

		if (wraps != null) super.add(wraps);
	}

	public function addLayout(e:Entity):LayoutGroup
	{
		var wrapper = new LayoutGroup(e);
		add(wrapper);
		return wrapper;
	}

	/**
	 * Position all children. If any children are LayoutGroups, their children
	 * will also be positioned.
	 */
	public function layoutChildren(?parentWidth:Float, ?parentHeight:Float):Void
	{
		// initial layout fills entire screen
		if (parentWidth == null) parentWidth = HXP.width * scene.width / HXP.screen.width;
		if (parentHeight == null) parentHeight = HXP.height * scene.height / HXP.screen.height;

		// measure padding and available space for children
		var paddingLeft = paddingLeft.measure(parentWidth),
			paddingRight = paddingRight.measure(parentWidth),
			paddingTop = paddingTop.measure(parentHeight),
			paddingBottom = paddingBottom.measure(parentHeight);
		var availableWidth = parentWidth - paddingLeft - paddingRight,
			availableHeight = parentHeight - paddingTop - paddingBottom;
		// if we explicitly set width or height, respect that
		if (layoutWidth != null)
		{
			width = Std.int(layoutWidth.measure(parentWidth));
			paddingLeft = this.paddingLeft.measure(width);
			paddingRight = this.paddingRight.measure(width);
			availableWidth = width - paddingLeft - paddingRight;
			if (wraps != null) wraps.width = Std.int(availableWidth);
		}
		if (layoutHeight != null)
		{
			height = Std.int(layoutHeight.measure(parentHeight));
			paddingTop = this.paddingTop.measure(height);
			paddingBottom = this.paddingBottom.measure(height);
			availableHeight = height - paddingTop - paddingBottom;
			if (wraps != null) wraps.height = Std.int(availableHeight);
		}
		if (width < 0) width = 0;
		if (height < 0) height = 0;

		var childrenWidth:Float = 0;
		var childrenHeight:Float = 0;
		var maxRowHeight:Float = 0;

		var cursorX:Float = 0,
			cursorY:Float = 0;

		for (member in entities)
		{
			inline function layoutChild()
			{
				if (Std.is(member, LayoutGroup))
				{
					var layout:LayoutGroup = cast member;
					member.localX = 0;
					member.localY = 0;
					layout.layoutChildren(
						availableWidth,
						availableHeight
					);
					member.localX += paddingLeft;
					member.localY += paddingTop;
				}
				else
				{
					member.localX = paddingLeft;
					member.localY = paddingTop;
				}
			}

			switch (childLayoutType)
			{
				case Stack:
					layoutChild();
					childrenWidth = Math.max(childrenWidth, member.localX + member.width + paddingRight);
					childrenHeight = Math.max(childrenHeight, member.localY + member.height + paddingBottom);

				case Horizontal:
					availableWidth -= childrenWidth;
					layoutChild();
					member.x += childrenWidth;
					childrenWidth += spacing.measure(parentWidth) + member.width;
					childrenHeight = Math.max(childrenHeight, member.height);

				case Vertical:
					availableHeight -= childrenHeight;
					layoutChild();
					member.y += childrenHeight;
					childrenHeight += spacing.measure(parentHeight) + member.height;
					childrenWidth = Math.max(childrenWidth, member.width);

				case Grid:
					availableWidth -= cursorY;
					availableHeight -= cursorX;
					layoutChild();
					if (cursorX + member.width > width - paddingLeft - paddingRight)
					{
						// move to the next row
						cursorX = 0;
						cursorY += spacing.measure(parentWidth) + maxRowHeight;
						maxRowHeight = 0;
					}
					member.x += cursorX;
					member.y += cursorY;
					cursorX += spacing.measure(parentWidth) + member.width;
					maxRowHeight = Math.max(maxRowHeight, member.height);
					childrenWidth = Math.max(childrenWidth, cursorX);
					childrenHeight = Math.max(childrenHeight, cursorY);

				default: {}
			}
		}

		if (wraps != null)
		{
			// if we wrap something
			if (layoutWidth == null) width = wraps.width;
			if (layoutHeight == null) height = wraps.height;
		}
		else
		{
			// if no explicit width or height and nothing wrapped,
			// set dimensions based on children
			if (layoutWidth == null) width = Std.int(childrenWidth);
			if (layoutHeight == null) height = Std.int(childrenHeight);
		}

		localX = layoutX.measure(parentWidth) - width * anchorX;
		localY = layoutY.measure(parentHeight) - height * anchorY;
	}

	override public function added()
	{
		super.added();
		if (parent == null) layoutChildren();
	}

	override public function resized()
	{
		if (parent == null) layoutChildren();
	}

	override function get_width() return this.width;
	override function set_width(value:Int) return this.width = value;
	override function get_height() return this.height;
	override function set_height(value:Int) return this.height = value;
}
