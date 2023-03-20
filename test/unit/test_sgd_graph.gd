extends GutTest


const PARAM_VALUES = [false, true]
const MAKE_SPANNING_SHUFFLE_PROBABILITY = 0.5
const MAKE_SPANNING_KEEP_PROBABILITY = 0.8
const RANDOM_NUMBER_GENERATOR_SEED = 1
const EPSILON = 1e-3


func _make_duplication_test_params() -> Array:
	var result = []
	for oriented in [false, true]:
		result.push_back({
				"oriented": oriented
			})
	return result


func _make_connect_neighbours_test_params() -> Array:
	var result = []
	for oriented in [false, true]:
		for connectivity in range(1, 3):
			result.push_back({
					"oriented": oriented,
					"connectivity": connectivity
				})
	return result


var _graph_3d: SgdGraph3D
var _random_number_gen: RandomNumberGenerator


func initialize(oriented: bool) -> void:
	_graph_3d = SgdGraph3D.new(oriented)


func test_can_add_points(oriented = use_parameters(PARAM_VALUES)) -> void:
	initialize(oriented)
	var id_a = _graph_3d.add_point(Vector3(0, 0, 0))
	var id_b = _graph_3d.add_point(Vector3(1, 0, 0))
	
	assert_true(_graph_3d.has_node(id_a))
	assert_true(_graph_3d.has_node(id_b))
	assert_eq(_graph_3d.get_node_count(), 2)


func test_can_remove_nodes(oriented = use_parameters(PARAM_VALUES)) -> void:
	initialize(oriented)
	var id_a = _graph_3d.add_point(Vector3(0, 0, 0))
	var id_b = _graph_3d.add_point(Vector3(1, 0, 0))
	_graph_3d.remove_node(id_a)
	_graph_3d.remove_node(id_b)
	
	assert_false(_graph_3d.has_node(id_a))
	assert_false(_graph_3d.has_node(id_b))
	assert_eq(_graph_3d.get_node_count(), 0)


func test_should_recycle_ids(oriented = use_parameters(PARAM_VALUES)) -> void:
	initialize(oriented)
	var id_a = _graph_3d.add_point(Vector3(0, 0, 0))
	_graph_3d.add_point(Vector3(1, 0, 0))
	_graph_3d.remove_node(id_a)
	var id_c = _graph_3d.add_point(Vector3(1, 0, 1))
	
	assert_eq(id_a, id_c)


func test_should_recycle_ids_only_once(oriented = use_parameters(PARAM_VALUES)) -> void:
	initialize(oriented)
	var id_a = _graph_3d.add_point(Vector3(0, 0, 0))
	_graph_3d.add_point(Vector3(1, 0, 0))
	_graph_3d.remove_node(id_a)
	_graph_3d.add_point(Vector3(1, 0, 1))
	var id_d = _graph_3d.add_point(Vector3(1, 1, 1))
	
	assert_ne(id_a, id_d)


func test_can_add_edge(oriented = use_parameters(PARAM_VALUES)) -> void:
	initialize(oriented)
	var id_a = _graph_3d.add_point(Vector3(0, 0, 0))
	var id_b = _graph_3d.add_point(Vector3(1, 0, 0))
	var edge_id = _graph_3d.add_edge(id_a, id_b)
	
	assert_true(_graph_3d.has_edge(edge_id))
	assert_eq(_graph_3d.get_edge_count(), 1)


func test_edges_have_no_orientation() -> void:
	initialize(false)
	var id_a = _graph_3d.add_point(Vector3(0, 0, 0))
	var id_b = _graph_3d.add_point(Vector3(1, 0, 0))
	_graph_3d.add_edge(id_a, id_b)
	
	assert_true(_graph_3d.has_edge(_graph_3d.get_edge_id(id_b, id_a)))


func test_edges_have_orientation() -> void:
	initialize(true)
	var id_a = _graph_3d.add_point(Vector3(0, 0, 0))
	var id_b = _graph_3d.add_point(Vector3(1, 0, 0))
	_graph_3d.add_edge(id_a, id_b)
	
	assert_false(_graph_3d.has_edge(_graph_3d.get_edge_id(id_b, id_a)))


func test_can_duplicate(params = use_parameters(_make_duplication_test_params())) -> void:
	initialize(params.oriented)
	var id_a = _graph_3d.add_point(Vector3(0, 0, 0))
	var id_b = _graph_3d.add_point(Vector3(1, 0, 0))
	var edge_id = _graph_3d.add_edge(id_a, id_b, { "test_data": true })
	
	var dup = _graph_3d.duplicate()
	
	assert_true(dup.has_node(id_a))
	assert_true(dup.has_node(id_b))
	assert_eq(dup.get_node_data(id_a), _graph_3d.get_node_data(id_a))
	assert_eq(dup.get_node_data(id_b), _graph_3d.get_node_data(id_b))
	assert_eq(dup.get_node_count(), 2)
	assert_true(dup.has_edge(edge_id))
	assert_eq(dup.is_oriented(), _graph_3d.is_oriented())


func test_can_connect_fully(oriented = use_parameters(PARAM_VALUES)) -> void:
	initialize(oriented)
	_graph_3d.add_point(Vector3(1, 0, 0))
	_graph_3d.add_point(Vector3(1, 1, 0))
	_graph_3d.add_point(Vector3(0, 1, 0))
	_graph_3d.add_point(Vector3(0, 1, 0))
	_graph_3d.connect_fully()
	if oriented:
		assert_eq(_graph_3d.get_edge_count(), 16)
	else:
		assert_eq(_graph_3d.get_edge_count(), 6)


func test_can_connect_neighbours(params = use_parameters(_make_connect_neighbours_test_params())) -> void:
	var oriented = params["oriented"]
	initialize(oriented)
	# warning-ignore:return_value_discarded
	_graph_3d.add_point(Vector3(1, 0, 0))
	# warning-ignore:return_value_discarded
	_graph_3d.add_point(Vector3(1, 1, 0))
	# warning-ignore:return_value_discarded
	_graph_3d.add_point(Vector3(0, 1, 0))
	# warning-ignore:return_value_discarded
	_graph_3d.add_point(Vector3(0, 1, 0))
	var connectivity = params["connectivity"]
	_graph_3d.connect_neighbours(connectivity)
	match connectivity:
		1:
			if oriented:
				assert_eq(_graph_3d.get_edge_count(), 4)
			else:
				assert_eq(_graph_3d.get_edge_count(), 2)
		2:
			if oriented:
				assert_eq(_graph_3d.get_edge_count(), 8)
			else:
				assert_eq(_graph_3d.get_edge_count(), 3)


func test_can_make_smallest_spanning(oriented = use_parameters(PARAM_VALUES)) -> void:
	initialize(oriented)
	var id_a = _graph_3d.add_point(Vector3(1, 0, 0))
	var id_b = _graph_3d.add_point(Vector3(1, 1, 0))
	var id_c = _graph_3d.add_point(Vector3(0, 1, 0))
	var id_d = _graph_3d.add_point(Vector3(0, 1, 1))
	_graph_3d.connect_fully()
	var tree_count = _graph_3d.make_spanning_forest().size()
	assert_eq(tree_count, 1)
	assert_eq(_graph_3d.get_edge_count(), 3)
	assert_true(_has_edge_any_dir(id_a, id_b))
	assert_true(_has_edge_any_dir(id_b, id_c))
	assert_true(_has_edge_any_dir(id_c, id_d))


func test_can_make_spanning_with_random_component(oriented = use_parameters(PARAM_VALUES)) -> void:
	initialize(oriented)
	_random_number_gen = RandomNumberGenerator.new()
	_random_number_gen.seed = RANDOM_NUMBER_GENERATOR_SEED
	var id_a = _graph_3d.add_point(Vector3(1, 0, 0))
	var id_b = _graph_3d.add_point(Vector3(1, 1, 0))
	var id_c = _graph_3d.add_point(Vector3(0, 1, 0))
	var id_d = _graph_3d.add_point(Vector3(0, 1, 1))
	_graph_3d.connect_fully()
	var tree_count = _graph_3d.make_spanning_forest(
			MAKE_SPANNING_SHUFFLE_PROBABILITY, 0.0, _random_number_gen).size()
	assert_eq(tree_count, 1)
	assert_eq(_graph_3d.get_edge_count(), 3)
	
	# Thes were determined by running the tests with the given random number generator and seed.
	# Thes will likely change if the seed or the algorithm are changed.
	if not oriented:
		assert_true(_has_edge_any_dir(id_a, id_b))
		assert_true(_has_edge_any_dir(id_a, id_c))
		assert_true(_has_edge_any_dir(id_c, id_d))
	else:
		assert_true(_has_edge_any_dir(id_a, id_c))
		assert_true(_has_edge_any_dir(id_a, id_d))
		assert_true(_has_edge_any_dir(id_b, id_c))


func test_can_make_almost_spanning(oriented = use_parameters(PARAM_VALUES)) -> void:
	initialize(oriented)
	var id_a = _graph_3d.add_point(Vector3(1, 0, 0))
	var id_b = _graph_3d.add_point(Vector3(1, 1, 0))
	var id_c = _graph_3d.add_point(Vector3(0, 1, 0))
	var id_d = _graph_3d.add_point(Vector3(0, 1, 1))
	_graph_3d.connect_fully()
	var tree_count = _graph_3d.make_spanning_forest(
			0.0, MAKE_SPANNING_KEEP_PROBABILITY, _random_number_gen).size()
	assert_eq(tree_count, 1)
	assert_gt(_graph_3d.get_edge_count(), 3)
	assert_true(_has_edge_any_dir(id_a, id_b))
	assert_true(_has_edge_any_dir(id_b, id_c))
	assert_true(_has_edge_any_dir(id_c, id_d))


func test_can_compute_all_costs_correctly(oriented = use_parameters(PARAM_VALUES)) -> void:
	initialize(oriented)
	var id_a = _graph_3d.add_point(Vector3(1, 0, 0))
	var id_b = _graph_3d.add_point(Vector3(1, 1, 0))
	var id_c = _graph_3d.add_point(Vector3(0, 1, 0))
	var id_d = _graph_3d.add_point(Vector3(0, 1, 1))
	_graph_3d.connect_fully()
	var costs = _graph_3d.get_all_costs_from_node(id_a)
	assert_almost_eq(costs[id_a], 0.0, 1e-3)
	assert_almost_eq(costs[id_b], 1.0, 1e-3)
	assert_almost_eq(costs[id_c], sqrt(2.0), 1e-3)
	assert_almost_eq(costs[id_d], sqrt(3.0), 1e-3)
	_graph_3d.make_spanning_forest()
	costs = _graph_3d.get_all_costs_from_node(id_d)
	assert_almost_eq(costs[id_a], 3.0, 1e-3)
	assert_almost_eq(costs[id_b], 2.0, 1e-3)
	assert_almost_eq(costs[id_c], 1.0, 1e-3)
	assert_almost_eq(costs[id_d], 0.0, 1e-3)


func test_can_merge_two_graphs(oriented = use_parameters(PARAM_VALUES)) -> void:
	initialize(oriented)
	var first_graph = _graph_3d
	var second_graph = _graph_3d.duplicate()
	var id_a_1 = first_graph.add_point(Vector3(1, 0, 0))
	first_graph.add_point(Vector3(1, 1, 0))
	first_graph.add_point(Vector3(0, 1, 0))
	var id_d_1 = first_graph.add_point(Vector3(0, 1, 1))
	first_graph.connect_fully()
	first_graph.make_spanning_forest()
	
	var id_a_2 = second_graph.add_point(Vector3(2, 0, 0))
	second_graph.add_point(Vector3(2, 2, 0))
	second_graph.add_point(Vector3(0, 2, 0))
	var id_d_2 = second_graph.add_point(Vector3(0, 2, 2))
	second_graph.connect_fully()
	second_graph.make_spanning_forest()
	
	var graph_merge_result = SgdGraphMerger.new(first_graph) \
			.add_graph(second_graph) \
			.add_inter_graph_edge(first_graph, id_d_1, second_graph, id_a_2, "Test") \
			.build()
	
	var merged_graph = graph_merge_result.get_graph()
	assert_true(merged_graph is SgdGraph)
	assert_eq(merged_graph.get_node_count(), first_graph.get_node_count() + second_graph.get_node_count())
	assert_eq(merged_graph.get_edge_count(), first_graph.get_edge_count() + second_graph.get_edge_count() + 1)
	
	for node_id in first_graph.get_node_ids():
		var new_node_id = graph_merge_result.get_new_node_id(first_graph, node_id)
		assert_true(merged_graph.has_node(new_node_id))
		assert_eq(merged_graph.get_node_data(new_node_id), first_graph.get_node_data(node_id))
	
	
	for node_id in second_graph.get_node_ids():
		var new_node_id = graph_merge_result.get_new_node_id(second_graph, node_id)
		assert_true(merged_graph.has_node(new_node_id))
		assert_eq(merged_graph.get_node_data(new_node_id), second_graph.get_node_data(node_id))
	
	
	for edge_id in first_graph.get_edge_ids():
		var new_edge_id = graph_merge_result.get_new_edge_id(first_graph, edge_id)
		assert_true(merged_graph.has_edge(new_edge_id))
	
	
	for edge_id in second_graph.get_edge_ids():
		var new_edge_id = graph_merge_result.get_new_edge_id(second_graph, edge_id)
		assert_true(merged_graph.has_edge(new_edge_id))
	
	var new_id_d_1 = graph_merge_result.get_new_node_id(first_graph, id_d_1)
	var new_id_a_2 = graph_merge_result.get_new_node_id(second_graph, id_a_2)
	assert_eq(merged_graph.get_edge_data(merged_graph.get_edge_id(new_id_d_1, new_id_a_2)), "Test")
	
	var costs_first_graph = first_graph.get_all_costs_from_node(id_a_1)
	var costs_second_graph = second_graph.get_all_costs_from_node(id_a_2)
	var new_id_a_1 = graph_merge_result.get_new_node_id(first_graph, id_a_1)
	var new_id_d_2 = graph_merge_result.get_new_node_id(second_graph, id_d_2)
	var costs_merged_graph = merged_graph.get_all_costs_from_node(new_id_a_1)
	assert_almost_eq(
			costs_first_graph[id_d_1] + costs_second_graph[id_d_2],
			costs_merged_graph[new_id_d_2] \
					- merged_graph.get_edge_cost(merged_graph.get_edge_id(new_id_d_1, new_id_a_2)),
			EPSILON
		)


func test_can_map_to_dict_and_back(oriented = use_parameters(PARAM_VALUES)) -> void:
	initialize(oriented)
	_graph_3d.add_point(Vector3(1, 0, 0))
	_graph_3d.add_point(Vector3(1, 1, 0))
	_graph_3d.add_point(Vector3(0, 1, 0))
	_graph_3d.add_point(Vector3(0, 1, 1))
	_graph_3d.connect_fully()
	_graph_3d.make_spanning_forest()
	var original_costs = _graph_3d.get_all_costs_from_node(0)
	var dict = _graph_3d.to_dict()
	var loaded: SgdGraph3D = SgdGraph3D.new(false)
	loaded.from_dict(dict)
	assert_eq(loaded.is_oriented(), _graph_3d.is_oriented())
	assert_eq(loaded.get_node_count(), _graph_3d.get_node_count())
	assert_eq(loaded.get_edge_count(), _graph_3d.get_edge_count())
	var loaded_costs = loaded.get_all_costs_from_node(0)
	for node_id in _graph_3d.get_node_ids():
		assert_true(loaded.has_node(node_id))
		assert_eq_deep(loaded.get_node_data(node_id), _graph_3d.get_node_data(node_id))
		assert_eq(loaded_costs[node_id], original_costs[node_id])
	
	for edge_id in _graph_3d.get_edge_ids():
		assert_true(loaded.has_edge(edge_id))
		assert_eq_deep(loaded.get_edge_data(edge_id), _graph_3d.get_edge_data(edge_id))


func _has_edge_any_dir(id_a: int, id_b: int) -> bool:
	return _graph_3d.has_edge(_graph_3d.get_edge_id(id_a, id_b)) \
			or _graph_3d.has_edge(_graph_3d.get_edge_id(id_b, id_a))
