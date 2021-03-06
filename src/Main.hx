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
}

enum ItemType {
	ItemType_None;
	ItemType_Part;
	ItemType_Station;
	ItemType_Material;
}


@:publicFields
class Part {
	var item_type = ItemType_Part;
	var inventory_state = InventoryState_None;
	var dragged = false;
	var active = true;
	var x = 0;
	var y = 0;

	var intersecting_ship = false;
	var pixels = Data.bool_2d_vector(Main.part_width, Main.part_height);

	function new() {

	}
}

// "active" for items means that they are currently on screen, items in non-current planet inventories are inactive 

@:publicFields
class Station {
	var item_type = ItemType_Station;
	var inventory_state = InventoryState_None;
	var dragged = false;
	var active = true;
	var x = 0;
	var y = 0;

	var station_type = StationType_None;
	var level = 0;

	function new() {

	}
}

@:publicFields
class Material {
	var item_type = ItemType_Material;
	var inventory_state = InventoryState_None;
	var dragged = false;
	var active = true;
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
	var level = 0;
	var station = StationType_None;
	var station_level = 0;
	var mining_timer = 0;
	static var mining_timer_max_list = [0, 5 * 60, 3 * 60, 1 * 60]; // set based on level(first is 0 because levels span 1 to 3)

	var mining_graphic_on = false;
	var mining_graphic_timer = 0;
	static inline var mining_graphic_timer_max = 60;

	var inventory = new Vector<Dynamic>(Main.planet_inventory_size);

	var image_ready = false;

	function new() {

	}
}



@:publicFields
class Main {
	static inline var screen_width = 1000;
	static inline var screen_height = 1000;

	var state = GameState_Planets;

	static inline var part_width = 5;
	static inline var part_height = 5;
	static inline var item_width = 50;
	static inline var item_height = 50;
	var items = new Array<Dynamic>();
	var parts = new Array<Part>();
	var stations = new Array<Station>();
	var materials = new Array<Material>();

	static inline var planet_size = 64;
	static inline var planet_scale = 2;

	static inline var star_particle_amount = 15;
	var flying_state_timer = 0;
	var flying_state_timer_max = 1.2 * 60; // varies, set before flying to planet based on distance to planet
	var destruction_timer = 0;
	static inline var destruction_timer_max = 1 * 60;
	var flying_ship_x = 500;
	var flying_ship_y = 300;
	var star_particles = new Array<Star_Particle>();
	var destroyed_parts = new Array<Part>();
	var started_destroyed_graphic = false;
	var destroyed_pixels = Data.bool_2d_vector(ship_width, ship_height);
	var destroyed_graphic_x = 0;
	var destroyed_graphic_y = 0;
	var destroyed_graphic_dy = 0;
	// anything at this size or less gets destroyed when disconnected from the main ship
	var stray_fragment_size = 2; 

	var planets = new Array<Planet>();

	var previous_planet: Planet;
	var current_planet: Planet;
	static inline var distance_to_time = 1.0 / 250; // means that distance of 250 will take 1 second to travel

	var planet_view_ship_y = 0;
	var planet_view_ship_dy = 1;
	var planet_view_ship_y_move_timer = 0;
	var planet_view_ship_y_move_timer_max = 7;

	static inline var ui_x = 700;

	static inline var ship_edit_x = ui_x;
	static inline var ship_edit_y = 0;
	static inline var ship_pixel_size = 10;
	static inline var ship_width = 25;
	static inline var ship_height = 20;
	static inline var ship_edit_width = ship_width * ship_pixel_size;
	static inline var ship_edit_height = ship_height * ship_pixel_size;
	var ship_pixels = Data.bool_2d_vector(ship_width, ship_height);
	var ship_color = Col.DARKGREEN;

	static inline var ship_inventory_x = ui_x;
	static inline var ship_inventory_y = 250;
	static inline var ship_inventory_background_width = 250;
	static inline var ship_inventory_background_height = 100;
	static inline var ship_inventory_size = 10;
	static inline var ship_inventory_width = 5;
	var ship_inventory = new Vector<Dynamic>(ship_inventory_size);

	static inline var planet_inventory_x = ui_x;
	static inline var planet_inventory_y = 400;
	static inline var planet_inventory_background_width = 250;
	static inline var planet_inventory_background_height = 100;
	static inline var planet_inventory_size = 10;
	static inline var planet_inventory_width = 5;

	var trash_x = ui_x;
	var trash_y = 550;
	var trash_background_width = 100;
	var trash_background_height = 50;

	static inline var crafting_x = ui_x;
	static inline var crafting_y = 650;
	static inline var crafting_background_width = 300;
	static inline var crafting_background_height = 300;
	var craft_scroll = 0;
	static inline var scroll_hide_height = 40;
	static inline var scroll_area_x = crafting_x + crafting_background_width - 30;
	static inline var scroll_area_y = crafting_y + scroll_hide_height;
	static inline var scroll_area_width = 10;
	static inline var scroll_area_height = crafting_background_height - 2 * scroll_hide_height;
	static inline var scroll_slider_width = 10;
	static inline var scroll_slider_height = 40;
	var scrolling = false;

	static var mining_station_costs = [0, 5, 10, 15];
	static inline var assembly_station_cost = 10;
	static inline var part_cost = 1;

	var message_timer = 0;
	static inline var message_timer_max = 2 * 60;
	var message_queue = new Array<String>();

	var dragged_item: Dynamic = null;
	var split_material: Material = null;
	var split_amount: Float = 0;
	var dragging_x: Float = 0;
	var dragging_y: Float = 0;

	static inline var station_weight: Int = 5;
	var mining_station_weights = [0, 5, 10, 15];
	var assembly_station_weights = [0, 5];
	static inline var part_weight: Int = 1;
	var ship_size: Int = 0;
	var cargo_weight_max: Int = 0;

	var viewport_x = 0;
	var viewport_y = 0;
	static inline var viewport_width = screen_width;
	static inline var viewport_height = screen_height;
	static inline var viewport_scroll_speed = 7;

	static inline var planet_cell_size = 250;
	static inline var planet_map_size = 50;
	static inline var planet_map_scale = 2;


	function new() {
		Gfx.resize_screen(screen_width, screen_height, 1);
		Gfx.load_image("mining");		
		Gfx.load_image("assembly");		
		Gfx.load_image("material");	

		Text.change_size(16);


		load_string_to_pixels(ship_pixels, 
			[
			'....................',
			'....................',
			'....................',
			'....................',
			'....................',
			'....................',
			'............#.......',
			'.........######.....',
			'......############..',
			'.......###########..',
			'..........#####.....',
			'......###########...',
			'.......###########..',
			'....................',]);

		function make_planet(): Planet {
			var planet = new Planet();
			planets.push(planet);
			planet.x = -100;
			planet.y = -100;
			planet.name = generate_planet_name();
			planet.level = Random.int(1, 3); // 1 = dry, 2 = lots of water, 3 = medium
			
			// Skew levels down a bit
			if (Random.chance(75)) {
				planet.level = Std.int(Math.max(1, planet.level - 1));
			}

			var mining_timers = [2 * 60, 2 * 60, 2 * 60];
			Gfx.create_image(planet.name, planet_size, planet_size);

			return planet;
		}

		var edge_planets = new Array<Planet>();
		var new_edge_planets = new Array<Planet>();
		var edge_planet_angles = new Array<Planet>();


		var planet_map = run_game_of_life(planet_map_size, planet_map_size, 0.5, death_limit, birth_limit, 1);
		Gfx.create_image("planet map", planet_map_size * planet_map_scale, planet_map_size * planet_map_scale);
		Gfx.draw_to_image("planet map");
		for (x in 0... planet_map.length) {
			for (y in 0...planet_map[0].length) {
				if (!planet_map[x][y]) {
					Gfx.fill_box(x * planet_map_scale, y * planet_map_scale, planet_map_scale * 0.5, planet_map_scale * 0.5, Col.WHITE);
				}
			}
		}
		Gfx.draw_to_screen();

		for (x in 0...planet_map_size) {
			for (y in 0...planet_map_size) {
				if (!planet_map[x][y]) {
					var planet = make_planet();
					if (current_planet == null) {
						current_planet = planet;
					}
					planet.x = x * planet_cell_size + Random.int(-75, 75);
					planet.y = y * planet_cell_size + Random.int(-75, 75);
				}
			}
		}
		viewport_x = current_planet.x - 200;
		viewport_y = current_planet.y - 300;


		var m_station = new Station();
		stations.push(m_station);
		items.push(m_station);
		m_station.station_type = StationType_Mining;
		m_station.level = 1;
		add_to_planet_inventory(m_station);

		var a_station = new Station();
		stations.push(a_station);
		items.push(a_station);
		a_station.station_type = StationType_Assembly;
		a_station.level = 1;
		add_to_planet_inventory(a_station);

		// var material = new Material();
		// materials.push(material);
		// items.push(material);
		// material.amount = 123;
		// add_to_planet_inventory(material);


		update_ship_size_and_cargo_size();
	}

	function update_ship_size_and_cargo_size() {
		ship_size = 0;
		for (x in 0...ship_pixels.length) {
			for (y in 0...ship_pixels[0].length) {
				if (ship_pixels[x][y]) {
					ship_size++;
				}
			}
		}

		cargo_weight_max = Math.round(ship_size / 10);
	}

	function add_message(message: String) {
		message_queue.push(message);
	}

	function count_neighbours(map: Vector<Vector<Bool>>, x: Int, y: Int): Int {
		var count = 0;
		var neighbour_x: Int;
		var neighbour_y: Int;

		for (dx in -1...2) {
			for (dy in -1...2) {
				if (dx != 0 || dy != 0) {
					neighbour_x = x + dx;
					neighbour_y = y + dy;

					function out_of_bound(x, y) {
						return 0 > x || x >= map.length || 0 > y || y >= map[0].length;
					}

					if (dx == 0 && dy == 0) {
						continue;
					} else if (out_of_bound(neighbour_x, neighbour_y) || map[neighbour_x][neighbour_y]){
						count++;
					}
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

	var initial_chance = 0.25;
	var death_limit = 4;
	var birth_limit = 3;
	var iterations = 6;

	var water_colors = [Col.RED, Col.PINK, Col.ORANGE, Col.GREEN, Col.DARKBLUE, Col.BLUE, Col.YELLOW];
	var land_colors = [Col.WHITE, Col.RED, Col.PINK, Col.ORANGE, Col.DARKGREEN, Col.GREEN,
	Col.BROWN, Col.DARKBLUE, Col.BLUE];

	function generate_planet_image(planet: Planet) {

		// Pick water and land colors, don't pick same
		var water_color = water_colors[Random.int(0, water_colors.length - 1)];
		land_colors.remove(water_color);
		var land_color = land_colors[Random.int(0, land_colors.length - 1)];
		land_colors.push(water_color);

		switch (planet.level) {
			case 1: {
				// waterless planets have darker land color instead of water
				// and water and land in game of life are swapped so that the
				// cells represent the land and space is darker patches
				initial_chance = Random.float(0.45, 0.53);
				var temp = water_color;

				// swap water and land
				water_color = land_color;
				land_color = temp;

				water_color = Col.rgb(
					Math.round(Col.r(land_color) * 0.85), 
					Math.round(Col.g(land_color) * 0.85), 
					Math.round(Col.b(land_color) * 0.85));
			}
			case 2: {
				// mostly water, land is like islands
				initial_chance = Random.float(0.46, 0.48);
			}
			case 3: {
				// Medium planets have about earth ratio of land/water
				initial_chance = Random.float(0.36, 0.4);
			}
		}

		// Water is generated using the game of life, water = cells in the game
		var water_map = run_game_of_life(Std.int(planet_size / planet_scale), 
			Std.int(planet_size / planet_scale), 
			initial_chance, death_limit, birth_limit, iterations);

		Gfx.draw_to_image(planet.name);
		Gfx.clear_screen_transparent();
		// Draw planet texture in circle area
		var circle_map = Math.fill_circle_map(Std.int(planet_size / planet_scale / 2));
		for (x in 0...water_map.length) {
			for (y in 0...water_map[0].length) {
				if (circle_map[x][y]) {
					if (water_map[x][y]) {
						Gfx.fill_box(x * planet_scale, y * planet_scale, planet_scale, planet_scale, water_color);
					} else {
						Gfx.fill_box(x * planet_scale, y * planet_scale, planet_scale, planet_scale, land_color);
					}
				}
			}
		}
		Gfx.draw_to_screen();


		planet.image_ready = true;
	}

	var vowels = ['a', 'e', 'i', 'o', 'u'];
	var consonants = ['y', 'q', 'w', 'r', 't', 'p', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'z', 'x', 'c', 'v', 'b', 'n', 'm'];
	var generated_names = [""];
	function generate_planet_name(): String {

		function random_consonant(): String {
			return consonants[Random.int(0, consonants.length - 1)];
		}
		function random_vowel(): String {
			return vowels[Random.int(0, vowels.length - 1)];
		}

		var name = "";
		while (generated_names.indexOf(name) != -1) {
			var length = Random.int(2, 4);

			// Decrease number of 4 long names a bit
			if (Random.chance(50) && length == 4) {
				length = Random.int(2, 3);
			}
			
			for (i in 0...length) {
				var consonant_first = Random.bool();
				var consonant_only = Random.chance(25);
				var consonant = random_consonant();
				var vowel = random_vowel();

				if (consonant_only) {
					// sometimes only add a consonant
					name += random_consonant();
					if (Random.chance(10)) {
						name += consonant;
					}
				} if (consonant_first) {
					name += random_consonant();
					name += vowel;
					if (Random.chance(10)) {
						// sometimes double end vowel
						name += vowel;
					}
				} else {
					name += vowel;
					if (Random.chance(10)) {
						// sometimes double start vowel
						name += vowel;
					}
					name += random_consonant();
					if (Random.chance(10)) {
						// sometimes add another consonant
						name += random_consonant();
					}
				}

				// Capitalize first letter
				if (i == 0) {
					name = name.charAt(0).toUpperCase() + name.charAt(1);
				}
			}
		}

		generated_names.push(name);

		return name;
	}

	function generate_part_pixels(part: Part) {
		part.pixels[2][2] = true;
		var current_x = 2;
		var current_y = 2;
		var k = Random.int(5, 20);
		for (i in 0...k) {
			var dx_dy = four_dx_dy[Random.int(0, four_dx_dy.length - 1)];
			current_x += dx_dy.x;
			current_y += dx_dy.y;
			if (0 > current_x || current_x >= part_width 
				|| 0 > current_y || current_y >= part_height) 
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

	function ship_x(x) {
		return Math.round((x - ship_edit_x) / ship_pixel_size);
	}
	function ship_y(y) {
		return Math.round((y - ship_edit_y) / ship_pixel_size);
	}

	var four_dx_dy: Array<IntVector2> = 
	[{x: -1, y: 0}, {x: 1, y: 0}, {x: 0, y: 1}, {x: 0, y: -1}];

	function part_ship_intersect(part: Part) {
		for (x in 0...part_width) {
			for (y in 0...part_height) {
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
			case ItemType_Part: {
				var part: Part = item;

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
				Text.display(item.x + 35, item.y + 20, '${item.level}', Col.WHITE);
			}
			case ItemType_Material: {
				Gfx.draw_image(item.x, item.y, 'material');
				Text.display(item.x, item.y + 20, '${item.amount}');
			}
			case ItemType_None:
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

		// Scale damage with ship size
		var k = Math.round(ship_size * 0.1 * Random.float(0.75, 1.25));
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

		Gfx.fill_box(planet_size, planet_size / 2 - 2, (screen_width - 40), 
			4, Col.WHITE);
		Gfx.fill_box(planet_size, planet_size / 2 - 2, 
			(1 - flying_state_timer / flying_state_timer_max) * (screen_width - 40), 
			4, Col.BLACK);

		if (current_planet != null) {
			Gfx.draw_image(planet_size / 2, 0, current_planet.name);
			Text.display(planet_size / 2, planet_size + 10, '${current_planet.name}');
		}
		if (previous_planet != null) {
			Gfx.draw_image(screen_width - planet_size, 0, previous_planet.name);
			Text.display(screen_width - Text.width('${previous_planet.name}'), planet_size + 10, 
				'${previous_planet.name}');
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


		// at max, remove previous destruction, create new one, reset position
		destruction_timer++;
		if (destruction_timer > destruction_timer_max) {
			destruction_timer = 0;
			// Clear previous destruction
			for (x in 0...destroyed_pixels.length) {
				for (y in 0...destroyed_pixels[0].length) {
					destroyed_pixels[x][y] = false;
				}
			}
			// Generate new one
			generate_damage();
			destroyed_graphic_dy = Random.pick_int(-1, 1);
			destroyed_graphic_x = 0;
			destroyed_graphic_y = 0;
		}

		// Move destroyed graphic
		destroyed_graphic_x += Random.int(3, 5);
		destroyed_graphic_y += destroyed_graphic_dy * Random.int(0, 1);

		flying_state_timer++;

		if (flying_state_timer > flying_state_timer_max) {
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
			update_ship_size_and_cargo_size();

			// Recenter viewport
			viewport_x = current_planet.x - 300;
			viewport_y = current_planet.y - 450;
		}

		render_flying();
	}

	// Attach parts
	function attach_parts() {
		var attached_parts = new Array<Part>();

		// Attach all parts currently connected to ship
		for (part in parts) {
			if (part.inventory_state == InventoryState_ShipEdit && part_ship_intersect(part)) {
				attached_parts.push(part);

				for (x in 0...part_width) {
					for (y in 0...part_height) {
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
		update_ship_size_and_cargo_size();

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

	function inventory_has_space(inventory: Vector<Dynamic>) {
		for (i in 0...inventory.length) {
			if (inventory[i] == null) {
				return true;
			}
		}

		return false;
	}

	function planet_in_viewport(planet: Planet): Bool {
		return Math.box_box_intersect(planet.x, planet.y, planet_size, planet_size, 
			viewport_x, viewport_y, viewport_width, viewport_height);
	}

	// Interact zone ends at the ui line
	function planet_in_interact(planet: Planet): Bool {
		return Math.box_box_intersect(planet.x, planet.y, planet_size, planet_size, 
			viewport_x, viewport_y, ui_x, viewport_height);
	}

	function render_planets() {
		Gfx.clear_screen(Col.BLACK);

		for (planet in planets) {
			if (mouse_planet_intersect(planet) && planet_in_interact(planet)) {
				Gfx.line_thickness = 4;
				Gfx.draw_line(
					(current_planet.x - viewport_x) + planet_size / 2, 
					(current_planet.y - viewport_y) + planet_size / 2, 
					(planet.x - viewport_x) + planet_size / 2, 
					(planet.y - viewport_y) + planet_size / 2, 
					Col.YELLOW);
				Gfx.line_thickness = 1;
				break;
			}
		}


		// TODO: optimize by putting it all in the same loop? less intersect calls

		var generated_planet_this_frame = false;

		// Planets
		for (planet in planets) {
			if (planet_in_viewport(planet)) { 
				// generate one planet per frame, space it out
				if (!generated_planet_this_frame && !planet.image_ready) {
					generate_planet_image(planet);
					generated_planet_this_frame = true;
				}

				if (!planet.image_ready) {
					if (!generated_planet_this_frame) {
						generate_planet_image(planet);
						generated_planet_this_frame = true;
					}
					Gfx.fill_circle(planet.x - viewport_x + planet_size / 2, planet.y - viewport_y + planet_size / 2, 
						planet_size / 2, Col.GRAY);
				} else {
					Gfx.draw_image(planet.x - viewport_x, planet.y - viewport_y, planet.name);
				}
			}
		}


		// Planet stations
		for (planet in planets) {
			if (planet_in_viewport(planet)) {
				switch (planet.station) {
					case StationType_None:
					case StationType_Assembly: {
						Text.display(planet.x - viewport_x, planet.y - viewport_y - 5, 'A${planet.station_level}', Col.WHITE);
					}
					case StationType_Mining: {
						Text.display(planet.x - viewport_x, planet.y - viewport_y - 5, 'M${planet.station_level}', Col.WHITE);
					}	
				}
			}
		}

		// Planet mining graphic
		for (planet in planets) {
			if (planet.mining_graphic_on && planet_in_viewport(planet)) {
				var graphic_progress = planet.mining_graphic_timer / Planet.mining_graphic_timer_max;
				var c = Math.round((1 - graphic_progress) * 255);
				Text.display(planet.x - viewport_x + planet_size / 2, planet.y - viewport_y - graphic_progress * 10, 
					'+1', Col.rgb(c, c, c));
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
		var ship_x = current_planet.x - viewport_x + planet_size * 1.5;
		var ship_y = current_planet.y - viewport_y + planet_size / 2;
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

		// TODO: remove this, just for debug
		// Ship stats
		Text.display(500, ship_edit_y + 40, 'Size: ${ship_size}');

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
				// gray out dragged item(this is the old location image of dragged item)
				// TODO: transparency might be very slow on html5, i dont remember, maybe just dither
				if (ship_inventory[i].dragged) {
					Gfx.fill_box(ship_inventory[i].x, ship_inventory[i].y, item_width, item_height, Col.BLACK, 0.2);
				}
			}

			// TODO: could optimize this by keeping track of x and y variables
			var position = position_in_ship_inventory(i);
			// Border
			Gfx.draw_box(position.x, position.y, item_width, item_height, Col.ORANGE);
		}
		Text.display(ship_inventory_x, ship_inventory_y - 40, 'Cargo ${cargo_weight()} / ${cargo_weight_max}');

		// Planet inventory
		Gfx.fill_box(planet_inventory_x, planet_inventory_y, planet_inventory_background_width, 
			planet_inventory_background_height, Col.GRAY);
		var planet_inventory = current_planet.inventory;
		for (i in 0...planet_inventory.length) {
			if (planet_inventory[i] != null) {
				draw_item(planet_inventory[i]);

				// gray out dragged item(this is the old location image of dragged item)
				// TODO: transparency might be very slow on html5, i dont remember, maybe just dither
				if (planet_inventory[i].dragged) {
					Gfx.fill_box(planet_inventory[i].x, planet_inventory[i].y, item_width, item_height, Col.BLACK, 0.2);
				}
			}

			// TODO: could optimize this by keeping track of x and y variables
			var position = position_in_planet_inventory(i);
			// Border
			Gfx.draw_box(position.x, position.y, item_width, item_height, Col.ORANGE);
		}
		Text.display(planet_inventory_x, planet_inventory_y - 40, 'Planet storage');

		// Parts in ship edit area
		for (part in parts) {
			if (part.inventory_state == InventoryState_ShipEdit && !part.dragged) {
				draw_item(part);
			}
		}

		// Trash
		Gfx.fill_box(trash_x, trash_y, trash_background_width, trash_background_height, Col.GRAY);
		Text.display(trash_x, trash_y, 'Delete', Col.WHITE);

		// Dragged item image at mouse cursor
		// another image is drawn at old location
		if (dragged_item != null) {
			// Draw at mouse position
			var temp_x = dragged_item.x;
			var temp_y = dragged_item.y;
			dragged_item.x = Mouse.x - dragging_x;
			dragged_item.y = Mouse.y - dragging_y;
			draw_item(dragged_item);
			dragged_item.x = temp_x;
			dragged_item.y = temp_y;
		}

		// Crafting GUI
		if (current_planet.station == StationType_Assembly) {
			Gfx.fill_box(crafting_x, crafting_y, crafting_background_width, 
				crafting_background_height, Col.YELLOW);
			Text.display(crafting_x, crafting_y - 40, 'Crafting');

			var button_x = crafting_x + 10;
			var button_y: Float = crafting_y + scroll_hide_height - craft_scroll;
			var text_height = Text.height();
			var button_height = text_height * 1.25;
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

			function out_of_scroll_bound(y: Float): Bool {
				return crafting_y >= y || y >= crafting_y + crafting_background_height;
			}

			function test_space(): Bool {
				if (inventory_has_space(current_planet.inventory)) {
					return true;
				} else {
					add_message('No space in Planet Storage for crafting');
					return false;
				}
			}
			function test_cost(cost): Bool {
				if (material_count >= cost) {
					return true;
				} else {
					add_message('Not enough material for crafting');
					return false;
				}
			}

			function subtract_material(amount: Int) {
				var amount_left = amount;

				function subtract_material_from_inventory(inventory: Vector<Dynamic>) {
					for (i in 0...inventory.length) {
						if (inventory[i] != null 
							&& inventory[i].item_type == ItemType_Material) 
						{
							var material: Material = inventory[i];

							if (amount_left >= material.amount) {
								// Item completely used up, delete it
								amount_left -= material.amount;
								items.remove(material);
								materials.remove(material);
								inventory[i] = null;
							} else {
								// Item not used up all the way
								material.amount -= amount_left;
								amount_left = 0;							
								break;
							}
						}
					}
				}

				subtract_material_from_inventory(current_planet.inventory);
				// If planet inventory materials wasn't enough, move on to ship inventory
				if (amount_left > 0) {
					subtract_material_from_inventory(ship_inventory);
				}
			}

			function craft_mining_station_button(level: Int) {
				GUI.text_button(button_x, button_y, 'Craft Mining Station ${level}, cost: ${mining_station_costs[level]}', function() {
					if (test_space() && test_cost(mining_station_costs[level])) {
						subtract_material(mining_station_costs[level]);

						var m_station = new Station();
						m_station.level = level;
						stations.push(m_station);
						items.push(m_station);
						m_station.station_type = StationType_Mining;
						add_to_planet_inventory(m_station);
					}
				});
			}

			function crafting_buttons(button_n: Int) {
				switch (button_n) {
					case 0: {
						GUI.text_button(button_x, button_y, 'Craft Ship Part ${part_cost}', function() {
							if (test_space() && test_cost(part_cost)) {
								subtract_material(part_cost);

								var part = new Part();
								parts.push(part);
								items.push(part);

								generate_part_pixels(part);
								add_to_planet_inventory(part);
							}
						});
					}
					case 1: {
						GUI.text_button(button_x, button_y, 'Craft Assembly Station ${assembly_station_cost}', function() {
							if (test_space() && test_cost(assembly_station_cost)) {
								subtract_material(assembly_station_cost);

								var a_station = new Station();
								stations.push(a_station);
								items.push(a_station);
								a_station.station_type = StationType_Assembly;
								add_to_planet_inventory(a_station);
							}
						});
					}
					case 2: {
						craft_mining_station_button(1);
					}
					case 3: {
						craft_mining_station_button(2);
					}
					case 4: {
						craft_mining_station_button(3);
					}
				}
			}

			for (i in 0...5) {
				if (!out_of_scroll_bound(button_y)) {
					crafting_buttons(i);
				}
				button_y += (button_height + 2);
			}


			// Top and bottom borders to hide scroll culling
			Gfx.fill_box(crafting_x, crafting_y, crafting_background_width, scroll_hide_height, Col.YELLOW);
			Gfx.fill_box(crafting_x, crafting_y + crafting_background_height - scroll_hide_height, crafting_background_width, 
				scroll_hide_height, Col.YELLOW);

			// Slider
			Gfx.fill_box(scroll_area_x, scroll_area_y, scroll_area_width, 
				crafting_background_height - 2 * scroll_hide_height, Col.GRAY);
			Gfx.fill_box(scroll_area_x, scroll_area_y + craft_scroll, scroll_area_width,
				scroll_slider_height, Col.WHITE);
		}


		// Planet hover tooltip
		for (planet in planets) {
			if (mouse_planet_intersect(planet)
				&& planet_in_interact(planet))
			{
				// Planet name
				Text.display(planet.x - viewport_x + planet_size, planet.y - viewport_y + planet_size - 30, '${planet.name}(${planet.level})');

				// Remote planet inventory
				if (planet != current_planet) {
					var draw_x = planet.x - viewport_x;
					var draw_y = planet.y - viewport_y + planet_size + 10;
					Gfx.fill_box(draw_x, draw_y, planet_inventory_background_width, 
						planet_inventory_background_height, Col.GRAY);
					var planet_inventory = planet.inventory;
					var dx = draw_x - planet_inventory_x;
					var dy = draw_y - planet_inventory_y;
					for (i in 0...planet_inventory.length) {
						if (planet_inventory[i] != null) {
							planet_inventory[i].x += dx;
							planet_inventory[i].y += dy;
							draw_item(planet_inventory[i]);
							planet_inventory[i].x -= dx;
							planet_inventory[i].y -= dy;
						}

						// TODO: could optimize this by keeping track of x and y variables
						var position = position_in_planet_inventory(i);
						// Border
						Gfx.draw_box(position.x + dx, position.y + dy, item_width, item_height, Col.ORANGE);
					}
				}
			}
		}


		// Splitting
		if (split_material != null) {
			// Split amount input box
			Gfx.fill_box(split_material.x + item_width, split_material.y + item_height, 
				item_width * 2, item_height, Col.BLACK);

			GUI.editable_number(split_material.x + item_width, split_material.y + item_height,
				'', function(x) { split_amount = x; }, split_amount);
		}

		Gfx.draw_image(0, 0, "planet map");
		Gfx.fill_box(viewport_x / planet_cell_size * planet_map_scale, viewport_y / planet_cell_size * planet_map_scale, 4, 4, Col.YELLOW);
	}

	function mouse_planet_intersect(planet: Planet): Bool {
		return Math.dst(Mouse.x, Mouse.y, planet.x - viewport_x + planet_size / 2, 
			planet.y - viewport_y + planet_size / 2) <= planet_size / 2;
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

	function add_to_ship_inventory(item) {
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

	function add_to_planet_inventory(item) {
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

	function destroy_item(item: Dynamic) {
		items.remove(item);
		switch (item.item_type) {
			case ItemType_Material: materials.remove(item);
			case ItemType_Station: stations.remove(item);
			case ItemType_Part: parts.remove(item);
			case ItemType_None:
		}
	}

	function item_weight(item: Dynamic): Int {
		switch (item.item_type) {
			case ItemType_Material: return item.amount;
			case ItemType_Station: {
				switch (item.station_type) {
					case StationType_Assembly: return assembly_station_weights[item.level];
					case StationType_Mining: return mining_station_weights[item.level];
					case StationType_None:
				}
			}
			case ItemType_Part: return part_weight;
			case ItemType_None:
		}

		return 0;
	}

	function cargo_weight(): Int {
		var current_weight = 0;

		for (i in 0...ship_inventory.length) {
			if (ship_inventory[i] != null && !ship_inventory[i].dragged) {
				current_weight += item_weight(ship_inventory[i]);
			}
		}

		return current_weight;

		var weight_left = cargo_weight_max - current_weight;
		if (weight_left > 0) {
			return weight_left;
		} else {
			return 0;
		}
	}

	function update_planets() {

		// Item dragging
		if (dragged_item == null && split_material == null) {
			// Picking up
			if (Mouse.left_click()) {
				for (item in items) {
					if (item.active && mouse_item_intersect(item)) {
						dragged_item = item;
						dragged_item.dragged = true;
						dragging_x = Mouse.x - item.x;
						dragging_y = Mouse.y - item.y;

						break;
					}
				}
			}
		} else if (Mouse.left_released() && dragged_item != null) {

			function remove_from_inventory(item: Dynamic) {
				// call before modifying inventory state to new one!
				var inventory = null;

				switch (item.inventory_state) {
					case InventoryState_ShipInventory: inventory = ship_inventory;
					case InventoryState_PlanetInventory: inventory = current_planet.inventory;
					default:
				}

				if (inventory != null) {
					for (i in 0...inventory.length) {
						if (inventory[i] == item) {
							inventory[i] = null;
							break;
						}
					}
				}
			}

			var mouse_in_ship_edit = Math.point_box_intersect(Mouse.x, Mouse.y, ship_edit_x, ship_edit_y, ship_edit_width, ship_edit_height);
			var mouse_in_ship_inventory = Math.point_box_intersect(Mouse.x, Mouse.y, ship_inventory_x, ship_inventory_y, 
				ship_inventory_background_width, ship_inventory_background_height);
			var mouse_in_planet_inventory = Math.point_box_intersect(Mouse.x, Mouse.y, planet_inventory_x, planet_inventory_y, 
				planet_inventory_background_width, planet_inventory_background_height);
			var mouse_in_trash = Math.point_box_intersect(Mouse.x, Mouse.y, trash_x, trash_y, trash_background_width, trash_background_height);

			// Dropping
			if (mouse_in_ship_edit
				&& dragged_item.item_type == ItemType_Part) 
			{
				// Dropped in ship edit area
				// Only ship parts can be dropped here
				remove_from_inventory(dragged_item);
				dragged_item.inventory_state = InventoryState_ShipEdit;
				dragged_item.x = Math.round((Mouse.x - dragging_x) / ship_pixel_size) * ship_pixel_size;
				dragged_item.y = Math.round((Mouse.y - dragging_y) / ship_pixel_size) * ship_pixel_size;
				dragged_item.intersecting_ship = part_ship_intersect(dragged_item);
				
				dragged_item.dragged = false;
				dragged_item = null;
			} else if (mouse_in_ship_inventory) {
				// Dropped in ship inventory

				var stack_target: Material = null;
				if (dragged_item.item_type == ItemType_Material) {
					for (i in 0...ship_inventory.length) {
						if (ship_inventory[i] != null
							&& ship_inventory[i].item_type == ItemType_Material
							&& !ship_inventory[i].dragged // don't stack with itself
							&& mouse_item_intersect(ship_inventory[i])) 
						{
							stack_target = ship_inventory[i];
							break;
						}
					}
				}


				if (dragged_item.item_type == ItemType_Material
					&& stack_target != null) 
				{
					// Material stacking

					if (dragged_item.amount + cargo_weight() > cargo_weight_max) {
						// No weight space, return to old location
						add_message('Ship cargo weight limit reached');
						dragged_item.dragged = false;
						dragged_item = null;
					} else {
						// Add amount to static material, delete dragged material
						stack_target.amount += dragged_item.amount;

						remove_from_inventory(dragged_item);
						destroy_item(dragged_item);
						dragged_item = null;
					}
				} else if (!inventory_has_space(ship_inventory)) {
					// No slot space, return to old location
					add_message('Ship cargo is full');
					dragged_item.dragged = false;
					dragged_item = null;
				} else if (item_weight(dragged_item) + cargo_weight() > cargo_weight_max) {
					// No weight space
					add_message('Ship cargo weight limit reached');
					dragged_item.dragged = false;
					dragged_item = null;
				} else {
					// There is space, drop normally

					if (dragged_item.inventory_state == InventoryState_ShipInventory) {
						// If item wasn't moved to different area, only reset the item
						dragged_item.dragged = false;
						dragged_item = null;
					} else {
						// Otherwise, remove from old inventory and move to new location
						for (i in 0...ship_inventory.length) {
							if (ship_inventory[i] == null) {
								remove_from_inventory(dragged_item);
								add_to_ship_inventory(dragged_item);

								dragged_item.dragged = false;
								dragged_item = null;
								break;
							}
						}
					}
				}
			} else if (mouse_in_planet_inventory) {
				// Dropped in planet inventory

				var planet_inventory = current_planet.inventory;

				var stack_target: Material = null;
				if (dragged_item.item_type == ItemType_Material) {
					for (i in 0...planet_inventory.length) {
						if (planet_inventory[i] != null
							&& planet_inventory[i].item_type == ItemType_Material
							&& !planet_inventory[i].dragged // don't stack with itself
							&& planet_inventory[i].active // don't stack on top of inactive(in other planet's inventories) items
							&& mouse_item_intersect(planet_inventory[i])) 
						{
							stack_target = planet_inventory[i];
							break;
						}
					}
				}

				if (dragged_item.item_type == ItemType_Material
					&& stack_target != null) 
				{
					// Material stacking
					stack_target.amount += dragged_item.amount;

					remove_from_inventory(dragged_item);
					destroy_item(dragged_item);
					dragged_item = null;
				} else if (!inventory_has_space(planet_inventory)) {
					// No slot space, return to old location
					add_message('Planet storage is full');
					dragged_item.dragged = false;
					dragged_item = null;
				} else {
					// There is space, drop normally

					if (dragged_item.inventory_state == InventoryState_PlanetInventory) {
						dragged_item.dragged = false;
						dragged_item = null;
					} else {
						for (i in 0...planet_inventory.length) {
							if (planet_inventory[i] == null) {
								remove_from_inventory(dragged_item);
								dragged_item.inventory_state = InventoryState_PlanetInventory;
								planet_inventory[i] = dragged_item;

								var position = position_in_planet_inventory(i);
								dragged_item.x = position.x;
								dragged_item.y = position.y;
								dragged_item.dragged = false;
								dragged_item = null;
								break;
							}
						}
					}
				}
			} else if (mouse_in_trash) {
				// Delete item
				remove_from_inventory(dragged_item);
				destroy_item(dragged_item);
				dragged_item = null;
			} else {
				// Dropped outside of designated areas, return to old location
				dragged_item.dragged = false;
				dragged_item = null;
			}
		}

		// Splitting material stacks
		if (split_material == null && dragged_item == null) {
			// Select material to split
			if (Mouse.right_released()) {
				for (material in materials) {
					if (material.active && mouse_item_intersect(material)) {
						split_material = material;

						break;
					}
				}
			}
		} else if (split_material != null) {
			// Split, only if split amount isn't larger than total amount of material
			var split_amount_int = Std.int(split_amount);

			function test_space(inventory_state: InventoryState): Bool {
				var has_space = false;

				if (inventory_state == InventoryState_ShipInventory) {
					has_space = inventory_has_space(ship_inventory);
				} else if (inventory_state == InventoryState_PlanetInventory) {
					has_space = inventory_has_space(current_planet.inventory);
				}

				if (!has_space) {
					add_message('Not enough space to split');
				}

				return has_space;
			}

			if (Input.just_pressed(Key.S)
				&& split_material.amount > split_amount_int
				&& test_space(split_material.inventory_state)) 
			{
				var material = new Material();
				materials.push(material);
				items.push(material);
				material.amount = split_amount_int;

				// put split item into same inventory as original stack
				if (split_material.inventory_state == InventoryState_ShipInventory) {
					add_to_ship_inventory(material);				
				} else if (split_material.inventory_state == InventoryState_PlanetInventory) {
					add_to_planet_inventory(material);				
				}

				split_material.amount -= split_amount_int;
				split_material = null;
			}
		}

		// Installing stations
		// overwrite current planet's station type and delete station item
		if (Mouse.right_released()) {
			var installed_station_from_ship_inventory = false;

			function try_install_station(inventory: Vector<Dynamic>): Bool {
				for (i in 0...inventory.length) {
					if (inventory[i] != null 
						&& inventory[i].item_type == ItemType_Station
						&& mouse_item_intersect(inventory[i])) 
					{
						var station: Station = inventory[i];

						current_planet.station = station.station_type;
						current_planet.station_level = station.level;
						inventory[i] = null;
						items.remove(station);
						stations.remove(station);

						return true;
					}
				}

				return false;
			}

			var installed_already = try_install_station(ship_inventory);
			if (!installed_already) {
				try_install_station(current_planet.inventory);
			}
		}


		// Auto-attach part, pick random pixel, go in random direction until reaching empty cell or ship edit area border, 
		// place part down, using a random part pixel as the "anchor"
		// NOTE: placement is not smart at all, the only guarantee is that the part will cover a single space that 
		// is adjacent to the ship
		if (Mouse.right_click()) {
			function try_attach_part(inventory: Vector<Dynamic>) {
				for (i in 0...inventory.length) {
					if (inventory[i] != null && inventory[i].active && inventory[i].item_type == ItemType_Part
						&& mouse_item_intersect(inventory[i])) 
					{
						var part: Part = inventory[i];

						var pixels = new Array<IntVector2>();
						for (x in 0...ship_width) {
							for (y in 0...ship_height) {
								if (ship_pixels[x][y]) {
									pixels.push({x: x, y: y});
								}
							}
						}

						// Pick random pixel on ship, move in random direction from it
						// When out of bounds or at ship border, stop
						var current_position = pixels[Random.int(0, pixels.length - 1)];
						var random_direction = four_dx_dy[Random.int(0, four_dx_dy.length - 1)];
						var went_out_of_bounds = true;
						current_position.x += random_direction.x;
						current_position.y += random_direction.y;
						while (!out_of_bound_ship(current_position.x, current_position.y)) {
							if (!ship_pixels[current_position.x][current_position.y]) {
								// Reached ship border
								went_out_of_bounds = false;
								break;
							}
							current_position.x += random_direction.x;
							current_position.y += random_direction.y;
						}

						// Retrace back to inside ship edit area if went out of bounds
						if (went_out_of_bounds) {
							current_position.x -= random_direction.x;
							current_position.y -= random_direction.y;
						}

						// Put down part at this location with random offset
						var part_pixels = new Array<IntVector2>();
						for (x in 0...part_width) {
							for (y in 0...part_height) {
								if (part.pixels[x][y]) {
									part_pixels.push({x: x, y: y});
								}
							}
						}						

						var random_pixel = part_pixels[Random.int(0, part_pixels.length - 1)];

						var new_x = current_position.x - random_pixel.x;
						var new_y = current_position.y - random_pixel.y;

						part.x = ship_edit_x + new_x * ship_pixel_size;
						part.y = ship_edit_y + new_y * ship_pixel_size;

						inventory[i] = null;
						part.inventory_state = InventoryState_ShipEdit;

						part.intersecting_ship = part_ship_intersect(part);

						return true;
					}
				}

				return false;
			}

			var attached_already = try_attach_part(ship_inventory);
			if (!attached_already) {
				try_attach_part(current_planet.inventory);
			}	
		}

		// Crafting area scroll slider
		if (!scrolling) {
			if (Mouse.left_held() && Math.point_box_intersect(Mouse.x, Mouse.y, scroll_area_x, scroll_area_y,
				scroll_area_width, scroll_area_height)) 
			{
				craft_scroll = Mouse.y - scroll_area_y;
				scrolling = true;
			}
		} else {
			craft_scroll = Mouse.y - scroll_area_y;
			if (Mouse.left_released()) {
				scrolling = false;
			}
		}
		if (craft_scroll < 0) {
			craft_scroll = 0;
		}
		// TODO: limit in other direction
		

		// Fly to another planet
		if (Mouse.left_click()) {
			for (planet in planets) {
				if (planet != current_planet 
					&& mouse_planet_intersect(planet)
					&& planet_in_interact(planet)) 
				{

					if (cargo_weight() > cargo_weight_max) {
						// If over cargo weight capacity, 
						add_message('Can\'t fly, over cargo capacity');
					} else {
						state = GameState_Flying;
						flying_state_timer = 0;

						// Reset drag state
						if (dragged_item != null) {
							dragged_item.dragged = false;
							dragged_item = false;
						}

						// Reset split state
						if (split_material != null) {
							split_material = null;
						}

						// Reset craft scroll
						craft_scroll = 0;
						scrolling = false;

						previous_planet = current_planet;
						current_planet = planet;

						// Move unattached parts into planet inventory
						var planet_inventory = previous_planet.inventory;
						for (part in parts) {
							if (part.inventory_state == InventoryState_ShipEdit) {
								var moved_successfully = false;

								for (i in 0...planet_inventory.length) {
									if (planet_inventory[i] == null) {
										planet_inventory[i] = part;
										part.inventory_state = InventoryState_PlanetInventory;
										var position = position_in_planet_inventory(i);
										part.x = position.x;
										part.y = position.y;

										moved_successfully = true;

										break;
									}
								}

								if (!moved_successfully) {
									add_message('Destroyed unattached part, not enough space in planet storage');
								}
							}
						}

						// Deactive items in previous planet's inventory
						var previous_inventory = previous_planet.inventory;
						for (i in 0...previous_inventory.length) {
							if (previous_inventory[i] != null) {
								previous_inventory[i].active = false;
							}
						}
						// Activate items in destination planet's inventory
						var destination_inventory = current_planet.inventory;
						for (i in 0...destination_inventory.length) {
							if (destination_inventory[i] != null) {
								destination_inventory[i].active = true;
							}
						}

						// Create initial stars
						for (i in 0...star_particle_amount) {
							star_particles.push(generate_star_particle());
						}

						// Set flying time based on distance, this will affect the amount of damage generated
						var trip_distance = Math.dst(current_planet.x, current_planet.y, previous_planet.x, previous_planet.y);
						flying_state_timer_max = Math.round(trip_distance * distance_to_time * Random.float(0.75, 1.25) * 60);

					}

					break;
				}
			}
		}

		// Planets with mining stations mine materials
		for (planet in planets) {
			if (planet.station == StationType_Mining) {

				planet.mining_timer++;

				// Effective mining level of planet
				var mining_level = Std.int(Math.min(planet.level, planet.station_level));

				if (planet.mining_timer > Planet.mining_timer_max_list[mining_level]) {
					planet.mining_timer = 0;


					var added_material = false;
					for (i in 0...planet.inventory.length) {
						if (planet.inventory[i] != null 
							&& planet.inventory[i].item_type == ItemType_Material) 
						{
							planet.inventory[i].amount += 1;
							added_material = true;

							break;
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

								// Materials added to off-screen inventories are inactive
								if (planet != current_planet) {
									material.active = false;
								}

								planet.inventory[i] = material;
								material.inventory_state = InventoryState_PlanetInventory;
								var position = position_in_planet_inventory(i);
								material.x = position.x;
								material.y = position.y;

								added_material = true;

								break;
							}
						}
					}

					// Mining graphic of popping "+1" above planet
					if (added_material) {
						planet.mining_graphic_on = true;
					} else {
						add_message('A planet can\'t mine because it\'s storage is full');
					}
				}
			}
		}

		// Shift inventories to remove empty spaces
		function shift_inventory(inventory: Vector<Dynamic>, inventory_state: InventoryState) {
			var i = 0;
			while (i < inventory.length) {
				if (inventory[i] == null) {
					var item_moved = false;
					var j = i + 1;

					while (j < inventory.length) {
						if (inventory[j] != null) {
							inventory[i] = inventory[j];
							inventory[j] = null;

							var position: IntVector2;
							if (inventory_state == InventoryState_ShipInventory) {
								position = position_in_ship_inventory(i);
							} else {
								position = position_in_planet_inventory(i);
							}
							inventory[i].x = position.x;
							inventory[i].y = position.y;

							item_moved = true;

							break;
						}

						if (!item_moved) {
							break;
						}

						j++;
					}
				}

				i++;
			}
		}
		shift_inventory(ship_inventory, InventoryState_ShipInventory);
		shift_inventory(current_planet.inventory, InventoryState_PlanetInventory);


		// Update mining graphic state
		for (planet in planets) {
			if (planet.mining_graphic_on) {
				planet.mining_graphic_timer++;

				if (planet.mining_graphic_timer > Planet.mining_graphic_timer_max) {
					planet.mining_graphic_timer = 0;
					planet.mining_graphic_on = false;
				}
			}
		}

		if (Input.just_pressed(Key.SPACE)) {
			var new_part = new Part();
			parts.push(new_part);
			items.push(new_part);

			generate_part_pixels(new_part);
			add_to_ship_inventory(new_part);
		}


		render_planets();

	}

	function update() {
		switch (state) {
			case GameState_Flying: update_flying();
			case GameState_Planets: update_planets();
		}

		Text.display(0, screen_height - 50, 'Mouse: x=${Mouse.x} y=${Mouse.y}');

		// Messages
		if (message_queue.length != 0) {
			var current_message = message_queue[0];

			var progress = message_timer / message_timer_max;
			var c = Math.round((1 - progress) * 255);
			Text.display(0, 950 + progress * 10 , current_message, Col.rgb(c, c, c));

			message_timer++;
			if (message_timer > message_timer_max) {
				message_timer = 0;
				message_queue.shift();
			}
		}

		var left = Input.pressed(Key.A);
		var right = Input.pressed(Key.D);
		var up = Input.pressed(Key.W);
		var down = Input.pressed(Key.S);

		if (right && !left) {
			viewport_x += viewport_scroll_speed;
		} else if (left && !right) {
			viewport_x -= viewport_scroll_speed;
		}

		if (down && !up) {
			viewport_y += viewport_scroll_speed;
		} else if (up && !down) {
			viewport_y -= viewport_scroll_speed;
		}

		if (Input.pressed(Key.DOWN)) {
			craft_scroll += 2;
		} else if (Input.pressed(Key.UP)) {
			craft_scroll -= 2;
			if (craft_scroll < 0) {
				craft_scroll = 0;
			}
		}
	}
}
