extends SgdGraph
class_name SgdGraph3D


func _init(oriented: bool) -> void:
	super(oriented)


func add_point(position: Vector3) -> int:
	return super.add_node(position)


func set_point_position(id: int, position: Vector3) -> void:
	super.set_node_data(id, position)


func compute_edge_cost(data_a: Vector3, data_b: Vector3, _data_edge) -> float:
	return data_a.distance_to(data_b)


func get_node_data(id: int) -> Vector3:
	return super.get_node_data(id)


func duplicate(deep: bool = false) -> SgdGraph:
	var other = SgdGraph3D.new(_is_oriented)
	return _duplicate(other, deep)
