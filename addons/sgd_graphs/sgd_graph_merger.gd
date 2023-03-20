class_name SgdGraphMerger


var _fast_graphs: Array[SgdGraph] = []
var _graph_ids: Dictionary = {}
var _inter_edges: Dictionary = {}

var _used: bool = false
var _is_oriented: bool = false
var _graph_class: String


class SgdGraphMergeResult:
	
	var _node_mappings: Dictionary = {}
	var _merger: Object
	var _fast_graph: SgdGraph
	
	
	func get_new_node_id(graph: SgdGraph, node_idx: int) -> int:
		var graph_idx = _merger._get_graph_id(graph)
		return _node_mappings[str([graph_idx, node_idx])]
	
	
	func get_new_edge_id(graph: SgdGraph, edge_idx: int) -> int:
		var graph_idx = _merger._get_graph_id(graph)
		var node_ids = graph.get_edge_node_ids(edge_idx)
		var new_node_id_a = _node_mappings[str([graph_idx, node_ids[0]])]
		var new_node_id_b = _node_mappings[str([graph_idx, node_ids[1]])]
		return _fast_graph.get_edge_id(new_node_id_a, new_node_id_b)
	
	
	func get_graph() -> SgdGraph:
		return _fast_graph


func _init(graph: SgdGraph) -> void:
	_graph_class = graph.get_class()
	_is_oriented = graph.is_oriented()
	# warning-ignore:return_value_discarded
	add_graph(graph)


func add_graph(fast_graph: SgdGraph) -> Object:
	_check_not_used()
	assert(fast_graph.is_oriented() == _is_oriented, "Cannot merge oriented and not oriented graphs")
	assert(fast_graph.get_class() == _graph_class, "Cannot merge graph instances of different sub classes")
	_fast_graphs.push_back(fast_graph)
	_graph_ids[fast_graph] = _fast_graphs.size() - 1
	return self


func add_inter_graph_edge(graph_a: SgdGraph, node_idx_a: int, graph_b: SgdGraph,
		node_idx_b: int, data = null) -> Object:
	_check_not_used()
	assert(graph_a.has_node(node_idx_a) and graph_b.has_node(node_idx_b), "Nodes must exist in graphs")
	var graph_idx_a = _get_graph_id(graph_a)
	var graph_idx_b = _get_graph_id(graph_b)
	var edge_ids = _make_inter_egde_ids(graph_idx_a, node_idx_a, graph_idx_b, node_idx_b)
	if not _inter_edges.has(edge_ids[0]):
		_inter_edges[edge_ids[0]] = [[graph_idx_a, node_idx_a], [graph_idx_b, node_idx_b], data]
		if not _is_oriented:
			_inter_edges[edge_ids[1]] = [[graph_idx_b, node_idx_b], [graph_idx_a, node_idx_a], data]
	return self


func build(deep_copy_data: bool = false) -> SgdGraphMergeResult:
	_check_not_used()
	assert(not _fast_graphs.is_empty(), "Cannot merge 0 graphs")
	var result = SgdGraphMergeResult.new()
	result._merger = self
	var first_graph = _fast_graphs[0].duplicate()
	result._fast_graph = first_graph
	for node_id in first_graph.get_node_ids():
		result._node_mappings[str([0, node_id])] = node_id
	
	for i in range(1, _fast_graphs.size()):
		var graph = _fast_graphs[i]
		for node_id in graph.get_node_ids():
			var node_data = graph.get_node_data(node_id)
			var new_node_id = first_graph.add_node(node_data)
			result._node_mappings[str([i, node_id])] = new_node_id
		
		for edge_id in graph.get_edge_ids():
			var node_ids = graph.get_edge_node_ids(edge_id)
			var new_node_id_a = result.get_new_node_id(graph, node_ids[0])
			var new_node_id_b = result.get_new_node_id(graph, node_ids[1])
			var edge_data = graph.get_edge_data(edge_id)
			first_graph.add_edge(new_node_id_a, new_node_id_b, edge_data)
	
	for inter_edge in _inter_edges.values():
		var node_id_a = result.get_new_node_id(_fast_graphs[inter_edge[0][0]], inter_edge[0][1])
		var node_id_b = result.get_new_node_id(_fast_graphs[inter_edge[1][0]], inter_edge[1][1])
		if not first_graph.has_edge(first_graph.get_edge_id(node_id_a, node_id_b)):
			first_graph.add_edge(node_id_a, node_id_b, inter_edge[2])
	if deep_copy_data:
		result._fast_graph = result._fast_graph.duplicate(true)
	return result


func _get_graph_id(graph: SgdGraph) -> int:
	assert(_graph_ids.has(graph), "Graph was not added to the merger, cannot get ID")
	return _graph_ids[graph]


func _make_inter_egde_ids(graph_idx_a: int, node_idx_a: int, graph_idx_b: int, node_idx_b: int) -> Array:
	if _is_oriented:
		return [str([[graph_idx_a, node_idx_a], [graph_idx_b, node_idx_b]])]
	else:
		return [str([[graph_idx_a, node_idx_a], [graph_idx_b, node_idx_b]]),
				str([[graph_idx_b, node_idx_b], [graph_idx_a, node_idx_a]])]


func _check_not_used() -> void:
	assert(not _used, "The merger was already used, cannot use it twice")
