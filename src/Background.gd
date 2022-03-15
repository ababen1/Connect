extends TileMap

func draw_background(size: Vector2) -> void:
	var tile1 = tile_set.get_tiles_ids().front()
	var tile2 = tile_set.get_tiles_ids().back()
	for y in size.y:
		for x in size.x:
			var cell_texture = tile1 if int(x + y) % 2 == 0 else tile2
			set_cell(x,y, cell_texture)
