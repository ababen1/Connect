extends Resource
class_name PathData

enum {
	DIRECT = 1,
	TWO_CASTS = 2,
	THREE_CASTS = 3
	INVALID = -1
}

var start_cast: PoolVector2Array
var end_cast: PoolVector2Array
var connecting_cast: PoolVector2Array

func _init(start: PathRaycast = null, end: PathRaycast = null, connecting: PathRaycast = null) -> void:
	start_cast = PoolVector2Array([start.global_position, start.get_casting_global_pos()]) if start else PoolVector2Array([])
	end_cast = PoolVector2Array([end.global_position, end.get_casting_global_pos()]) if end else PoolVector2Array([])
	connecting_cast = PoolVector2Array([connecting.global_position, connecting.get_casting_global_pos()]) if connecting else PoolVector2Array([])

func get_line_path() -> PoolVector2Array:
	match get_path_type():
		DIRECT:
			return start_cast
		TWO_CASTS:
			return _make_path_with_two_casts()
		THREE_CASTS:
			return _make_path_with_three_casts()
		_:
			return PoolVector2Array([])
	
func get_path_length() -> float:
	var start_cast_length = start_cast[0].distance_to(start_cast[1]) if start_cast else 0.0
	var end_cast_length = end_cast[0].distance_to(end_cast[1]) if end_cast else 0.0
	var connecting_cast_length = connecting_cast[0].distance_to(connecting_cast[1]) if connecting_cast else 0.0
	return start_cast_length + end_cast_length + connecting_cast_length
	
func get_path_type() -> int:
	if start_cast and not end_cast and not connecting_cast:
		return DIRECT
	elif start_cast and end_cast and not connecting_cast:
		return TWO_CASTS
	elif start_cast and end_cast and connecting_cast:
		return THREE_CASTS
	else:
		return INVALID

func _make_path_with_two_casts() -> PoolVector2Array:
	assert(get_path_type() == TWO_CASTS)
	var intersection = get_intersection_point(start_cast, end_cast)
	return PoolVector2Array([start_cast[0], intersection, end_cast[0]])

func _make_path_with_three_casts() -> PoolVector2Array:
	return PoolVector2Array([
		start_cast[0], 
		connecting_cast[0], 
		connecting_cast[1], 
		end_cast[0]])

static func get_intersection_point(
	line1: PoolVector2Array, 
	line2: PoolVector2Array) -> Vector2:
		var point_a = line1[0]
		var point_b = line1[1]
		var point_c = line2[0]
		var point_d = line2[1]

		 # Line AB represented as a1x + b1y = c1
		var a1 = point_b.y - point_a.y
		var b1 = point_a.x - point_b.x
		var c1 = a1*(point_a.x) + b1*(point_a.y)

		# Line CD represented as a2x + b2y = c2
		var a2 = point_d.y - point_c.y;
		var b2 = point_c.x - point_d.x;
		var c2 = a2*(point_c.x)+ b2*(point_c.y)
		
		var determinant = a1*b2 - a2*b1;
		if determinant == 0:
			return Vector2.ZERO
		else:
			var x = (b2*c1 - b1*c2) / determinant
			var y = (a1*c2 - a2*c1) / determinant
			return Vector2(x,y)
		
