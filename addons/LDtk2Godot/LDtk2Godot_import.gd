tool
extends EditorImportPlugin

enum Presets { DEFAULT }

func get_importer_name():
	return "LDtk2Godot"

func get_visible_name():
	return "LDTK"

func get_recognized_extensions():
	return ["ldtk"]

func get_save_extension():
	return "res"

func get_resource_type():
	return "PackedDataContainer"

func get_preset_count():
	return Presets.size()

func get_preset_name(preset):
	match preset:
		Presets.DEFAULT:
			return "Default"
		_:
			return "Unknown"

func get_import_options( preset ):
	return []

func get_option_visibility( option, options ):
	return true

func import( source_file, save_path, options, r_platform_variants, r_gen_files ):
	# Read raw data from file
	var json_file = File.new()
	var err = json_file.open( source_file, File.READ )
	if err != OK:
		return err
	var parse_data = JSON.parse( json_file.get_as_text() )
	json_file.close()
	if parse_data.error != OK:
		return parse_data.error
	var json = parse_data.result
	
	var ldtk_data = {
		"celldata" : process_json_celldata( json ),
		"entities" : process_json_entities( json ),
		"entities_list" : process_json_entities_properties( json ),
	}
	
	
	var resource := PackedDataContainer.new()
	resource.pack( var2bytes( ldtk_data, true ) )
	
	
	var result = ResourceSaver.save( "%s.%s" % [ save_path, get_save_extension() ], resource )
	return result


func process_json_celldata( json : Dictionary ) -> Dictionary:
#	print( " <<<< Importing LDtk Data >>>>")
	var data := {} 
	for source_level in json.levels:
		data[source_level.identifier] = {}
#		print( "Loading level: ", source_level.identifier )
		for source_layer in source_level.layerInstances:
			if source_layer.__type == "Entities": continue
			data[source_level.identifier][source_layer.__identifier] = []
			var cell_size : int = source_layer.__gridSize
#			print( "Loading layer: ", source_layer.__identifier )
			for source_cell in source_layer.autoLayerTiles:
				data[source_level.identifier][source_layer.__identifier].append(
					process_cell_data( source_cell, cell_size )
				)
			for source_cell in source_layer.gridTiles:
				data[source_level.identifier][source_layer.__identifier].append(
					process_cell_data( source_cell, cell_size )
				)
	return data

func process_cell_data( source_cell : Dictionary, cell_size : int ) -> Dictionary:
	var output := {
		"x" : source_cell.px[0] / cell_size,
		"y" : source_cell.px[1] / cell_size,
		"flip_x" : true if int( source_cell.f ) & 1 == 1 else false,
		"flip_y" : true if int( source_cell.f ) & 2 == 2 else false,
		"transpose" : false,
		"autotile_coord" : Vector2( source_cell.src[0], source_cell.src[1] ) / cell_size
	}
	return output


func process_json_entities( json : Dictionary ) -> Dictionary:
#	print( " <<<< Importing LDtk Data Entities >>>>")
	var data := {} 
	for source_level in json.levels:
		data[source_level.identifier] = {}
#		print( "Loading level: ", source_level.identifier )
		for source_layer in source_level.layerInstances:
			if source_layer.__type != "Entities": continue
			data[source_level.identifier][source_layer.__identifier] = []
			var cell_size : int = source_layer.__gridSize
#			print( "Loading layer: ", source_layer.__identifier )
			var layer_defid = source_layer.layerDefUid
			var idx := 0
			for entity in source_layer.entityInstances:
#				print( entity.__identifier, " - cell: ", \
#					( entity.__grid[0] + entity.__pivot[0] ) * cell_size, " ",\
#					( entity.__grid[1] + entity.__pivot[1] ) * cell_size, \
#					"    px: ",
#					entity.px )
				var new_entity = {
					"id" : entity.__identifier,
					"position" : Vector2(
						( entity.__grid[0] + entity.__pivot[0] ) * cell_size,
						( entity.__grid[1] + entity.__pivot[1] ) * cell_size
					),
					"x" : ( entity.__grid[0] + entity.__pivot[0] ) * cell_size,
					"y" : ( entity.__grid[1] + entity.__pivot[1] ) * cell_size,
					"unique_id" : "%d_%d" % [ layer_defid, idx ],
					"parameters" : {}
				}
				idx += 1
				for parameter in entity.fieldInstances:
					new_entity.parameters[parameter.__identifier] = parameter.__value
				data[source_level.identifier][source_layer.__identifier].append( new_entity )
	return data

func process_json_entities_properties( json : Dictionary ) -> Dictionary:
	var data = {}
	for entity in json.defs.entities:
		data[entity.identifier] = {}
	return data
