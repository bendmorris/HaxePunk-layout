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
	public var spacing:Measurement;

	public var layoutX:Measurement;
	public var layoutY:Measurement;
	public var layoutWidth:Measurement;
	public var layoutHeight:Measurement;

	public var layoutTop(default, set):Measurement;
	inline function get_layoutTop() return layoutY;
	inline function set_layoutTop(m:Measurement) { anchorY = 0; return layoutY = m; }

	public var layoutBottom(default, set):Measurement;
	inline function get_layoutBottom() return layoutY;
	inline function set_layoutBottom(m:Measurement) { anchorY = 1; return layoutY = m; }

	public var layoutLeft(default, set):Measurement;
	inline function get_layoutLeft() return layoutX;
	inline function set_layoutLeft(m:Measurement) { anchorX = 0; return layoutX = m; }

	public var layoutRight(default, set):Measurement;
	inline function get_layoutRight() return layoutX;
	inline function set_layoutRight(m:Measurement) { anchorX = 1; return layoutX = m; }

	public var layoutCenterX(default, set):Measurement;
	inline function get_layoutCenterX() return layoutX;
	inline function set_layoutCenterX(m:Measurement) { anchorX = 0.5; return layoutX = m; }

	public var layoutCenterY(default, set):Measurement;
	inline function get_layoutCenterY() return layoutX;
	inline function set_layoutCenterY(m:Measurement) { anchorY = 0.5; return layoutY = m; }

	var anchorX:Float = 0;
	var anchorY:Float = 0;

	/**
	 * Shortcut to set padding on all sides.
	 */
	public var padding(default, set):Measurement;
	inline function set_padding(m:Measurement)
	{
		return padding = paddingLeft = paddingRight = paddingTop = paddingBottom = m;
	}

	/**
	 * Shortcut to set horizontal padding.
	 */
	public var paddingX(default, set):Measurement;
	inline function set_paddingX(m:Measurement)
	{
		return paddingX = paddingLeft = paddingRight = m;
	}

	/**
	 * Shortcut to set vertical padding.
	 */
	public var paddingY(default, set):Measurement;
	inline function set_paddingY(m:Measurement)
	{
		return paddingY = paddingTop = paddingBottom = m;
	}

	public var paddingTop:Measurement;
	public var paddingBottom:Measurement;
	public var paddingLeft:Measurement;
	public var paddingRight:Measurement;

	public var wraps:Null<Entity>;
	/* If true, this LayoutGroup should fill available space. */
	public var stretch:Bool = false;

	/**
	 * @param	wraps			If provided, this LayoutGroup wraps this Entity
	 * @param	percentWidth	Percent of available width to fill. If this
	 * 							LayoutGroup has no parent, percent of screen width.
	 * @param	percentHeight	Percent of available height to fill. If this
	 * 							LayoutGroup has no parent, percent of screen height.
	 * @param	childLayoutType	How child entities should be arranged.
	 */
	public function new(
		?wraps:Entity,
		?childLayoutType:LayoutType=LayoutType.Stack,
		?width:Float=100,
		?widthUnit:MeasurementType=MeasurementType.Percent,
		?height:Float=100,
		?heightUnit:MeasurementType=MeasurementType.Percent
	)
	{
		super();

		layoutX = 0;
		layoutY = 0;
		layoutWidth = new Measurement(width, widthUnit);
		layoutHeight = new Measurement(height, heightUnit);
		spacing = 0;
		paddingTop = paddingBottom = paddingLeft = paddingRight = 0;

		this.wraps = wraps;
		this.childLayoutType = childLayoutType;

		if (wraps != null) super.add(wraps);
	}

	/**
	 * Position all children. If any children are LayoutGroups, their children
	 * will also be positioned.
	 */
	public function layoutChildren(?parentWidth:Float, ?parentHeight:Float):Void
	{
		if (parentWidth == null || parentHeight == null)
		{
			// initial layout fills entire screen
			parentWidth = HXP.width;
			parentHeight = HXP.height;
		}

		var childrenWidth:Float = 0;
		var childrenHeight:Float = 0;
		var maxRowHeight:Float = 0;

		var paddingLeft:Float = paddingLeft.measure(parentWidth),
			paddingRight:Float = paddingRight.measure(parentWidth),
			paddingTop:Float = paddingTop.measure(parentHeight),
			paddingBottom:Float = paddingBottom.measure(parentHeight);

		for (member in entities)
		{
			if (Std.is(member, LayoutGroup))
			{
				var layout:LayoutGroup = cast member;
				member.localX = 0;
				member.localY = 0;
				layout.layoutChildren(
					parentWidth - paddingLeft - paddingRight,
					parentHeight - paddingTop - paddingBottom
				);
				member.localX += paddingLeft;
				member.localY += paddingTop;
			}
			else
			{
				member.localX = paddingLeft;
				member.localY = paddingTop;
			}

			switch (childLayoutType)
			{
				case Stack:
					childrenWidth = Math.max(childrenWidth, member.localX + member.width + paddingRight);
					childrenHeight = Math.max(childrenHeight, member.localY + member.height + paddingBottom);

				case Horizontal:
					member.x += childrenWidth;
					childrenWidth += spacing.measure(parentWidth) + member.width;
					childrenHeight = Math.max(childrenHeight, member.height);

				case Vertical:
					member.y += childrenHeight;
					childrenHeight += spacing.measure(parentHeight) + member.height;
					childrenWidth = Math.max(childrenWidth, member.width);

				case Grid:
					if (childrenWidth + member.width > width - paddingLeft - paddingRight)
					{
						// move to the next row
						childrenWidth = 0;
						childrenHeight += spacing.measure(parentWidth) + maxRowHeight;
						maxRowHeight = 0;
					}
					member.x += childrenWidth;
					member.y += childrenHeight;
					childrenWidth += spacing.measure(parentWidth) + member.width;
					maxRowHeight = Math.max(maxRowHeight, member.height);

				default: {}
			}
		}

		if (childLayoutType == Stack)
		{
			width = Std.int(parentWidth);
			height = Std.int(parentHeight);
		}
		else
		{
			width = Std.int(childrenWidth);
			height = Std.int(childrenHeight);
		}
		if (wraps != null && stretch)
		{
			wraps.width = width;
			wraps.height = height;
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
