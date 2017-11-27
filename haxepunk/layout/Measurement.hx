package haxepunk.layout;

typedef MeasurementData = {
	value:Float,
	unit:MeasurementType,
}

@:forward(value, unit)
abstract Measurement(MeasurementData) from MeasurementData to MeasurementData
{
	// preallocate whole percentages to avoid runtime allocations
	static var _percent:Array<Measurement> = [for (i in 0 ... 101) new Measurement(i, MeasurementType.Percent)];

	@:from public static inline function fromFloat(v:Float) return new Measurement(v);

	public static inline function percent(v:Float) return (v % 1 == 0) ? _percent[Std.int(v)] : new Measurement(v, MeasurementType.Percent);

	public function new(value:Float, unit:MeasurementType=MeasurementType.Pixels)
	{
		return cast {value: value, unit: unit};
	}

	public inline function measure(?max:Float=100):Float
	{
		return switch (this.unit)
		{
			case Percent: this.value * max / 100;
			default: this.value;
		}
	}

	@:to public inline function toString():String return Std.string(this.value) + Std.string(this.unit);
}
