package haxepunk.layout;

typedef BoundsData =
{
	var value:Measurement;
	var min:Null<Measurement>;
	var max:Null<Measurement>;
}

/**
 * A measurement with optional range of acceptable values.
 */
@:forward(value, min, max)
abstract MeasurementRange(BoundsData)
{
	@:from public static inline function fromMeasurement(m:Measurement):MeasurementRange
	{
		if (m == null) return null;
		else return new MeasurementRange(m);
	}
	@:from public static inline function fromFloat(f:Float):MeasurementRange return new MeasurementRange(f);

	public inline function new(val:Measurement, ?min:Measurement, ?max:Measurement)
	{
		this = {value: val, min: min, max: max};
	}

	public inline function measure(?maxValue:Float=100):Float
	{
		var val = this.value.measure(maxValue);
		if (this.min != null) val = Math.max(this.min.measure(maxValue), val);
		if (this.max != null) val = Math.min(this.max.measure(maxValue), val);
		return val;
	}
}
