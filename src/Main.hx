import haxegon.*;
import haxe.ds.Vector;

using haxegon.MathExtensions;

enum GameState {
	GameState_Flying;
	GameState_Planets;
}

enum StationType {
	StationType_None;
	StationType_Assembly;
	StationType_Mining;
}

enum InventoryState {
	InventoryState_None;
	InventoryState_ShipInventory;
	InventoryState_PlanetInventory;
	InventoryState_ShipEdit;
	InventoryState_Dragged;
}

enum ItemType {
	ItemType_None;
	ItemType_ShipPart;
	ItemType_Station;
	ItemType_Material;
}


@:publicFields
class Ship_Part {
	var item_type = ItemType_ShipPart;
	var inventory_state = InventoryState_None;
	var x = 0;
	var y = 0;

	var intersecting_ship = false;
	var pixels = Data.bool_2d_vector(Main.ship_part_width, Main.ship_part_height);

	function new() {

	}
}

@:publicFields
class Station {
	var item_type = ItemType_Station;
	var inventory_state = InventoryState_None;
	var x = 0;
	var y = 0;

	var station_type = StationType_None;

	function new() {

	}
}

@:publicFields
class Material {
	var item_type = ItemType_Material;
	var inventory_state = InventoryState_None;
	var x = 0;
	var y = 0;

	var amount = 0;

	function new() {

	}
}

@:publicFields
class Star_Particle {
	var x = 0;
	var y = 0;
	var width = 0;
	var height = 0;
	var dx = 0;
	var dy = 0;

	function new() {

	}
}


@:publicFields
class Planet {
	var x = 0;
	var y = 0;
	var name = "";
	var type = 0;
	var station = StationType_None;
	var mining_timer = 0;
	static inline var mining_timer_max = 5 * 60;

	var inventory = new Vector<Dynamic>(Main.planet_inventory_width * Main.planet_inventory_height);

	function new() {

	}
}



@:publicFields
class Main {
	static inline var screen_width = 1000;
	static inline var screen_height = 1000;

	var state = GameState_Planets;

	static inline var ship_edit_x = 700;
	static inline var ship_edit_y = 0;
	static inline var ship_pixel_size = 10;
	static inline var ship_width = 25;
	static inline var ship_height = 20;
	static inline var ship_edit_width = ship_width * ship_pixel_size;
	static inline var ship_edit_height = ship_height * ship_pixel_size;
	var ship_pixels = Data.bool_2d_vector(ship_width, ship_height);
	var ship_color = Col.DARKGREEN;

	static inline var ship_part_width = 5;
	static inline var ship_part_height = 5;
	static inline var item_width = 50;
	static inline var item_height = 50;
	var items = new Array<Dynamic>();
	var parts = new Array<Ship_Part>();
	var stations = new Array<Station>();
	var materials = new Array<Material>();

	static inline var planet_size = 64;

	static inline var star_particle_amount = 15;
	var flying_state_timer = 0;
	var flying_state_timer_max = 5 * 60;
	var flying_destruction_time = 0.5;
	var flying_ship_x = 500;
	var flying_ship_y = 300;
	var star_particles = new Array<Star_Particle>();
	var destroyed_parts = new Array<Ship_Part>();
	var started_destroyed_graphic = false;
	var destroyed_pixels = Data.bool_2d_vector(ship_width, ship_height);
	var destroyed_graphic_x = 0;
	var destroyed_graphic_y = 0;
	var destroyed_graphic_dy = 0;
	// anything at this size or less gets destroyed when disconnected 
	// from the main ship
	var stray_fragment_size = 2; 

	var planets = new Array<Planet>();

	var previous_planet: Planet;
	var current_planet: Planet;

	var planet_view_ship_y = 0;
	var planet_view_ship_dy = 1;
	var planet_view_ship_y_move_timer = 0;
	var planet_view_ship_y_move_timer_max = 7;

	var ship_inventory_x = 700;
	var ship_inventory_y = 250;
	var ship_inventory_background_width = 300;
	var ship_inventory_background_height = 200;
	static inline var ship_inventory_width = 5;
	static inline var ship_inventory_height = 4;
	var ship_inventory = new Vector<Dynamic>(ship_inventory_width * ship_inventory_height);

	var planet_inventory_x = 700;
	var planet_inventory_y = 500;
	var planet_inventory_background_width = 300;
	var planet_inventory_background_height = 200;
	static inline var planet_inventory_width = 5;
	static inline var planet_inventory_height = 4;

	var crafting_x = 700;
	var crafting_y = 750;
	var crafting_background_width = 300;
	var crafting_background_height = 200;

	static inline var mining_station_cost = 5;
	static inline var assembly_station_cost = 10;
	static inline var ship_part_cost = 1;

	function new() {
		Gfx.resize_screen(screen_width, screen_height, 1);
		Gfx.load_image("rounder");		
		Gfx.load_image("mining");		
		Gfx.load_image("assembly");		
		Gfx.load_image("material");		


		load_string_to_pixels(ship_pixels, 
			[
			'...............',
			'...............',
			'.......#.......',
			'....######.....',
			'.############..',
			'..###########..',
			'.....#####.....',
			'.###########...',
			'..###########..',
			'...............',]);

		for (i in 0...10) {
			var planet = new Planet();
			planets.push(planet);
			planet.x = -100;
			planet.y = -100;
			planet.name = 'planet_${planets.length - 1}';
			planet.type = Random.int(1, 3); // 1 = no water, 2 = some water, 3 = lots of water
			Gfx.create_image(planet.name, planet_size, planet_size);
			generate_planet_image(planet);
		}

		planets[0].x = 50;
		planets[0].y = 50;

		var angle = -20;
		for (i in 1...4) {
			var origin = planets[0];
			var planet = planets[i];
			var distance = Random.int(250, 350);
			angle += Random.int(30, 40);
			var position: Vector2 = {
				x: origin.x + distance, 
				y: origin.y
			};
			Math.rotate_vector(position, origin.x, origin.y, angle);
			planet.x = Std.int(position.x);
			planet.y = Std.int(position.y);
		}

		angle = -20;

		for (i in 4...7) {
			var origin = planets[2];
			var planet = planets[i];
			var distance = Random.int(250, 350);
			angle += Random.int(30, 40);
			var position: Vector2 = {
				x: origin.x + distance, 
				y: origin.y
			};
			Math.rotate_vector(position, origin.x, origin.y, angle);
			planet.x = Std.int(position.x);
			planet.y = Std.int(position.y);
		}


		angle = -20;

		for (i in 7...10) {
			var origin = planets[6];
			var planet = planets[i];
			var distance = Random.int(250, 350);
			angle += Random.int(30, 40);
			var position: Vector2 = {
				x: origin.x + distance, 
				y: origin.y
			};
			Math.rotate_vector(position, origin.x, origin.y, angle);
			planet.x = Std.int(position.x);
			planet.y = Std.int(position.y);
		}

		current_planet = planets[0];




		var m_station = new Station();
		stations.push(m_station);
		items.push(m_station);
		m_station.station_type = StationType_Mining;
		add_item_to_ship_inventory(m_station);

		var a_station = new Station();
		stations.push(a_station);
		items.push(a_station);
		a_station.station_type = StationType_Assembly;
		add_item_to_ship_inventory(a_station);

		var material = new Material();
		materials.push(material);
		items.push(material);
		material.amount = 123;
		add_item_to_ship_inventory(material);
	}

	function count_neighbours(map: Vector<Vector<Bool>>, x: Int, y: Int): Int {
		var count = 0;
		for (dx in -1...2) {
			for (dy in -1...2) {
				var neighbour_x = x + dx;
				var neighbour_y = y + dy;

				function out_of_bound_planet(x, y) {
					return 0 > x || x >= map.length || 0 > y || y >= map[0].length;
				}

				if (dx == 0 && dy == 0) {
					continue;
				} else if (out_of_bound_planet(neighbour_x, neighbour_y)){
					count++;
				} else if (map[neighbour_x][neighbour_y]) {
					count++;
				}
			}
		}
		return count;
	}

	function run_game_of_life(width: Int, height: Int, initial_chance: Float,
		death_limit: Int, birth_limit: Int, iterations: Int): Vector<Vector<Bool>> 
	{
		var map = Data.bool_2d_vector(width, height);
		var old = Data.bool_2d_vector(width, height);

		for (x in 0...map.length) {
			for (y in 0...map[0].length) {
				if (Math.random() < initial_chance) {
					map[x][y] = true;
				} else {
					map[x][y] = false;
				}
			}
		}

		for (i in 0...iterations) {
			for (x in 0...map.length) {
				for (y in 0...map[0].length) {
					old[x][y] = map[x][y];
				}
			}
			for (x in 0...map.length) {
				for (y in 0...map[0].length) {
					var count = count_neighbours(old, x, y);

					if (old[x][y]) {
						if (count < death_limit) {
							map[x][y] = false;
						} else {
							map[x][y] = true;
						}
					} else {
						if (count > birth_limit) {
							map[x][y] = true;
						} else {
							map[x][y] = false;
						}
					}
				}
			}
		}

		return map;
	}

	// initial chance varies from 0.3 to 0.4, from least to most water
	var initial_chance = 0.25;
	var death_limit = 4;
	var birth_limit = 3;
	var iterations = 6;

	var water_colors = [Col.RED, Col.PINK, Col.ORANGE, Col.GREEN, Col.DARKBLUE, Col.BLUE, Col.YELLOW];
	var land_colors = [Col.WHITE, Col.RED, Col.PINK, Col.ORANGE, Col.DARKGREEN, Col.GREEN,
	Col.BROWN, Col.DARKBLUE, Col.BLUE];

	function generate_planet_image(planet: Planet) {
		var scale = 2;

		// Pick water and land colors, don't pick same
		var water_color = water_colors[Random.int(0, water_colors.length - 1)];
		land_colors.remove(water_color);
		var land_color = land_colors[Random.int(0, land_colors.length - 1)];
		land_colors.push(water_color);

		var swap_water_land = false;

		switch (planet.type) {
			case 1: {
				// waterless planets have darker land color instead of water
				// and water and land in game of life are swapped so that the
				// cells represent the land and space is darker patches
				initial_chance = Random.float(0.45, 0.53);
				swap_water_land = true;
				water_color = Col.rgb(
					Math.round(Col.r(land_color) * 0.85), 
					Math.round(Col.g(land_color) * 0.85), 
					Math.round(Col.b(land_color) * 0.85));
			}
			case 2: {
				// Medium planets have about earth ratio of land/water
				initial_chance = Random.float(0.36, 0.4);
			}
			case 3: {
				// mostly water, land is like islands
				initial_chance = Random.float(0.46, 0.48);
			}
		}

		var pixels = Data.int_2d_vector(Std.int(planet_size / scale), 
			Std.int(planet_size / scale));

		// Water is generated using the game of life, water = cells in the game
		var water_map = run_game_of_life(Std.int(planet_size / scale), 
			Std.int(planet_size / scale), 
			initial_chance, death_limit, birth_limit, iterations);

		for (x in 0...pixels.length) {
			for (y in 0...pixels[0].length) {
				if (swap_water_land) {
					if (!water_map[x][y]) {
						pixels[x][y] = water_color;
					} else {
						pixels[x][y] = land_color;
					}
				} else {
					if (water_map[x][y]) {
						pixels[x][y] = water_color;
					} else {
						pixels[x][y] = land_color;
					}
				}
			}
		}

		Gfx.draw_to_image(planet.name);
		Gfx.clear_screen_transparent();
		// Draw planet texture in circle area
		var circle_map = Math.fill_circle_map(Std.int(planet_size / scale / 2));
		for (x in 0...pixels.length) {
			for (y in 0...pixels[0].length) {
				if (circle_map[x][y]) {
					Gfx.fill_box(x * scale, y * scale, scale, scale, pixels[x][y]);
				}
			}
		}
		Gfx.draw_to_screen();
	}

	function generate_part_pixels(part: Ship_Part) {
		part.pixels[2][2] = true;
		var current_x = 2;
		var current_y = 2;
		var k = Random.int(5, 20);
		for (i in 0...k) {
			var dx_dy = four_dx_dy[Random.int(0, four_dx_dy.length - 1)];
			current_x += dx_dy.x;
			current_y += dx_dy.y;
			if (0 > current_x || current_x >= ship_part_width 
				|| 0 > current_y || current_y >= ship_part_height) 
			{
				current_x -= dx_dy.x;
				current_y -= dx_dy.y;
			}
			part.pixels[current_x][current_y] = true;
		}
	}

	function load_string_to_pixels(pixels: Vector<Vector<Bool>>, string: Array<String>) {
		var pixels_width = pixels.length;
		var string_width = string[0].length;
		var pixels_height = pixels[0].length;
		var string_height = string.length;
		if (pixels_width < string_width || pixels_height < string_height) {
			trace('ERROR: string array is bigger than pixels array');
			return;
		}

		for (x in 0...string_width) {
			for (y in 0...string_height) {
				if (string[y].charAt(x) == '#') {
					pixels[x][y] = true;
				}
			}
		}
	}

	function out_of_bound_ship(x, y) {
		return 0 > x || x >= ship_width || 0 > y || y >= ship_height; 
	}

	function out_of_bound_ship_inventory(x, y) {
		return ship_inventory_x > x || x >= ship_inventory_x + ship_inventory_background_width || ship_inventory_y > y 
		|| y >= ship_inventory_y + ship_inventory_background_height; 
	}

	function out_of_bound_planet_inventory(x, y) {
		return planet_inventory_x > x || x >= planet_inventory_x + planet_inventory_background_width 
		|| planet_inventory_y > y || y >= planet_inventory_y + planet_inventory_background_height; 
	}

	function out_of_bound_ship_edit(x, y) {
		return ship_edit_x > x || x >= ship_edit_x + ship_edit_width 
		|| ship_edit_y > y || y >= ship_edit_y + ship_edit_height; 
	}

	function ship_x(x) {
		return Math.round((x - ship_edit_x) / ship_pixel_size);
	}
	function ship_y(y) {
		return Math.round((y - ship_edit_y) / ship_pixel_size);
	}

	var four_dx_dy: Array<IntVector2> = 
	[{x: -1, y: 0}, {x: 1, y: 0}, {x: 0, y: 1}, {x: 0, y: -1}];

	function part_ship_intersect(part: Ship_Part) {
		for (x in 0...ship_part_width) {
			for (y in 0...ship_part_height) {
				if (part.pixels[x][y]) {
					for (dx_dy in four_dx_dy) {
						var this_x = ship_x(part.x) + x + dx_dy.x;
						var this_y = ship_y(part.y) + y + dx_dy.y;

						if (!out_of_bound_ship(this_x, this_y) 
							&& ship_pixels[this_x][this_y]) 
						{
							return true;
						}
					}
				}
			}
		}	

		return false;
	}

	function draw_item(item: Dynamic) {
		switch (item.item_type) {
			case ItemType_ShipPart: {
				var part: Ship_Part = item;

				// outline is red when not connecting ship, white when connecting
				var outline_color = Col.RED;
				if (item.intersecting_ship) {
					outline_color = Col.WHITE;
				}

				var pixels = part.pixels;
				for (x in 0...pixels.length) {
					for (y in 0...pixels[0].length) {
						if (pixels[x][y]) {
							Gfx.fill_box(
								part.x + x * ship_pixel_size, 
								part.y + y * ship_pixel_size,
								ship_pixel_size, ship_pixel_size, ship_color);
							// draw outline if the part is in ship edit area
							if (part.inventory_state == InventoryState_ShipEdit) {
								Gfx.draw_box(
									part.x + x * ship_pixel_size, 
									part.y + y * ship_pixel_size,
									ship_pixel_size, ship_pixel_size, outline_color);
							}
						}
					}
				}
			}
			case ItemType_Station: {
				if (item.station_type == StationType_Mining) {
					Gfx.draw_image(item.x, item.y, 'mining');
				} else if (item.station_type == StationType_Assembly) {
					Gfx.draw_image(item.x, item.y, 'assembly');
				}
			}
			case ItemType_Material: {
				Gfx.draw_image(item.x, item.y, 'material');
				Text.display(item.x + item_width / 2, item.y + item_height / 2, '${item.amount}');
			}
			default:
		}
	}

	function generate_damage() {
		var pixels = new Array<IntVector2>();
		for (x in 0...ship_width) {
			for (y in 0...ship_height) {
				if (ship_pixels[x][y]) {
					pixels.push({x: x, y: y});
				}
			}
		}	

		var random_pixel = pixels[Random.int(0, pixels.length - 1)];
		var current_x = random_pixel.x;
		var current_y = random_pixel.y;	

		var k = Random.int(5, 10);
		for (i in 0...k) {
			Random.shuffle(four_dx_dy);
			for (j in 0...four_dx_dy.length) {
				var dx_dy = four_dx_dy[j];
				current_x += dx_dy.x;
				current_y += dx_dy.y;
				if (0 > current_x || current_x >= ship_width 
					|| 0 > current_y || current_y >= ship_height
					|| !ship_pixels[current_x][current_y]) 
				{
					current_x -= dx_dy.x;
					current_y -= dx_dy.y;
				} else {
					ship_pixels[current_x][current_y] = false;
					destroyed_pixels[current_x][current_y] = true;

					break;
				}
			}
		}
	}

	function remove_vector(array: Array<IntVector2>, vector: IntVector2) {
		for (i in 0...array.length) {
			if (array[i].x == vector.x && array[i].y == vector.y) {
				array.splice(i, 1);
				break;
			}
		}
	}

	function contains_vector(array: Array<IntVector2>, vector: IntVector2) {
		for (v in array) {
			if (v.x == vector.x && v.y == vector.y) {
				return true;
			}
		}

		return false;
	}

	function get_fragments(): Array<Array<IntVector2>> {
		var pixels = new Array<IntVector2>();
		for (x in 0...ship_width) {
			for (y in 0...ship_height) {
				if (ship_pixels[x][y]) {
					pixels.push({x: x, y: y});
				}
			}
		}
		var fragments = new Array<Array<IntVector2>>();

		while (pixels.length > 0) {
			var fragment = new Array<IntVector2>();
			var fragment_edge = new Array<IntVector2>();
			fragment_edge.push(pixels[0]);

			while (fragment_edge.length > 0) {
				var edge = fragment_edge[0];
				for (dx_dy in four_dx_dy) {
					var x = edge.x + dx_dy.x;
					var y = edge.y + dx_dy.y;

					if (!out_of_bound_ship(x, y)
						&& ship_pixels[x][y]
						&& !contains_vector(fragment_edge, {x: x, y: y})
						&& !contains_vector(fragment, {x: x, y: y})) 
					{
						fragment_edge.push({x: x, y: y});
					}						
				}

				fragment.push(edge);
				fragment_edge.shift();
				remove_vector(pixels, edge);
			}

			fragments.push(fragment);
		}

		return fragments;
	}

	function clear_stray_fragments_2() {
		var fragments = new Array<Array<IntVector2>>();
		var pixels = new Array<IntVector2>();
		for (x in 0...ship_width) {
			for (y in 0...ship_height) {
				if (ship_pixels[x][y]) {
					pixels.push({x: x, y: y});
				}
			}
		}	

		while (pixels.length > 0) {
			var pixel = pixels[0];
			var fragment = new Array<IntVector2>();
			var fragment_edge = new Array<IntVector2>();
			fragment_edge.push(pixel);
			pixels.remove(pixel);

			while (fragment_edge.length > 0) {
				var edge = fragment_edge[0];
				var x = 0;
				var y = 0;
				for (dx_dy in four_dx_dy) {
					x = pixel.x + dx_dy.x;
					y = pixel.y + dx_dy.y;

					function contains_vector(array: Array<IntVector2>, vector: IntVector2) {
						for (v in array) {
							if (v.x == vector.x && v.y == vector.y) {
								return true;
							}
						}

						return false;
					}

					if (!out_of_bound_ship(x, y)
						&& !contains_vector(fragment_edge, {x: x, y: y})
						&& !contains_vector(fragment, {x: x, y: y})) 
					{
						fragment_edge.push({x: x, y: y});
					}						
				}

				fragment.push(edge);
				pixels.remove(fragment_edge.shift());
			}

			fragments.push(fragment);
		}

		var largest_size = 0;

		for (fragment in fragments) {
			if (fragment.length > largest_size) {
				largest_size = fragment.length;
			}
		}
		var skipped_one_largest = false;
		for (fragment in fragments) {
			if (fragment.length == largest_size && !skipped_one_largest) {
				// For edge case of more than one fragment of equal largest size
				// Only leave one
				skipped_one_largest = true;
			} else {
				for (pixel in fragment) {
					ship_pixels[pixel.x][pixel.y] = false;
					destroyed_pixels[pixel.x][pixel.y] = true;
				}
			}
		}
	}

	var dragged_item: Dynamic = null;
	var split_material: Material = null;
	var split_amount: Float = 0;
	var dragging_x: Float = 0;
	var dragging_y: Float = 0;

	function generate_star_particle(): Star_Particle {
		var particle = new Star_Particle();
		particle.width = Random.int(5, 40);
		particle.height = Random.int(2, 5);
		particle.x = -particle.width - Random.int(0, screen_width);
		particle.y = Random.int(0, screen_height - particle.height);
		particle.dx = 15;
		return particle;
	}

	function render_flying() {
		Gfx.clear_screen(Col.BLACK);

		for (particle in star_particles) {
			Gfx.fill_box(particle.x, particle.y, particle.width, particle.height, Col.WHITE);
		}

		// Ship base
		for (x in 0...ship_pixels.length) {
			for (y in 0...ship_pixels[0].length) {
				if (ship_pixels[x][y]) {
					Gfx.fill_box(
						flying_ship_x + x * ship_pixel_size, 
						flying_ship_y + y * ship_pixel_size,
						ship_pixel_size, ship_pixel_size, ship_color);
				}
			}
		}

		// Destroyed graphic
		for (x in 0...destroyed_pixels.length) {
			for (y in 0...destroyed_pixels[0].length) {
				if (destroyed_pixels[x][y]) {
					Gfx.fill_box(
						flying_ship_x + destroyed_graphic_x + x * ship_pixel_size, 
						flying_ship_y + destroyed_graphic_y + y * ship_pixel_size,
						ship_pixel_size, ship_pixel_size, ship_color);
				}
			}
		}

		Gfx.fill_box(20, planet_size / 2 - 2, (screen_width - 40), 
			4, Col.WHITE);
		Gfx.fill_box(20, planet_size / 2 - 2, 
			(flying_state_timer / flying_state_timer_max) * (screen_width - 40), 
			4, Col.BLACK);

		if (current_planet != null) {
			Gfx.draw_image(planet_size / 2, 0, current_planet.name);
		}
		if (previous_planet != null) {
			Gfx.draw_image(screen_width - planet_size, 0, 
				previous_planet.name);
		}
	}

	function update_flying() {
		flying_ship_x += Random.int(-1, 1);
		flying_ship_y += Random.int(-1, 1);

		var removed_particles = new Array<Star_Particle>();
		for (particle in star_particles) {
			particle.x += particle.dx;
			if (particle.x  > screen_width) {
				removed_particles.push(particle);
			}
		}
		for (particle in removed_particles) {
			star_particles.remove(particle);
			star_particles.push(generate_star_particle());
		}


		flying_state_timer--;
		
		if (flying_state_timer / flying_state_timer_max < flying_destruction_time 
			&& !started_destroyed_graphic) 
		{
			started_destroyed_graphic = true;
			generate_damage();
			destroyed_graphic_dy = Random.pick_int(-1, 1);
		}
		if (started_destroyed_graphic) {
			destroyed_graphic_x += Random.int(3, 5);
			destroyed_graphic_y += destroyed_graphic_dy * Random.int(0, 1);
		}

		if (flying_state_timer <= 0) {
			state = GameState_Planets;
			started_destroyed_graphic = false;
			for (x in 0...destroyed_pixels.length) {
				for (y in 0...destroyed_pixels[0].length) {
					destroyed_pixels[x][y] = false;
				}
			}
			destroyed_graphic_x = 0;
			destroyed_graphic_y = 0;

			// Clear stray fragments that are too small
			var fragments = get_fragments();
			for (fragment in fragments) {
				if (fragment.length <= stray_fragment_size) {
					for (pixel in fragment) {
						ship_pixels[pixel.x][pixel.y] = false;
					}
				}
			}
		}

		render_flying();
	}

	// Attach parts
	function attach_parts() {
		var attached_parts = new Array<Ship_Part>();

		// Attach all parts currently connected to ship
		for (part in parts) {
			if (part.inventory_state == InventoryState_ShipEdit && part_ship_intersect(part)) {
				attached_parts.push(part);

				for (x in 0...ship_part_width) {
					for (y in 0...ship_part_height) {
						if (part.pixels[x][y]) {
							var this_x = ship_x(part.x) + x;
							var this_y = ship_y(part.y) + y;

							if (!out_of_bound_ship(this_x, this_y)) {
								ship_pixels[this_x][this_y] = true;
							}

						}
					}
				}
			}
		}

		for (part in attached_parts) {
			parts.remove(part);
			items.remove(part);
		}

		// Recalculate intersect flag since it could've changed when parts were added
		for (part in parts) {
			if (part.inventory_state == InventoryState_ShipEdit) {
				part.intersecting_ship = part_ship_intersect(part);
			}
		}
	}

	function render_planets() {
		Gfx.clear_screen(Col.BLACK);

		for (planet in planets) {
			if (mouse_planet_intersect(planet)) {
				Gfx.line_thickness = 4;
				Gfx.draw_line(current_planet.x + planet_size / 2, 
					current_planet.y + planet_size / 2, 
					planet.x + planet_size / 2, planet.y + planet_size / 2, 
					Col.YELLOW);
				Gfx.line_thickness = 1;
				break;
			}
		}

		// Planets
		for (planet in planets) {
			Gfx.draw_image(planet.x, planet.y, planet.name);
		}

		// Planet stations
		for (planet in planets) {
			switch (planet.station) {
				case StationType_None:
				case StationType_Assembly: Text.display(planet.x, planet.y - 5, 'A', Col.WHITE);
				case StationType_Mining: Text.display(planet.x, planet.y - 5, 'M', Col.WHITE);
			}			
		}

		// Move ship graphic up and down
		planet_view_ship_y_move_timer++;
		if (planet_view_ship_y_move_timer > planet_view_ship_y_move_timer_max) {
			planet_view_ship_y_move_timer = 0;

			planet_view_ship_y += planet_view_ship_dy;
			if (Math.abs(planet_view_ship_y) > 5) {
				planet_view_ship_dy = -planet_view_ship_dy;
			}
		}

		// Ship near planet
		var ship_x = current_planet.x + planet_size * 1.5;
		var ship_y = current_planet.y + planet_size / 2;
		for (x in 0...ship_width) {
			for (y in 0...ship_height) {
				if (ship_pixels[x][y]) {
					Gfx.fill_box(
						ship_x + x, 
						ship_y + y + planet_view_ship_y,
						1, 1, ship_color);
				}
			}
		}

		
		// Ship edit
		Gfx.fill_box(ship_edit_x, ship_edit_y, ship_width * ship_pixel_size, 
			ship_height * ship_pixel_size, Col.DARKBLUE);
		for (x in 0...ship_width) {
			for (y in 0...ship_height) {
				if (ship_pixels[x][y]) {
					Gfx.fill_box(
						ship_edit_x + x * ship_pixel_size, 
						ship_edit_y + y * ship_pixel_size,
						ship_pixel_size, ship_pixel_size, ship_color);
				}
			}
		}

		// Attach button
		GUI.text_button(ship_edit_x - 200, ship_edit_y, 'Attach parts', attach_parts);

		// Ship inventory
		var ship_inventory_color = Col.rgb(
			Std.int(Math.min(255, Col.r(ship_color) * 1.3)),
			Std.int(Math.min(255, Col.g(ship_color) * 1.3)),
			Std.int(Math.min(255, Col.b(ship_color) * 1.3))
			);
		Gfx.fill_box(ship_inventory_x, ship_inventory_y, ship_inventory_background_width, 
			ship_inventory_background_height, ship_inventory_color);
		for (i in 0...ship_inventory.length) {
			if (ship_inventory[i] != null) {
				draw_item(ship_inventory[i]);
			}
		}
		Text.display(ship_inventory_x, ship_inventory_y - 40, 'Cargo');

		// Planet inventory
		Gfx.fill_box(planet_inventory_x, planet_inventory_y, planet_inventory_background_width, 
			planet_inventory_background_height, Col.GRAY);
		var planet_inventory = current_planet.inventory;
		for (i in 0...planet_inventory.length) {
			if (planet_inventory[i] != null) {
				draw_item(planet_inventory[i]);
			}
		}
		Text.display(planet_inventory_x, planet_inventory_y - 40, 'Planet storage');

		// Ship parts in ship edit area
		for (part in parts) {
			if (part.inventory_state == InventoryState_ShipEdit) {
				draw_item(part);
			}
		}

		// Dragged item
		if (dragged_item != null) {
			draw_item(dragged_item);
		}

		// Crafting GUI
		if (current_planet.station == StationType_Assembly) {
			Gfx.fill_box(crafting_x, crafting_y, crafting_background_width, 
				crafting_background_height, Col.YELLOW);
			Text.display(crafting_x, crafting_y - 40, 'Crafting');

			// Count materials in inventories
			var material_count = 0;
			for (i in 0...ship_inventory.length) {
				if (ship_inventory[i] != null && ship_inventory[i].item_type == ItemType_Material) {
					material_count += ship_inventory[i].amount;
				}
			}
			var planet_inventory = current_planet.inventory;
			for (i in 0...planet_inventory.length) {
				if (planet_inventory[i] != null && planet_inventory[i].item_type == ItemType_Material) {
					material_count += planet_inventory[i].amount;
				}
			}

			function subtract_material(amount: Int) {
				var amount_left = amount;

				var planet_inventory = current_planet.inventory;
				for (i in 0...planet_inventory.length) {
					if (planet_inventory[i] != null 
						&& planet_inventory[i].item_type == ItemType_Material) 
					{
						var material: Material = planet_inventory[i];

						if (amount_left >= material.amount) {
							// Item completely used up, delete it
							amount_left -= material.amount;
							items.remove(material);
							materials.remove(material);
							planet_inventory[i] = null;
						} else {
							// Item not used up all the way
							material.amount -= amount_left;
							amount_left = 0;							
							break;
						}
					}
				}

				// If planet inventory materials wasn't enough, move on to ship inventory
				if (amount_left > 0) {
					for (i in 0...ship_inventory.length) {
						if (ship_inventory[i] != null 
							&& ship_inventory[i].item_type == ItemType_Material) 
						{
							var material: Material = ship_inventory[i];

							if (amount_left >= material.amount) {
								// Item completely used up, delete it
								amount_left -= material.amount;
								items.remove(material);
								materials.remove(material);
								ship_inventory[i] = null;
							} else {
								// Item not used up all the way
								material.amount -= amount_left;
								amount_left = 0;							
								break;
							}
						}
					}
				}
			}

			GUI.x = crafting_x + 10;
			GUI.y = crafting_y + 10;
			GUI.auto_text_button('Craft Mining Station', function() {
				if (material_count >= mining_station_cost) {
					subtract_material(mining_station_cost);

					var m_station = new Station();
					stations.push(m_station);
					items.push(m_station);
					m_station.station_type = StationType_Mining;
					add_item_to_planet_inventory(m_station);
				}
			});
			GUI.auto_text_button('Craft Assembly Station', function() {
				if (material_count >= assembly_station_cost) {
					subtract_material(assembly_station_cost);

					var a_station = new Station();
					stations.push(a_station);
					items.push(a_station);
					a_station.station_type = StationType_Assembly;
					add_item_to_planet_inventory(a_station);
				}
			});
			GUI.auto_text_button('Craft Ship Part', function() {
				if (material_count >= ship_part_cost) {
					subtract_material(ship_part_cost);

					var part = new Ship_Part();
					parts.push(part);
					items.push(part);

					generate_part_pixels(part);
					add_item_to_planet_inventory(part);
				}
			});
		}


		// Splitting
		if (split_material != null) {
			// Split amount input box
			Gfx.fill_box(split_material.x + item_width, split_material.y + item_height, 
				item_width * 2, item_height, Col.BLACK);

			GUI.editable_number(split_material.x + item_width, split_material.y + item_height,
				'', function(x) { split_amount = x; }, split_amount);
		}

	}

	function mouse_planet_intersect(planet: Planet): Bool {
		return Math.dst(Mouse.x, Mouse.y, planet.x, planet.y) <= planet_size;
	}

	function position_in_ship_inventory(i: Int): IntVector2 {
		return {
			x: ship_inventory_x + i % ship_inventory_width * item_width,
			y: ship_inventory_y + Std.int(i / ship_inventory_width) * item_height
		};
	}

	function position_in_planet_inventory(i: Int): IntVector2 {
		return {
			x: planet_inventory_x + i % planet_inventory_width * item_width,
			y: planet_inventory_y + Std.int(i / planet_inventory_width) * item_height
		};
	}

	function add_item_to_ship_inventory(item) {
		for (i in 0...ship_inventory.length) {
			if (ship_inventory[i] == null) {
				ship_inventory[i] = item;
				item.inventory_state = InventoryState_ShipInventory;
				var position = position_in_ship_inventory(i);
				item.x = position.x;
				item.y = position.y;

				break;
			}
		}
	}

	function add_item_to_planet_inventory(item) {
		var planet_inventory = current_planet.inventory;
		for (i in 0...planet_inventory.length) {
			if (planet_inventory[i] == null) {
				planet_inventory[i] = item;
				item.inventory_state = InventoryState_PlanetInventory;
				var position = position_in_planet_inventory(i);
				item.x = position.x;
				item.y = position.y;

				break;
			}
		}
	}

	function mouse_item_intersect(item) {
		return Math.point_box_intersect(Mouse.x, Mouse.y, item.x, item.y, item_width, 
			item_height);
	}

	function update_planets() {

		if (Mouse.left_click()) {
			for (planet in planets) {
				if (planet != current_planet && mouse_planet_intersect(planet)) {
					state = GameState_Flying;

					flying_state_timer = flying_state_timer_max;
					flying_destruction_time = Random.float(0.3, 0.7);

					for (i in 0...star_particle_amount) {
						star_particles.push(generate_star_particle());
					}
					previous_planet = current_planet;
					current_planet = planet;

					// Move unattached parts back into planet inventory
					var planet_inventory = previous_planet.inventory;
					for (part in parts) {
						if (part.inventory_state == InventoryState_Dragged 
							|| part.inventory_state == InventoryState_ShipEdit) 
						{
							for (i in 0...planet_inventory.length) {
								if (planet_inventory[i] == null) {
									planet_inventory[i] = part;
									part.inventory_state = InventoryState_PlanetInventory;
									var position = position_in_planet_inventory(i);
									part.x = position.x;
									part.y = position.y;

									break;
								}
							}
						}
					}

					break;
				}
			}
		}

		// Item dragging
		if (dragged_item == null) {
			// Picking up
			if (Mouse.left_click()) {

				for (item in items) {
					// remove ship part width/height altogether
					if (mouse_item_intersect(item)) {
						dragged_item = item;
						dragging_x = Mouse.x - item.x;
						dragging_y = Mouse.y - item.y;

						// If item was in inventory, remove from inventory
						switch (dragged_item.inventory_state) {
							case InventoryState_ShipInventory: {
								// Remove item from ship inventory it was in
								for (i in 0...ship_inventory.length) {
									if (ship_inventory[i] == dragged_item) {
										ship_inventory[i] = null;

										break;
									}
								}
							}
							case InventoryState_PlanetInventory: {
								// Remove part from planet inventory it was in
								var planet_inventory = current_planet.inventory;
								for (i in 0...planet_inventory.length) {
									if (planet_inventory[i] == dragged_item) {
										planet_inventory[i] = null;

										break;
									}
								}
							}
							default:
						}

						dragged_item.inventory_state = InventoryState_Dragged;

						break;
					}
				}
			}
		} else {
			// Dropping
			// TODO: handle full inventory case
			// Handle dropping materials on materials, should stack
			// TODO: when stacking inside ship inventory, handle cases where stack goes over max
			// cargo capacity
			if (Mouse.left_released()) {
				if (!out_of_bound_ship_inventory(Mouse.x, Mouse.y)) {
					// Dropped in ship inventory

					function drop_dragged_into_ship_inventory() {
						for (i in 0...ship_inventory.length) {
							if (ship_inventory[i] == null) {
								ship_inventory[i] = dragged_item;
								dragged_item.inventory_state = InventoryState_ShipInventory;

								var position = position_in_ship_inventory(i);
								dragged_item.x = position.x;
								dragged_item.y = position.y;
								dragged_item = null;
								break;
							}
						}
					}

					if (dragged_item.item_type == ItemType_Material) {
						var stacked_material = false;

						// If material, check for stacking
						for (i in 0...ship_inventory.length) {
							if (ship_inventory[i] != null
								&& ship_inventory[i].item_type == ItemType_Material
								&& mouse_item_intersect(ship_inventory[i])) 
							{
								ship_inventory[i].amount += dragged_item.amount;

								// delete dropped item
								items.remove(dragged_item);
								materials.remove(dragged_item);
								dragged_item = null;
								stacked_material = true;

								break;
							}
						}

						if (!stacked_material) {
							// If no stack, drop regularly
							drop_dragged_into_ship_inventory();
						}
					} else {
						drop_dragged_into_ship_inventory();
					}
				} else if (!out_of_bound_ship_edit(Mouse.x, Mouse.y)
					&& dragged_item.item_type == ItemType_ShipPart) 
				{
					// Dropped in ship edit area
					// Only ship parts can be dropped here
					dragged_item.inventory_state = InventoryState_ShipEdit;
					dragged_item.intersecting_ship = part_ship_intersect(dragged_item);

					dragged_item.x = Math.round(dragged_item.x / ship_pixel_size) * ship_pixel_size;
					dragged_item.y = Math.round(dragged_item.y / ship_pixel_size) * ship_pixel_size;
					dragged_item = null;
				} else {
					// Dropped in planet inventory OR
					// Dropped outside of designated areas
					// In either case put into planet inventory

					var planet_inventory = current_planet.inventory;

					function drop_dragged_into_planet_inventory() {
						for (i in 0...planet_inventory.length) {
							if (planet_inventory[i] == null) {
								planet_inventory[i] = dragged_item;
								dragged_item.inventory_state = InventoryState_PlanetInventory;

								var position = position_in_planet_inventory(i);
								dragged_item.x = position.x;
								dragged_item.y = position.y;
								dragged_item = null;
								break;
							}
						}
					}

					if (dragged_item.item_type == ItemType_Material) {
						var stacked_material = false;

						// If material, check for stacking
						for (i in 0...planet_inventory.length) {
							if (planet_inventory[i] != null
								&& planet_inventory[i].item_type == ItemType_Material
								&& mouse_item_intersect(planet_inventory[i])) 
							{
								planet_inventory[i].amount += dragged_item.amount;

								// delete dropped item
								items.remove(dragged_item);
								materials.remove(dragged_item);
								dragged_item = null;
								stacked_material = true;

								break;
							}
						}

						if (!stacked_material) {
							// If no stack, drop regularly
							drop_dragged_into_planet_inventory();
						}
					} else {
						drop_dragged_into_planet_inventory();
					}
				}
			} else {
				dragged_item.x = Mouse.x - dragging_x;
				dragged_item.y = Mouse.y - dragging_y;
			}
		}

		// Splitting material stacks
		if (split_material == null) {
			// Select material to split
			if (Mouse.right_released()) {
				for (material in materials) {
					if (mouse_item_intersect(material)) {
						split_material = material;

						break;
					}
				}
			}
		} else {
			// Split, only if split amount isn't larger than total amount of material
			var split_amount_int = Std.int(split_amount);

			if (Input.just_pressed(Key.S)
				&& split_material.amount > split_amount_int) 
			{
				var material = new Material();
				materials.push(material);
				items.push(material);
				material.amount = split_amount_int;

				// put split item into same inventory as original stack
				if (split_material.inventory_state == InventoryState_ShipInventory) {
					add_item_to_ship_inventory(material);				
				} else if (split_material.inventory_state == InventoryState_PlanetInventory) {
					add_item_to_planet_inventory(material);				
				}

				split_material.amount -= split_amount_int;
				split_material = null;
			}
		}

		// Installing stations
		// overwrite current planet's station type and delete station item
		if (Mouse.right_released()) {
			var installed_station_already = false;

			for (i in 0...ship_inventory.length) {
				if (ship_inventory[i] != null 
					&& ship_inventory[i].item_type == ItemType_Station
					&& mouse_item_intersect(ship_inventory[i])) 
				{
					var station: Station = ship_inventory[i];

					current_planet.station = station.station_type;
					ship_inventory[i] = null;
					items.remove(station);
					stations.remove(station);

					installed_station_already = true;

					break;
				}
			}

			if (!installed_station_already) {
				var planet_inventory = current_planet.inventory;
				for (i in 0...planet_inventory.length) {
					if (planet_inventory[i] != null 
						&& planet_inventory[i].item_type == ItemType_Station
						&& mouse_item_intersect(planet_inventory[i])) 
					{
						var station: Station = ship_inventory[i];

						current_planet.station = station.station_type;
						ship_inventory[i] = null;
						items.remove(station);
						stations.remove(station);

						installed_station_already = true;

						break;
					}
				}			
			}
		}

		// Planets with mining stations mine materials
		for (planet in planets) {
			if (planet.station == StationType_Mining) {
				planet.mining_timer++;
				
				if (planet.mining_timer > Planet.mining_timer_max) {
					planet.mining_timer = 0;


					// TODO: add graphic of popping "+1" above planet
					var added_material = false;
					for (i in 0...planet.inventory.length) {
						if (planet.inventory[i] != null 
							&& planet.inventory[i].item_type == ItemType_Material) 
						{
							planet.inventory[i].amount += 1;
							added_material = true;
						}
					}

					if (!added_material) {
						// if planet inventory is full, no material is added, intentional!
						for (i in 0...planet.inventory.length) {
							if (planet.inventory[i] == null) {
								var material = new Material();
								materials.push(material);
								items.push(material);
								material.amount = 1;

								planet.inventory[i] = material;
								material.inventory_state = InventoryState_PlanetInventory;
								var position = position_in_planet_inventory(i);
								material.x = position.x;
								material.y = position.y;

								break;
							}
						}
					}
				}
			}
		}

		if (Input.just_pressed(Key.SPACE)) {
			var new_part = new Ship_Part();
			parts.push(new_part);
			items.push(new_part);

			generate_part_pixels(new_part);
			add_item_to_ship_inventory(new_part);
		}


		render_planets();

	}

	function update() {
		switch (state) {
			case GameState_Flying: update_flying();
			case GameState_Planets: update_planets();
		}

		Text.display(0, 0, 'Mouse: x=${Mouse.x} y=${Mouse.y}');
	}
}
