gml_pragma("global", "make_game()");
window_set_caption("Snake Game");
///@func make_game()
///@desc tbh it's pretty self-explanatory ;)
//Oh btw it's a dumb snake game
#region Macros & Enums
//Everyone loves 'em
//Set Up Game States
enum game_state{
	running,
	beginning,
	ending,
	menu,
	settings,
}
//Set Up Player States
enum player_state{
	spawning,
	normal,
	dying,
}
//"Constants" but not really...?
#macro grid_width 10
#macro grid_height 10
#macro cell_size 32
#macro max_tilt 16
#macro EMPTY -1
#macro FOOD 0
#macro SNAKE 1
#macro LAGTIME 10
#macro SNAKE_BASE_LENGTH 3
#endregion

#region Game super hack init over 9000

if (event_type == 0 && event_number == 0) { // should only be in the global init
	// Get script name and add to layer script
	// Credit: Nuxii @Kat3Nuxii
	// https://gist.github.com/NuxiiGit/1ed55debd0c0c7be02a78a0c464b50ee
	var script_stack = debug_get_callstack();
	var script_count = array_length_1d(script_stack);
	var script_top = script_stack[0];
	var script_name = string_replace(string_copy(script_top,1,string_pos(":",script_top)-1),"gml_Script_","");
	var this_script = asset_get_index(script_name);
	
	// re-target room
	layer_set_target_room(room_first);
	
	// add layer script
	var new_layer = layer_create(-16000);
	layer_script_begin(new_layer, this_script);
	return;
}
#endregion

#region Game Init
//Hopefully only happens ONCE :P
//Otherwise, you ain't using the script right!

if(ds_exists(0, ds_type_map)) {
	if(ds_map_exists(0, "buffer")) {
		var map = 0;
		var text = buffer_read(map[? "buffer"], buffer_string);
		show_debug_message(text);
	}
	
}

if (!variable_global_exists("make_game_init"))
	{
	randomize();
	global.make_game_init=true;
	var ww=grid_width*cell_size,hh=grid_height*cell_size;
	global.make_game_cam=camera_create_view(0,0,ww,hh,0,noone,0,0,0,0);
	surface_resize(application_surface,ww,hh);
	window_set_size(ww,hh);
	view_camera[0]=global.make_game_cam;
	view_enabled=true;
	view_visible[0]=true;
	//window_set_size(ww,hh);
	global.make_game_gamestate=game_state.menu;
	global.make_game_playerstate=player_state.normal;
	global.make_game_grid=ds_grid_create(grid_width,grid_height);
	ds_grid_clear(global.make_game_grid,EMPTY);
	global.make_game_snake_body=ds_list_create();
	global.make_game_spawn_timer=-1;
	global.make_game_snake_hsp=0;
	global.make_game_snake_vsp=0;
	global.make_game_lag=0;
	global.make_game_death_timer=0;
	score=0;
	global.make_game_current_high=0;
	global.make_game_selection=0;
	global.make_game_resolution=[320,480,640,720,920,1280];
	// load sprites
	// Credit: Meseta is awesome
	// https://meseta.itch.io/gm-imbuff
	var snake_sprite = "eJztmbEOgkAMQM8wuPpXTn6G/+DmHzn4BY4ODv6BK04aY0KMA1KOynFcW0AYzJVLE7D3Wi7IA+NyZczC2Jgbu52LnXU+3cizIh5mOP/eD+bL3hU/pEbJw9aTPx1Mi8WAHNkrq1jcPNatgftJauuVx7DWar3FpW1xoc+Q/9YoYruxc935eAw5OH5dm6xfg+tPsX4NKjhW4vv0vl2aASwGVcM/TzfcGhIfyrs1KB57UesL5Z8zdQDLR+oAfz7ud3XAWPehOqAeUzkgTdQBLB+pA/Q9IB4HHI06gOUjdYA/v897gNndyXOHHPcdhrzEQ7DXTR1Ark8dMICP0AE4L+QA6VkuPcOl+5C7/10PUKzEQ2/OI+qA8Yc6QB3wy7M4FJw/JB57qwPqof8LCLw64G8c0IXX3wLt/Ad01FVM";
	var temp_buff = buffer_base64_decode(snake_sprite);
	var header = buffer_read(temp_buff, buffer_u16);
	if(header == 0x4D47) { // uncompressed buffer
		global.make_game_snake_buffer = temp_buff;
	}
	else {
		global.make_game_snake_buffer = buffer_decompress(temp_buff);
		buffer_delete(temp_buff);
	}
	buffer_seek(global.make_game_snake_buffer, buffer_seek_start, 4);
	global.make_game_snake_h = buffer_read(global.make_game_snake_buffer, buffer_u32);
	global.make_game_snake_w = buffer_read(global.make_game_snake_buffer, buffer_u32);
	global.make_game_snake_frame_count = buffer_read(global.make_game_snake_buffer, buffer_u32);
	global.make_game_snake_frame_number = -1;
	global.make_game_snake_loop_start_time = get_timer();
	global.make_game_snake_frame_delay = 0;
	global.make_game_snake_frame_start = 24;
	global.make_game_snake_surface = -1;
	
	var apple_sprite = "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";
	var temp_buff = buffer_base64_decode(apple_sprite);
	var header = buffer_read(temp_buff, buffer_u16);
	if(header == 0x4D47) { // uncompressed buffer
		global.make_game_apple_buffer = temp_buff;
	}
	else {
		global.make_game_apple_buffer = buffer_decompress(temp_buff);
		buffer_delete(temp_buff);
	}
	buffer_seek(global.make_game_apple_buffer, buffer_seek_start, 4);
	global.make_game_apple_h = buffer_read(global.make_game_apple_buffer, buffer_u32);
	global.make_game_apple_w = buffer_read(global.make_game_apple_buffer, buffer_u32);
	global.make_game_apple_frame_count = buffer_read(global.make_game_apple_buffer, buffer_u32);
	global.make_game_apple_frame_number = -1;
	global.make_game_apple_loop_start_time = get_timer();
	global.make_game_apple_frame_delay = 0;
	global.make_game_apple_frame_start = 24;
	global.make_game_apple_surface = -1;

	// networking
	global.server_socket = network_create_server_raw(network_socket_udp, 4114, 1);

	}
#endregion

#region Draw event limiter
// makes sure layer script only fires once
if (event_type != ev_draw || event_number != ev_gui) {
	return;
}

#endregion

#region State Machine
//Nintendo
switch(global.make_game_gamestate)
	{
	#region MENU
	case game_state.menu:
		{
		var width=window_get_width(),height=window_get_height();
		draw_set_color(c_black);
		draw_rectangle(0,0,width,height,false);
		draw_set_halign(fa_center);
		draw_set_color(c_lime);
		draw_text(width/2,height/8,"SNAKE GAME");
		draw_set_color(c_white);
		draw_text(width/2,height/3,"Press SPACE to Play!");
		draw_text(width/2,height/2,"Press ENTER for Options");
		draw_text(width/2,height/1.3,"Made by Yosi, Meseta, and Kat");
		//Go to a level (the only level lol)
		if (keyboard_check(vk_space))
			global.make_game_gamestate=game_state.beginning;
		else if (keyboard_check_pressed(vk_enter))
			global.make_game_gamestate=game_state.settings;
		break;
		}
	#endregion
	#region SETTINGS
	case game_state.settings:
		{
		var width=window_get_width(),height=window_get_height();
		draw_set_color(c_black);
		draw_rectangle(0,0,width,height,false);
		draw_set_color(c_white);
		draw_set_halign(fa_center);
		draw_text(width/2,height/3,"Resolution: " + string(global.make_game_resolution[@global.make_game_selection]));
		var press=keyboard_check_pressed(vk_right)-keyboard_check_pressed(vk_left);
		if (press!=0)
			{
			global.make_game_selection=clamp(global.make_game_selection+press,0,array_length_1d(global.make_game_resolution)-1);
			//Update resolution
			var res=global.make_game_resolution[@global.make_game_selection];
			surface_resize(application_surface,res,res);
			window_set_size(res,res);
			camera_set_view_size(global.make_game_cam,res,res);
			}
		draw_text(width/2,height/1.3,"Press RIGHT and LEFT to choose");
		draw_text(width/2,height/1.2,"Press ENTER to exit");
		if (keyboard_check_pressed(vk_enter))
			global.make_game_gamestate=game_state.menu;
		break;
		}
	#endregion
	#region BEGIN
	case game_state.beginning:
		{
		var width=grid_width*cell_size,height=grid_height*cell_size;
		draw_set_color(c_black);
		draw_rectangle(0,0,width,height,false);
		//Set up the snake, the food, and the states
		var fx=grid_width div 2,fy=grid_height div 2;
		ds_grid_clear(global.make_game_grid,EMPTY);
		global.make_game_grid[# fx,fy]=SNAKE;
		global.make_game_grid[# fx,fy-3]=FOOD;
		ds_list_clear(global.make_game_snake_body);
		global.make_game_snake_hsp=0;
		global.make_game_snake_vsp=0;
		for(var j=0;j<SNAKE_BASE_LENGTH;j++)
			{
			global.make_game_snake_body[| j]=fx | (fy<<24);
			}
		global.make_game_gamestate=game_state.running;
		global.make_game_playerstate=player_state.spawning;
		global.make_game_spawn_timer=30;
		global.make_game_death_timer=0;
		score=0;
		global.make_game_lag=0;
		break;
		}
	#endregion
 	#region RUN
	case game_state.running:
		{
		#region Snake? Snake! SNAAAAAAAAAAAAKE!!!!!!!
		//Snake logic
		switch(global.make_game_playerstate)
			{
			case player_state.spawning:
				{
				if ((keyboard_check(vk_right) || keyboard_check(vk_left) || keyboard_check(vk_up) || keyboard_check(vk_down))
					&& --global.make_game_spawn_timer<=0)
					{
					global.make_game_spawn_timer=-1;
					global.make_game_playerstate=player_state.normal;
					global.make_game_snake_vsp=-1;
					}
				break;
				}
			case player_state.normal:
				{
				//Get keyboard input & move
				var rl=keyboard_check(vk_right)-keyboard_check(vk_left),ud=keyboard_check(vk_down)-keyboard_check(vk_up);
				if (--global.make_game_lag<=0)
					{
					global.make_game_lag=LAGTIME;
					if (rl!=0 && global.make_game_snake_hsp==0)
						{
						global.make_game_snake_hsp=rl;
						global.make_game_snake_vsp=0;
						}
					if (ud!=0 && global.make_game_snake_vsp==0)
						{
						global.make_game_snake_vsp=ud;
						global.make_game_snake_hsp=0;
						}
					//Add new coordinates to the list, but in a trippy binary format
					var oldx,oldy,new_coords;
					oldx=global.make_game_snake_body[|ds_list_size(global.make_game_snake_body)-1];
					oldy=oldx >> 24;
					oldx=oldx & $ffffff;
					oldx+=global.make_game_snake_hsp;
					oldy+=global.make_game_snake_vsp;
					new_coords=oldx | (oldy<<24);
					//Delete the first entry in the list (the last part of the snake)
					var lastx,lasty;
					lastx=global.make_game_snake_body[|0];
					lasty=lastx >> 24;
					lastx=lastx & $ffffff;
					global.make_game_grid[# lastx,lasty]=EMPTY;
					ds_list_delete(global.make_game_snake_body,0);
					#region Out of Grid or touching self
					if (oldx<0 || oldx>grid_width-1 || oldy<0 || oldy>grid_height-1) || (global.make_game_grid[# oldx,oldy]==SNAKE)
						{
						global.make_game_playerstate=player_state.dying;
						global.make_game_death_timer=60;
						oldx=clamp(oldx,0,grid_width-1);
						oldy=clamp(oldy,0,grid_height-1);
						#region SAVING SLASH LOADING
						if (file_exists("highscore.sav"))
							{
							var buffer=buffer_load("highscore.sav");
							var str=buffer_read(buffer,buffer_string);
							buffer_delete(buffer);
							var map=json_decode(str);
							global.make_game_current_high=map[?"SCORE"];
							ds_map_destroy(map);
							if (score>global.make_game_current_high)
								global.make_game_current_high=score;
							}
						else
							{
							global.make_game_current_high=score;
							}
						if (file_exists("highscore.sav"))
							file_delete("highscore.sav");
						var save_map=ds_map_create();
						save_map[?"SCORE"]=global.make_game_current_high;
						var save_buffer=buffer_create(string_byte_length(json_encode(save_map))+1,buffer_fixed,1);
						buffer_write(save_buffer,buffer_string,json_encode(save_map));
						buffer_save(save_buffer,"highscore.sav");
						buffer_delete(save_buffer);
						ds_map_destroy(save_map);
						#endregion
						}
					#endregion
					#region Eating
					//Yeah it says eating, but most of the logic is figuring out where the next food appears ;)
					if (global.make_game_grid[# oldx,oldy]==FOOD)
						{
						//Pointssssss
						score+=1;
						//Quite literally just duplicates the first index in the list, or the end of the snake
						ds_list_insert(global.make_game_snake_body,0,global.make_game_snake_body[|0]);
						//Try to spawn new food at a random location 10 times; if it fails, loop and spawn at an open location
						var xx,yy,success=false;
						repeat(10)
							{
							xx=irandom(grid_width-1);
							yy=irandom(grid_height-1);
							if (global.make_game_grid[# xx,yy]==EMPTY)
								{
								global.make_game_grid[# xx,yy]=FOOD;
								success=true;
								break;
								}
							}
						if (!success)
							{
							for(var i=0;i<grid_width;i++){for(var m=0;m<grid_height;m++)
								{
								if (global.make_game_grid[# i,m]==EMPTY)
									{
									global.make_game_grid[# i,m]=FOOD;
									success=true;
									break;
									}
								}}
							//If it still can't spawn food, the game just dies
							if (!success)
								{
								game_end();
								}
							}
						}
					#endregion
					global.make_game_grid[# oldx,oldy]=SNAKE;
					global.make_game_snake_body[|ds_list_size(global.make_game_snake_body)]=new_coords;
					}
				break;
				}
			case player_state.dying:
				{
				if (--global.make_game_death_timer<=0)
					{
					global.make_game_death_timer=0;
					global.make_game_gamestate=game_state.ending;
					}
				break;
				}
			}
		#endregion
		#region Prep and animate snake surface
		var snake_update = false;
		if (not surface_exists(global.make_game_snake_surface)) {
			global.make_game_snake_surface = surface_create(global.make_game_snake_w, global.make_game_snake_h);
			snake_update = true;
		}
	
		if(get_timer() >= global.make_game_snake_loop_start_time + global.make_game_snake_frame_delay) {

			// advance frame
			global.make_game_snake_frame_number += 1;
			if(global.make_game_snake_frame_number >= global.make_game_snake_frame_count) { // at end
				global.make_game_snake_frame_number = 0;
				global.make_game_snake_frame_delay = 0;
				global.make_game_snake_loop_start_time = get_timer();
			}
			
			// grab animation frame
			global.make_game_snake_frame_start = 20+(global.make_game_snake_w*global.make_game_snake_h*4+4)*global.make_game_snake_frame_number;
			buffer_seek(global.make_game_snake_buffer, buffer_seek_start, global.make_game_snake_frame_start);
			global.make_game_snake_frame_delay += buffer_read(global.make_game_snake_buffer, buffer_u32) * 1000;
			snake_update = true;
		}
		
		if (snake_update) {
			buffer_set_surface(global.make_game_snake_buffer, global.make_game_snake_surface, 0, global.make_game_snake_frame_start+4, 0);
		}
		#endregion
		
		#region Prep and animate apple surface
		var apple_update = false;
		if (not surface_exists(global.make_game_apple_surface)) {
			global.make_game_apple_surface = surface_create(global.make_game_apple_w, global.make_game_apple_h);
			draw_clear_alpha(c_white,0);
			apple_update = true;
		}
	
		if(get_timer() >= global.make_game_apple_loop_start_time + global.make_game_apple_frame_delay) {

			// advance frame
			global.make_game_apple_frame_number += 1;
			if(global.make_game_apple_frame_number >= global.make_game_apple_frame_count) { // at end
				global.make_game_apple_frame_number = 0;
				global.make_game_apple_frame_delay = 0;
				global.make_game_apple_loop_start_time = get_timer();
			}
			
			// grab animation frame
			global.make_game_apple_frame_start = 20+(global.make_game_apple_w*global.make_game_apple_h*4+4)*global.make_game_apple_frame_number;
			buffer_seek(global.make_game_apple_buffer, buffer_seek_start, global.make_game_apple_frame_start);
			global.make_game_apple_frame_delay += buffer_read(global.make_game_apple_buffer, buffer_u32) * 1000;
			apple_update = true;
		}
		
		if (apple_update) {
			buffer_set_surface(global.make_game_apple_buffer, global.make_game_apple_surface, 0, global.make_game_apple_frame_start+4, 0);
		}
		#endregion
		
		#region Rendering
		//Draw Grid
		var c=c_white;
		var xx,yy;
		var cell_ratio=window_get_width()/grid_width;
		for(var i=0;i<grid_width;i++){for(var m=0;m<grid_height;m++)
			{
			xx=i*cell_ratio;
			yy=m*cell_ratio;
			switch(global.make_game_grid[# i,m])
				{
				case EMPTY: c=$65ff65;draw_rectangle_color(xx,yy,(xx)+cell_ratio,(yy)+cell_ratio,c,c,c,c,false);break;
				case FOOD:
					draw_surface_ext(global.make_game_apple_surface, xx, m*cell_ratio, cell_ratio/global.make_game_apple_w, cell_ratio/global.make_game_apple_h, 0, c_white, 1.0);
					break;
				case SNAKE: 
					draw_surface_ext(global.make_game_snake_surface, xx, m*cell_ratio, cell_ratio/global.make_game_snake_w, cell_ratio/global.make_game_snake_h, 0, c_white, 1.0);
					break;
				}
			}}
		//Draw current score
		draw_text(window_get_width()/2,16,score);
		#endregion
		break;
		}
	#endregion
	#region END
	case game_state.ending:
		{
		var width=window_get_width(),height=window_get_height();
		draw_set_color(c_black);
		draw_rectangle(0,0,width,height,false);
		//Show the highscore
		draw_set_color(c_white);
		draw_set_halign(fa_center);
		draw_text(width/2,height/3,"HIGHEST:" + string(global.make_game_current_high));
		draw_text(width/2,height/3+64,"SCORE: " + string(score));
		draw_text(width/2,height/1.3,"Press SPACE to Play");
		draw_text(width/2,height/1.2,"ENTER for Settings");
		if (keyboard_check_pressed(vk_space))
			global.make_game_gamestate=game_state.beginning;
		else if (keyboard_check_pressed(vk_enter))
			global.make_game_gamestate=game_state.settings;
		break;
		}
	#endregion
	//The game literally just gives up if the state machine breaks :joy:
	default: game_end(); break;
	}
#endregion
//THE END