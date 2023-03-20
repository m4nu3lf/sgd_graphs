class_name SgdGraph


const NODE_COUNT_MAX: int = 46340 # Assume 32 bit signed integers


var _next_id: int = 0
var _deleted_ids: Array[int] = []
var _is_oriented: bool = false

var _nodes: Dictionary = {}
var _edges: Dictionary = {}

 # Used to quickly find edges going out or coming in to a given node
var _node_outgoing_edges: Dictionary = {}
var _node_incoming_edges: Dictionary = {}

var _edge_cost_cache: Dictionary


func _init(is_oriented: bool = false) -> void:
	_is_oriented = is_oriented


func is_oriented() -> bool:
	return _is_oriented


func add_node(data = null) -> int:
	assert(_nodes.size() < NODE_COUNT_MAX, "Reached node limit")
	var id: int = -1
	if not _deleted_ids.is_empty():
		id = _deleted_ids.pop_back()
	else:
		id = _next_id
		_next_id += 1
	_nodes[id] = data
	_node_outgoing_edges[id] = {}
	_node_incoming_edges[id] = {}
	return id


func has_node(id: int) -> bool:
	return _nodes.has(id)


func set_node_data(id: int, data) -> void:
	_assert_node_exists(id)
	for id_b in _node_outgoing_edges[id].keys():
		# warning-ignore:return_value_discarded
		_edge_cost_cache.erase(get_edge_id(id, id_b))
	
	if _is_oriented:
		for id_b in _node_incoming_edges[id].keys():
			# warning-ignore:return_value_discarded
			_edge_cost_cache.erase(get_edge_id(id, id_b))
	_nodes[id] = data


func get_node_data(id: int):
	_assert_node_exists(id)
	return _nodes[id]


func get_node_count() -> int:
	return _nodes.size()


func get_node_ids() -> Array:
	return _nodes.keys()


func get_leaf_ids() -> Array:
	var leaf_ids = []
	for node in get_node_ids():
		if is_oriented():
			if _node_outgoing_edges[node].emtpy():
				leaf_ids.push_back(node)
		else:
			if _node_incoming_edges[node].size() <= 1:
				leaf_ids.push_back(node)
	return leaf_ids


func remove_node(id: int) -> void:
	_assert_node_exists(id)
	for id_b in _node_outgoing_edges[id].keys():
		remove_edge(get_edge_id(id, id_b))
	
	if _is_oriented:
		for id_b in _node_incoming_edges[id].keys():
			remove_edge(get_edge_id(id_b, id))
	# warning-ignore:return_value_discarded
	_node_outgoing_edges.erase(id)
	# warning-ignore:return_value_discarded
	_node_incoming_edges.erase(id)
	# warning-ignore:return_value_discarded
	_nodes.erase(id)
	_deleted_ids.push_back(id)


func add_edge(id_a: int, id_b: int, data = null) -> int:
	var id = get_edge_id(id_a, id_b)
	assert(not _edges.has(id), "Nodes are connected already")
	_edges[id] = data
	_node_outgoing_edges[id_a][id_b] = true
	_node_incoming_edges[id_b][id_a] = true
	if not _is_oriented:
		_node_outgoing_edges[id_b][id_a] = true
		_node_incoming_edges[id_a][id_b] = true
	return id


func has_edge(id: int) -> bool:
	return _edges.has(id)


func has_edge_between_nodes(node_id_a: int, node_id_b: int) -> bool:
	return _edges.has(_get_edge_id_no_check(node_id_a, node_id_b))


func get_edge_count() -> int:
	return _edges.size()


func get_edge_ids() -> Array:
	return _edges.keys()


func get_node_outgoing_edges(node_id: int) -> Array:
	_assert_node_exists(node_id)
	return _node_outgoing_edges[node_id].keys()


func get_node_incoming_edges(node_id: int) -> Array:
	_assert_node_exists(node_id)
	return _node_incoming_edges[node_id].keys()


func set_edge_data(id: int, data) -> void:
	_assert_edge_exists(id)
	_edges[id] = data
	if _edge_cost_cache.has(id):
		# warning-ignore:return_value_discarded
		_edge_cost_cache.erase(id)


func get_edge_data(id: int):
	_assert_edge_exists(id)
	return _edges[id]


func get_edge_cost(id: int) -> float:
	_assert_edge_exists(id)
	if _edge_cost_cache.has(id):
		return _edge_cost_cache[id]
	else:
		var node_ids = get_edge_node_ids(id)
		var cost = compute_edge_cost(
			get_node_data(node_ids[0]),
			get_node_data(node_ids[1]),
			get_edge_data(id)
		)
		_edge_cost_cache[id] = cost
		return cost


func remove_edge(id: int) -> void:
	_assert_edge_exists(id)
	var node_ids = get_edge_node_ids(id)
	var id_a = node_ids[0]
	var id_b = node_ids[1]
	# warning-ignore:return_value_discarded
	_edges.erase(id)
	if _edge_cost_cache.has(id):
		# warning-ignore:return_value_discarded
		_edge_cost_cache.erase(id)
	_node_outgoing_edges[id_a].erase(id_b)
	_node_incoming_edges[id_b].erase(id_a)
	if not _is_oriented:
		_node_outgoing_edges[id_b].erase(id_a)
		_node_incoming_edges[id_a].erase(id_b)


## Override this method with cost computation. It must be a pure function.
func compute_edge_cost(_data_node_a, _data_node_b, _data_edge) -> float:
	return 1.0


## Fully connect graph with [code]data[/code] as edge data for all new edges.
func connect_fully(edge_data = null) -> void:
	if not _is_oriented:
		var node_ids = _nodes.keys()
		for i in range(node_ids.size() - 1):
			for j in range(i + 1, node_ids.size()):
				if not has_edge(get_edge_id(node_ids[i], node_ids[j])):
					# warning-ignore:return_value_discarded
					add_edge(node_ids[i], node_ids[j], edge_data)
	else:
		for node_id_a in _nodes.keys():
			for node_id_b in _nodes.keys():
				if not has_edge(get_edge_id(node_id_a, node_id_b)):
					# warning-ignore:return_value_discarded
					add_edge(node_id_a, node_id_b, edge_data)


## Connect nodes with minimum distance between them.
## [code]connectivity[/code] is the number of close nodes to connect.
## [data]data[/code] is the data of each new edge added.
func connect_neighbours(connectivity: int = 1, data = null) -> void:
	if not _is_oriented:
		var node_ids = get_node_ids()
		for i in range(node_ids.size() - 1):
			var node_id_a = node_ids[i]
			var edge_added = true
			while edge_added and get_node_outgoing_edges(node_id_a).size() < connectivity:
				edge_added = false
				var min_edge_cost: float = INF
				var min_edge_node_a
				var min_edge_node_b
				for j in range(i, node_ids.size()):
					var node_id_b = node_ids[j]
					if node_id_a != node_id_b and not has_edge(get_edge_id(node_id_a, node_id_b)):
						var edge_cost = compute_edge_cost(get_node_data(node_id_a), get_node_data(node_id_b), data)
						if edge_cost < min_edge_cost:
							min_edge_cost = edge_cost
							min_edge_node_a = node_id_a
							min_edge_node_b = node_id_b
				if not is_inf(min_edge_cost):
					# warning-ignore:return_value_discarded
					add_edge(min_edge_node_a, min_edge_node_b, data)
					edge_added = true
	else:
		for node_id_a in _nodes.keys():
			var edge_added = true
			while edge_added and get_node_outgoing_edges(node_id_a).size() < connectivity:
				edge_added = false
				var min_edge_cost: float = INF
				var min_edge_node_a
				var min_edge_node_b
				for node_id_b in _nodes.keys():
					if node_id_a != node_id_b and not has_edge(get_edge_id(node_id_a, node_id_b)):
						var edge_cost = compute_edge_cost(get_node_data(node_id_a), get_node_data(node_id_b), data)
						if edge_cost < min_edge_cost:
							min_edge_cost = edge_cost
							min_edge_node_a = node_id_a
							min_edge_node_b = node_id_b
				if not is_inf(min_edge_cost):
					# warning-ignore:return_value_discarded
					add_edge(min_edge_node_a, min_edge_node_b, data)
					edge_added = true


func clear() -> void:
	_edges.clear()
	_nodes.clear()


func clear_edge() -> void:
	_edges.clear()


func duplicate(deep: bool = false) -> SgdGraph:
	var other = SgdGraph.new(_is_oriented)
	return _duplicate(other, deep)


func _duplicate(other: SgdGraph, deep: bool) -> SgdGraph:
	other._next_id = _next_id
	other._nodes = _nodes.duplicate(deep)
	other._edges = _edges.duplicate(deep)
	other._node_outgoing_edges = _node_outgoing_edges.duplicate(true)
	other._node_incoming_edges = _node_incoming_edges.duplicate(true)
	other._edge_cost_cache = _edge_cost_cache.duplicate()
	return other


func _sort_edge_ids_and_costs(el_a: Array, el_b: Array) -> bool:
	if el_a[1] > el_b[1]:
		return true
	elif el_a[1] < el_b[1]:
		return false
	else:
		return el_a[0] > el_b [0]


## - [code]shuffle_probability[/code] is the probability of an edge to be shuffled after sorting by cost.
## If [code]shuffle_amount == 0.0[/code] no random shuffling will happen and the resulting forest will be the
## least costly one, if [code]shuffle_amount == 1.0[/code] all elements will be randomly shuffled and the resulting
## trees will be random.
## - [code]keep_probability[/code] is the probability an edge which is not part of the computed spanning tree is kept
## this will make it possible to generate "almost" spanning trees.
## - [code]rng[/code] is a RandomNumberGenerator that can be used to provide a seeded generator
##
## The return value is an array of arrays of node ids for each of the spanning (or almost spanning) trees
func make_spanning_forest(shuffle_probability: float = 0.0, keep_probability: float = 0.0,
		rng: RandomNumberGenerator = null) -> Array[Array]:
	# Implements the Kruskal's algorithm: https://en.wikipedia.org/wiki/Kruskal%27s_algorithm
	var node_id_to_node_set_id = {}
	var node_sets = {}
	for node_id in get_node_ids():
		node_id_to_node_set_id[node_id] = node_id
		node_sets[node_id] = [node_id]
	var edge_ids_and_costs = []
	for edge_id in get_edge_ids():
		var edge_cost = get_edge_cost(edge_id)
		edge_ids_and_costs.push_back([edge_id, edge_cost])
	if shuffle_probability < 1.0:
		edge_ids_and_costs.sort_custom(self._sort_edge_ids_and_costs)
	if not rng:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	if shuffle_probability > 0.0:
		for i in range(edge_ids_and_costs.size()):
			if rng.randf() < shuffle_probability:
				var j = rng.randi_range(0, edge_ids_and_costs.size() - 1)
				var tmp = edge_ids_and_costs[i]
				edge_ids_and_costs[i] = edge_ids_and_costs[j]
				edge_ids_and_costs[j] = tmp
	var edge_set = {}
	while edge_ids_and_costs.size() > 0:
		var edge_id = edge_ids_and_costs.pop_back()[0]
		var node_ids = get_edge_node_ids(edge_id)
		var node_id_a = node_ids[0]
		var node_id_b = node_ids[1]
		var set_id_node_a =  node_id_to_node_set_id[node_id_a]
		var set_id_node_b =  node_id_to_node_set_id[node_id_b]
		var node_set_node_a = node_sets[set_id_node_a]
		if set_id_node_a != set_id_node_b:
			edge_set[edge_id] = true
			for node_id in node_sets[set_id_node_b]:
				node_id_to_node_set_id[node_id] = set_id_node_a
				node_set_node_a.push_back(node_id)
			node_sets.erase(set_id_node_b)
	
	for edge_id in get_edge_ids():
		if not edge_set.has(edge_id):
			if keep_probability == 0.0 or rng.randf() > keep_probability:
				remove_edge(edge_id)
	var result: Array[Array] = []
	for node in node_sets.values():
		result.push_back(node)
	return result


func get_all_costs_from_node(start_id: int) -> Dictionary:
	var costs = {}
	for node_id in _nodes.keys():
		costs[node_id] = INF
	costs[start_id] = 0.0
	var open_node_ids = { start_id: true }
	while not open_node_ids.is_empty():
		var open_node_ids_tmp = open_node_ids.keys()
		open_node_ids.clear()
		for node_id in open_node_ids_tmp:
			for next_node_id in _node_outgoing_edges[node_id].keys():
				var new_cost = get_edge_cost(get_edge_id(node_id, next_node_id)) + costs[node_id]
				if new_cost < costs[next_node_id]:
					costs[next_node_id] = new_cost
					open_node_ids[next_node_id] = true
	return costs


func get_edge_id(id_a: int, id_b: int) -> int:
	_assert_node_exists(id_a)
	_assert_node_exists(id_b)
	return _get_edge_id_no_check(id_a, id_b)


func _get_edge_id_no_check(id_a: int, id_b: int) -> int:
	var ids = [id_a, id_b]
	if not _is_oriented:
		ids.sort()
	return ids[0] + ids[1] * NODE_COUNT_MAX


func get_edge_node_ids(id: int) -> Array:
	_assert_edge_exists(id)
	var id_a = id % NODE_COUNT_MAX
	# warning-ignore:integer_division
	var id_b = id / NODE_COUNT_MAX
	return [id_a, id_b]


func to_dict() -> Dictionary:
	var result_dict = {
		"next_id": _next_id,
		"deleted_ids": _deleted_ids,
		"is_oriented": _is_oriented,
		"nodes": _nodes,
		"edges": _edges,
		"node_outgoing_edges": _node_outgoing_edges
	}
	return result_dict


func from_dict(dict: Dictionary) -> void:
	_next_id = dict.next_id
	_deleted_ids = dict.deleted_ids.duplicate()
	_is_oriented = dict.is_oriented
	_nodes = dict.nodes.duplicate()
	_edges = dict.edges.duplicate()
	_node_outgoing_edges = dict.node_outgoing_edges.duplicate()


func _assert_node_exists(id: int) -> void:
	assert(_nodes.has(id), "Node doesn't exist")


func _assert_edge_exists(id: int) -> void:
	assert(_edges.has(id), "Nodes are not connected")
