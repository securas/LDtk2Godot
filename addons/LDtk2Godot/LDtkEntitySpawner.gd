extends Node
class_name LDtkEntitySpawner

export( PackedDataContainer ) var LDtk_Resource : PackedDataContainer = PackedDataContainer.new() setget _set_LDtk_Resource
export( Array, String ) var levels := [ "" ] setget _set_levels
export( Array, String ) var layers := [ "" ] setget _set_layers

func _enter_tree():
	if LDtk_Resource and LDtk_Resource is PackedDataContainer:
		_update_LDtk_resource()

func _set_LDtk_Resource( v ):
	LDtk_Resource = v
	if LDtk_Resource and LDtk_Resource is PackedDataContainer and Engine.editor_hint:
		_update_LDtk_resource()

func _set_levels( v ):
	levels = v
	if LDtk_Resource and LDtk_Resource is PackedDataContainer and Engine.editor_hint:
		_update_LDtk_resource()

func _set_layers( v ):
	layers = v
	if LDtk_Resource and LDtk_Resource is PackedDataContainer and Engine.editor_hint:
		_update_LDtk_resource()

func _update_LDtk_resource():
	var data = bytes2var( LDtk_Resource.__data__, true )
	var resource_data = bytes2var( data, true )
	var entities_data = resource_data.entities
	for level_name in levels:
		if level_name.empty(): continue
		for layer_name in layers:
			if layer_name.empty(): continue
			var entities = _get_entities( level_name, layer_name, entities_data )
			for entity in entities:
				call_deferred( "_spawn_entity", entity )

func _get_entities( level_name, layer_name, entities_data ):
	var entities = []
	if entities_data.has( level_name ):
		if entities_data[level_name].has( layer_name ):
			return entities_data[level_name][layer_name]
	return entities

func _spawn_entity( entity_data : Dictionary ) -> void:
	pass
