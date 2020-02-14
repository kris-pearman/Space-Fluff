pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
left,right,up,down,fire1,fire2=0,1,2,3,4,5
black,dark_blue,dark_purple,dark_green,brown,dark_gray,light_gray,white,red,orange,yellow,green,blue,indigo,pink,peach=0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15

--main loop functions
function _init()
    event_timeline = {}
    game_state = "title"
    hi_score=0
    title_frame = -80
    -- (eventType, quantity, initialFrame, frequency,x,y,pattern,group_id,default_speed)
    create_events("enemy1", 4, 100, 30,80,-20,"empty_pattern",nil,2)  
    create_events("enemy1", 4, 500, 30,40,-20,"empty_pattern",nil,2)
    create_events("enemy1", 4, 900, 25,20,-20,"square","group_1",1,4)
    create_events("enemy1", 4, 1500, 25,-30,5,"zig_zag","group_1",2,4)   
    for i=1,5 do
        create_events("enemy1", 1, 1900+(20*i), 30,15+(i*15),-20,"empty_pattern",3,3)
    end
    create_events("enemy1", 8, 2250, 20,-30,15,"wave",4,4)
    for i=1,5 do
        create_events("enemy1", 1, 2600+(20*i), 30,100-(i*15),-20,"empty_pattern",3,3)
    end
    for i=1,5 do
        create_events("enemy1", 1, 3400+(20*i), 30,90-(i*15),-20,"empty_pattern",3,2)
    end
    create_events("enemy1", 4, 3000, 25,-30,5,"zig_zag_2","group_1",2,4)
    init_session()
    print_debug_message = false
    decoration_speed = 1
    decoration_ypos = 1
    title_offset = 0

    
end

function init_session()
    create_player_vars()
    
    enemies={}
    boss={}
    boss.x=200
    boss.y=10
    boss.width = 16
    boss.height = 16
    boss.hp = 10
    boss_killed = false
    boss.bullets={}
    bullets={}
    powerups={}
    cur_frame=0
    background_initialised = 0
    background_array = {}
    background_tile_1_offset = 128
    background_tile_2_offset = 0
    enemy_bullets = {}
    boss_bullets = {}
    invuln_timer = 0
    explosions = {}
    decoration_ypos = 1
    
    for i=1,100 do
        local background_star = {}
        background_star.x = flr(rnd(128))
        background_star.y = flr(rnd(200))-72 
                
        star_color_rnd = flr(rnd(40))+1
        if (star_color_rnd >= 1 and star_color_rnd<=16) then
            background_star.color = dark_blue
        elseif (star_color_rnd >16 and star_color_rnd<=18) then
            background_star.color = dark_purple
        elseif (star_color_rnd >18 and star_color_rnd<=39) then
            background_star.color = dark_gray
        else
            background_star.color = white
        end   

        set_star_speed(background_star)         
        add(background_array, background_star)
    end
end

function _update60()
    if game_state == "title" then
        check_game_started()
        if title_frame < 22 then
            title_frame += 1
        end
        if transition == true then
            title_offset+=2
            
        end
        if title_offset == 128 then
            transition = false
            game_state = "gameplay"
            title_offset = 0
            music(0,60)
        end
    else
        if game_state == "gameplay" then
            handle_input()
            move_bullets()
            update_powerups()
            hide_dead_enemies()
            enemy_collision()
            enemy_projectiles()
            player_collision_with_ship()
            check_event_timeline()
            move_background()
            if boss_killed == false then
            boss_ai()
            end
            enemy_bullet_direction = flr(rnd(3))
            cur_frame += 1
            if cool_down > 0 then
                cool_down -= 1
            end
            if player.invulnerable then
                if invuln_timer > 1 then
                    invuln_timer -= 1
                else
                    player.invulnerable = false
                    invuln_timer = 0
                end
            end
            if player.lives < 1 then
                game_state = "game over"
                cur_frame = 0
                music(-1)
                if (player.score > hi_score) then
                    hi_score = player.score
                end
            end
        end
    end
    if game_state == "game over" then
        if cur_frame > 300 then
            game_state = "title"
        end
        cur_frame += 1
        if btnp(fire2) then
            game_state = "title"
        end
    end
end

function _draw()
    cls(black)
    if game_state == "title" then
        draw_title_logo()
        print("press ❎ to start",28-title_offset,60,white) 
        print("high score = " .. hi_score,33-title_offset,100,white) 
    else 
        if game_state == "gameplay" then
            
            draw_decorations()
            draw_background()
            draw_enemy_projectiles()
            draw_boss_projectiles()
            draw_player()
            draw_bullets()
            draw_powerup()
            draw_enemies()
            draw_explosions()
            if boss_killed == false then
            create_boss()
            boss_collision()
            end
            --KEEP THIS LAST. THAT MEANS YOU KRIS.
            draw_hud()
        else 
            if game_state == "game over" then
                draw_game_over()
                title_frame = -100
                
                
            end         
        end
    end
end

-->8
--creation functions

function create_enemy_data(pattern,speed)
    local patterns = {}
    local square = {}
    square.path = {{32,32,3},{92,32,3},{92,92,3},{32,92,3},{32,32,2},{60,50,2}}
    square.exit_d = "down"
    square.exit_s = 1
    square.fire = true
    square.fire_rate = 100
    patterns.square = square
    local enemy_two = {}
    enemy_two.path = {{80,128,4}}
    enemy_two.exit_d = "down"
    enemy_two.exit_s = 1
    patterns.enemy_two = enemy_two 
    local empty_pattern = {}
    empty_pattern.path = nil
    empty_pattern.exit_d = "down"
    empty_pattern.exit_s = speed
    patterns.empty_pattern = empty_pattern
    local zig_zag = {}
    zig_zag.path = {{100,25,2},{45,80,3},{100,80,3}}
    zig_zag.exit_d = "down"
    zig_zag.exit_s = speed
    zig_zag.fire = true
    zig_zag.fire_rate = 80
    patterns.zig_zag = zig_zag
    local zig_zag_2 = {}
    zig_zag_2.path = {{100,65,2},{45,20,3},{100,30,3}}
    zig_zag_2.exit_d = "down"
    zig_zag_2.exit_s = speed
    zig_zag_2.fire = true
    zig_zag_2.fire_rate = 80
    patterns.zig_zag_2 = zig_zag_2
    local wave = {}
    wave.path = {{0,30,3},{15,15,3},{30,30,3},{45,15,3},{60,30,3},{75,15,3},{90,30,3},{115,15,3},{130,30,3}}
    wave.exit_d = "down"
    wave.exit_s = speed
    wave.fire = true
    wave.fire_rate = 80
    patterns.wave = wave

    
    return patterns[pattern]
end

function create_boss()
    if cur_frame > 5000 then
        music(-1,60)
        
    sspr(112,0,16,16,boss.x,boss.y)
    boss_exists = true
    end
end

function boss_ai()
    if boss_exists == true then
        move_boss()
        check_boss_fires()
        move_boss_bullets()
    end
end

function boss_collision()
    for bullet in all(bullets) do
        if (objects_have_collided(bullet, boss)) then
            boss.hp -=1
            del(bullets,bullet)
            num_of_bullets -= 1
        end
    end
    if boss.hp < 1 then
        boss_killed = true
        player.score += 10000
    end
end

function move_boss()
    if cur_frame%2 == 0 then
        if boss.direction == left then
            boss.x -= 1
        end
        if boss.x < 20 then
            boss.direction = right
        end
        if boss.direction == right then
            boss.x += 1
        end
            if boss.x>80 then
            boss.direction = left
        end
    end
    
end


function check_boss_fires()
    if cur_frame%45 == 0 then
        for i=1,3,1 do 
            spawn_boss_bullet(i)
        end
    end
end


function spawn_boss_bullet(i)
    local boss_bullet = {}
    boss_bullet.x = boss.x + 5
    boss_bullet.y  = boss.y+12
    boss_bullet.x_speed = 4
    boss_bullet.direction = i
    boss_bullet.width = 4
    boss_bullet.height = 4
    boss_bullet.sprite = 1
    add(boss_bullets, boss_bullet)
end

function move_boss_bullets()
    for boss_bullet in all(boss_bullets) do
        boss_bullet.y += 1
        if boss_bullet.direction == 1 then
            boss_bullet.x -= 1
        end
        if boss_bullet.direction == 2 then
            boss_bullet.x += 1
        end

        if boss_bullet.y > 128 then
            del(boss_bullets,boss_bullet)
        end
        if player.invulnerable == false then
            if (objects_have_collided(boss_bullet, player)) then
                sfx(0)
                del(boss_bullets,boss_bullet)
                handle_player_death()
            end
        end
    end
end

function create_events(eventType, quantity, initialFrame, frequency,x,y,pattern,group_id,speed)
    for i=1,quantity do 
        local event = {}
        event.eventType = eventType
        event.startFrame = initialFrame + (i*frequency)
        event.x = x
        event.y = y
        event.p = pattern
        event.g = group_id
        event.s = speed
        add(event_timeline, event)
    end
end

function check_game_started()
    if btnp(fire2) then
        transition = true
        sfx(16)
        
        init_session()
    end
end

function create_player_vars()
    player={}
    player.alive=true
    player.x=60
    player.y=105
    player.width = 6
    player.height = 6
    player.score=0
    player.lives=3
    player.invulnerable = false
    cool_down = 0
    num_of_bullets = 0
end

function create_powerup(x,y)
    local powerup={}
    powerup.x=x
    powerup.y=y
    powerup.width = 8
    powerup.height = 6
    powerup.speed=4
    powerup.collected=false
    powerup.value=100
    add(powerups,powerup)
end

function player_fire()
    local bullet = {}
    bullet.x = player.x+2
    bullet.y = player.y
    bullet.width = 2
    bullet.height = 2
    bullet.speed=1
    add(bullets, bullet)
    sfx(0)
end

function spawn_enemy_event(x, y,pattern,group,speed)
    local enemy={}
    enemy.alive=true
    enemy.x=x
    enemy.y=y
    enemy.speed=1
    enemy.tick_count=1 --used to calculate how often the enemys move updates, change this to change how often the enemy updates
    enemy.value=200
    enemy.counter=0
    enemy.spawn_time = cur_frame-1
    enemy.attack={}
    enemy.attack.freq = 0
    enemy.attack.speed = 0
    enemy.attack.direction = 0
    enemy.attack.sprite = 0
    enemy.height = 8
    enemy.width = 8
    enemy.logic = create_enemy_data(pattern,speed)
    enemy.group = group
    add(enemies, enemy)
end


function check_event_timeline()
    for event in all(event_timeline) do
        if(event.eventType=="enemy1" and cur_frame==event.startFrame) then
            spawn_enemy_event(event.x,event.y,event.p,event.g,event.s)
        end
    end
end


function handle_player_death()
    if player.invulnerable == false then
        player.lives -= 1
        player.invulnerable = true
        invuln_timer = 180
    end
end

-->8
--player input functions here
function handle_input() 
    if player.alive then
        if btn(left) then
            if player.x != 0 then
                player.x -= 1
            end
        end
        if btn(right) then
            if player.x != (129 - 8) then
                player.x += 1
            end
        end
        if btn(up) then
            player.y -= 1
        end
        if btn(down) then
            if player.y < 105 then
                player.y += 1
            end
        end
        if btnp(fire1) then
            if (cool_down == 0 and num_of_bullets < 3) then
                player_fire()    
                cool_down = 4
                num_of_bullets += 1
            end
        end
        if btnp(fire2) then
           
        end
    end
end

-->8
--powerup functions here

function update_powerups()
    for powerup in all(powerups) do
        move_powerup(powerup)
        detect_powerup_collection(powerup)
    end
end

function move_powerup(powerup)
    if powerup.collected == false then
        if cur_frame%powerup.speed == 0 then
            powerup.y += 1
        end
    else
        del(powerups,powerup)
    end
end

function detect_powerup_collection(powerup)
    if (objects_have_collided(powerup, player)) then
        powerup.collected = true
        player.score += powerup.value
        sfx(1)
    end
end

-->8
--collision

function move_bullets()
    for bullet in all(bullets) do
        if bullet.y > -1 then
            bullet.y -= bullet.speed
        else
            del(bullets, bullet)
            num_of_bullets -= 1
        end
    end
end

-->8
--enemy functions

function hide_dead_enemies()
    for enemy in all(enemies) do
        if enemy.alive then
            check_enemy_moves(enemy)
            enemy.tick_count += 1
        else
            del(enemies,enemy)
        end
        if enemy.y>128 then
            del(enemies,enemy)
        end
    end
end


function check_enemy_moves(enemy)  --needs reworking but this controls basic movement
    for coord in all(enemy.logic.path) do
        local x = coord[1]
        local y = coord[2]
        local s = coord[3]
        if x == play_x then
            x = player.x
        end

        if enemy.tick_count%s == 0 then        
            enemy.tick_count = 1
        
        if enemy.x > x then
            move_enemy_left(enemy)
        elseif enemy.x < x then
            move_enemy_right(enemy)
        end
            if enemy.y < y then
            move_enemy_down(enemy)
        elseif enemy.y > y then
            move_enemy_up(enemy)
        end
    end
        if enemy.x == x then
            if enemy.y == y then
                del(enemy.logic.path, coord)
            end
        end
        return
        
    end
    if enemy.tick_count%enemy.logic.exit_s == 0 then
        if enemy.logic.path == nil or #enemy.logic.path == 0 then
            move_enemy_down(enemy)
        end
    end
end

function move_enemy_down(enemy)
    enemy.y+=enemy.speed
end

function move_enemy_up(enemy)
    enemy.y-=enemy.speed
end

function move_enemy_right(enemy)
    enemy.x+=enemy.speed
    enemy.counter += 1
end

function move_enemy_left(enemy)
    enemy.x -= enemy.speed
    enemy.counter -= 1
end

function enemy_collision()
    local counter = 0
    for bullet in all(bullets) do
        for enemy in all(enemies) do   
            if (objects_have_collided(bullet, enemy)) then
                enemy.alive = false
                player.score += enemy.value
                create_explosion(enemy.x+2,enemy.y+1)
                del(bullets, bullet)
                num_of_bullets -= 1
                if enemy.group  ~= nil  then
                    for group_check in all(enemies) do
                        if group_check.alive then
                            if group_check.group == enemy.group then
                                counter += 1
                            end
                        end
                    end
                    if counter == 0 then
                        create_powerup(enemy.x-1,enemy.y-3)
                    end
                end

                sfx(2) 
            end
        end
    end
end

function create_explosion(x,y)
    local explosion = {}
    explosion.x = x
    explosion.y = y
    explosion.t = 0
    add(explosions, explosion)
end


function enemy_projectiles()
    for enemy in all(enemies) do
        if enemy.logic.fire then
            if ((cur_frame - enemy.spawn_time)%enemy.logic.fire_rate) == 0 then
                if  flr((rnd(4))) == 1  then
                    create_enemy_bullet(enemy)
                end
            else
            end
        end
    end
    for enemy_bullet in all(enemy_bullets) do
        enemy_bullet.y += 0.75
        if cur_frame%enemy_bullet.x_speed==(0) then
            if enemy_bullet.direction == 1 then
                enemy_bullet.x -= flr(rnd(2))
            else if enemy_bullet.direction == 2 then
                enemy_bullet.x += flr(rnd(2))
            else
            end
            end
        end

        if enemy_bullet.y > 128 then
            del(enemy_bullets,enemy_bullet)
        end
        if player.invulnerable == false then
            if (objects_have_collided(enemy_bullet, player)) then
                sfx(0)
                del(enemy_bullets,enemy_bullet)
                handle_player_death()
            end
        end
    end 
end


function player_collision_with_ship()
    if player.invulnerable == false then
        for enemy in all(enemies) do 
            if (objects_have_collided(enemy, player)) then
                sfx(0)
                del(enemies,enemy)
                handle_player_death()
            end
        end
    end
end

function objects_have_collided(object1, object2)
    return object1.y < object2.y+object2.height and
        object1.y + object1.height > object2.y and 
        object1.x < object2.x + object2.width and 
        object1.x + object1.width > object2.x
end


function create_enemy_bullet(enemy)
    local enemy_bullet = {}
    enemy_bullet.x  = enemy.x+2
    enemy_bullet.y  = enemy.y+4
    enemy_bullet.x_speed = 4
    enemy_bullet.direction = enemy_bullet_direction
    enemy_bullet.width = 4
    enemy_bullet.height = 4
    enemy_bullet.sprite = 1
    add(enemy_bullets, enemy_bullet)
end

-->8
--drawing

function draw_background ()
    for background_star in all(background_array) do
        pset(background_star.x,background_star.y,background_star.color)
    end
end

function draw_explosions ()
    for explosion in all (explosions) do
        if explosion.t < 10 then
            circ(explosion.x,explosion.y,explosion.t,red)
            circ(explosion.x,explosion.y,explosion.t-1,orange)
            circ(explosion.x,explosion.y,explosion.t-2,yellow)
        else
            del(explosions, explosion)
        end
        explosion.t += 1
    end
    
end

function move_background()
    for background_star in all(background_array) do
        if cur_frame % background_star.speed == 0 then
            background_star.y += 1
            if background_star.y > 128 then 
                background_star.y = -8-flr(rnd(128))
                background_star.x = flr(rnd(128))
                set_star_speed(background_star)
            end
        end
    end
    if cur_frame%30 == 0 then
    decoration_ypos += 1
    end
end


function set_star_speed(background_star)
    s_x_diff = abs(background_star.x - 64) --the higher this number = the further from center of screen the star is

    if background_star.color == dark_blue then
        if s_x_diff > 48 then
            background_star.speed = 18
        elseif s_x_diff > 32 then
            background_star.speed = 16
        else
            background_star.speed = 14
        end
    elseif background_star.color == dark_purple then
        if s_x_diff > 48 then
            background_star.speed = 10
        elseif s_x_diff > 32 then
            background_star.speed = 9
        else
            background_star.speed = 7
        end
    elseif background_star.color == dark_gray then
        if s_x_diff > 48 then
            background_star.speed = 3
        elseif s_x_diff > 16 then
            background_star.speed = (2+flr(rnd(2)))
        else
            background_star.speed = 2
        end
    else    
        background_star.speed = 1    
    end    
end

    function draw_enemy_projectiles()
        for enemy_bullet in all(enemy_bullets) do
            spr(enemy_bullet.sprite,enemy_bullet.x,enemy_bullet.y)
        end    
        --rect(player.x,player.y,player.x+7,player.y+7,white) uncomment to see hitbox
    end
    function draw_boss_projectiles()
        for boss_bullet in all(boss_bullets) do
            spr(boss_bullet.sprite,boss_bullet.x,boss_bullet.y)
        end    
        --rect(player.x,player.y,player.x+7,player.y+7,white) uncomment to see hitbox
    end

    function draw_powerup()
        for powerup in all(powerups) do
            spr(2,powerup.x,powerup.y)
        end
    end
    
    function draw_enemies()
        for enemy in all(enemies) do 
            spr(19,enemy.x,enemy.y)
        end
    end
    
    function draw_player()
        if player.invulnerable == false then
            spr(8,player.x,player.y)
        else
            if invuln_timer > 30 then
                if invuln_timer % 4 == 0 then
                   spr(8,player.x,player.y)
                end
            else
                spr(8,player.x,player.y)
            end
        end
    end
    
    function draw_bullets()
        for bullet in all(bullets) do
            rect(bullet.x,bullet.y,bullet.x+1,bullet.y-1,white)
        end 
    end
    
    function draw_hud()
        for i=0,129 do
            if i%2 == 0 then
                pset(i,116,red)
                pset(i,114,dark_purple)
            else
                pset(i-2,115,red)
                pset(i-2,113,dark_purple)
            end
        end
        rectfill(0,117,127,128,red)
        print("score:",5,120,white)
        print(player.score,30,120,white)
        print("lives: ",80,120,white)
        print(player.lives,105,120,white)
    end

    function draw_game_over()
        print(game_state,45,50,blue)
    end

    function draw_decorations()
        if (cur_frame > 500 ) then
            spr(238,45,decoration_ypos-36+decoration_speed)
            spr(239,53,decoration_ypos-36+decoration_speed)
            spr(254,45,decoration_ypos-28+decoration_speed)
            spr(255,53,decoration_ypos-28+decoration_speed)
            
        end

        if (cur_frame > 1000 ) then
            pal(1,2,0)
            pal(13,14,0)
            spr(238,95,decoration_ypos-86+decoration_speed)
            spr(239,103,decoration_ypos-86+decoration_speed)
            spr(254,95,decoration_ypos-78+decoration_speed)
            spr(255,103,decoration_ypos-78+decoration_speed)
            pal()
            
        end
    end

    function draw_title_logo()
        for i=1,8 do
            spr(80+i,title_frame+(8*i)-title_offset,8)
            spr(96+i,title_frame+(8*i)-title_offset,16)
            spr(112+i,title_frame+(8*i)-title_offset,24)
            spr(88+i,title_frame+(8*i+8)-title_offset,26)
            spr(104+i,title_frame+(8*i+8)-title_offset,34)
            spr(120+i,title_frame+(8*i+8)-title_offset,42)
            
        end
    end
    -->8
    --game states?

    
-- function draw_enemy_hitbox () --testing where the hitbox is
--     rect(enemy.x+1,enemy.y+7,enemy.x+6,enemy.y,white)
-- end 

--draw_particles() enable this to show a small effect in the corner
    --pset(30,30,dark_blue) draws to an individual pixel
    --draw_enemy_hitbox()

    --49 to 52 = stars
__gfx__
00000000088000000000b000005500000088bb00009999000000b333880000000022000000000000000000000000000000000000000000000000555555550000
0000000087e80000000b0b000511500009993b8009777790000b3773880000000488400000000000000000000000000000000000000000000005111111115000
000000008ee8000000300030517c150099a999889799997900b37733000000000811800000000000000000000000000000000000000000000051122222211500
00000000088000000880088051cc150099999988979a99790b3773b300000000885588000000000000000000000000000000000000000000051122dddd221150
000000000000000088e888e8051150009aa99988979a9979b3773bb3000000004555540000000000000000000000000000000000000000005112277776c22115
000000000000000088888888005500009aa99988979999793773bb3300000000856658000000000000000000000000000000000000000000512277776c1c2215
000000000000000008800880000000000999988009777790373bb3b300000000044440000000000000000000000000000000000000000000512d7776c1c1d215
0000000000000000000000000000000000888800009999003333333300000000000000000000000000000000000000000000000000000000512d776c1c1cd215
0000000000000000000000000055550000000000000000000000000000000000000220000000000000000000000000000000000000000000512d76c1c1c1d215
0000000000000000000000000511115000000000000000000000000000000000004884000000000000000000000000000000000000000000512d6c1c1c1cd215
00000000000000000000000051776c15000000000000000000000000000000000081180000000000000000000000000000000000000000005122c1c1c1c12215
0000000000000000000000005176cc150000000000000000000000000000000008855880000000000000000000000000000000000000000051122c1c1c122115
000000000000000000000000516ccc1500000000000000000000000000000005045555405000000000000000000000000000000000000000051122dddd221150
00000000000000000000000051cccc15000000000000000000000000000000050856658050000000000000000000000000000000000000000051122222211500
00000000000000000000000005111150000000000000000000000000600000056688886650000046000000000000000000000000000000000005111111115000
00000000000000000000000000555500000000000000000000000000000000000008800000000000000000000000000000000000000000000000555555550000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000009999000999999000000000900000000000009999900000000999990000000999999000000000000000000009999990000999999000000000000
00000000000098888909888888900000009890000000000098888890000009888889000009888888900900000000000000098888889009888888900000000000
00000000000989999009899999890000098989000000000989999900000098999990000009899999009890000000000000098999990009899999000000000000
00000000009890000009890000989000098989000000009890000000000989000000000009890000009890000000000000098900000009890000000000000000
00000000009890000009890000989000989098900000098900000000009890000000000009890000009890000000000000098900000009890000000000000000
00000000009890000009890000989000989098900000098900000000009890000000000009890000009890000000000000098900000009890000000000000000
00000000000989000009890000989009890009890000098900000000009890000000000009890000009890000000000000098900000009890000000000000000
00000000000098900009899999890009890009890000098900000000009899999990000009899999009890000000000000098999990009899999000000000000
00000000000009890009888888900098999999989000098900000000009888888889000009888888909890000009000090098888889009888888900000000000
00000000000000989009899999000098888888889000098900000000009899999990000009899999009890000098900989098999990009899999000000000000
00000000000000098909890000000989999999998900098900000000009890000000000009890000009890000098900989098900000009890000000000000000
00000000000000008909890000000989000000098900098900000000009890000000000009890000009890000098900989098900000009890000000000000000
00000000000000098909890000009890000000009890098900000000009890000000000009890000009890000098900989098900000009890000000000000000
00000000000999989009890000009890000000009890009899999900000989999990000009890000009899999009899890098900000009890000000000000000
00000000009888890000900000000900000000000900000988888890000098888889000000900000000988888900988900009000000000900000000000000000
00000000000999990000000000000000000000000000000099999900000009999990000000000000000099999000099000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddddddd00000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1111331d0000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d331115311d000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d13333115131d00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d15333113331d00
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1115333335511d0
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1111333551111d0
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1113333331111d0
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1133333333311d0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d13333333351d00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d11333533511d00
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d153515511d000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1511111d0000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddddddd00000
__sfx__
000300001a550185501555013550115500c5500a55006550055500050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
0006000027550295502c5503055034550345500050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001963500605000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
0112002004135040200413500105070250b1140b0130e1250b13400105040240212102035070251710509135001050904500105090230e122001050414507135091350b125091250b0350e055100350000000000
011200201073502744177001774515735107030474313745157421a72202700107451c7200474209705137420970515740097031574000705137401c720117400b7050e742107410472002750007001375017720
011200200c0430c04300004000043c6150000400004000040c043000040c043000043c61500004000040c0430c0430c043000040c0433c615000040c043000040004400004000040c0433c6150c0430000400004
01120000107600e740107500e74010762007011375210752007000070115774157551176211752107740070015735157071577011755107600e7550070011762107400e7550070011762107600e775107440e760
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00060000170501b0501f0501b0501e050220501e04023040270402b0402f04033020360203a020100000a00006000020000000000000030000a0000c0000c0000d00000000000000000000000000000000000000
__music__
00 03040544
02 05030644

