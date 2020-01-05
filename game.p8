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
    create_events("enemy1", 2, 100, 75 ,10,-20,1)  
    create_events("enemy1", 1, 300, 75,80,-20,1)  
    create_events("enemy1", 1, 350, 75 ,30,-20,1)  
    create_events("enemy1", 1, 350, 75,100,-20,1)
    create_events("enemy1", 4, 600, 60 ,40,-20,1)  
    create_events("enemy1", 4, 600, 60, 80,-20,1)  
    create_events("enemy1", 1, 850, 75 ,50,-20,1)  
    create_events("enemy1", 1, 950, 75, 80,-20,1) 
    create_events("enemy1", 1, 50, 75, -20,40,4) 
    create_events("enemy1", 1, 50, 75, 148,20,5)
    
    init_session()

    
end

function init_session()
    create_player_vars()
    enemies={}
    bullets={}
    powerups={}
    cur_frame=0
    background_initialised = 0
    background_array = {}
    background_tile_1_offset = 128
    background_tile_2_offset = 0
    enemy_bullets = {}
    invuln_timer = 0
    explosions = {}
    
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
            cur_frame += 1
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
        print("press ❎ to start",28,60,white) 
        print("high score = " .. hi_score,33,100,white) 
    else 
        if game_state == "gameplay" then
            draw_background()
            draw_enemy_projectiles()
            draw_player()
            draw_bullets()
            draw_powerup()
            draw_enemies()
            draw_explosions()
            --KEEP THIS LAST. THAT MEANS YOU KRIS.
            draw_hud()
        else 
            if game_state == "game over" then
                draw_game_over()
                
                
            end         
        end
    end
end

-->8
--creation functions

function create_enemy_data()
    local enemy_one = {}
    enemy_one.path = {{20,10},{15,30},{100,20}}
    enemy_one.exit_d = "down"
    enemy_one.exit_s = 1
    return enemy_one
end

function create_events(eventType, quantity, initialFrame, frequency,x,y,direction)
    for i=1,quantity do 
        local event = {}
        event.eventType = eventType
        event.startFrame = initialFrame + (i*frequency)
        event.x = x
        event.y = y
        event.d = direction
        add(event_timeline, event)
    end
end

function check_game_started()
    if btnp(fire2) then
        game_state = "gameplay"
        music(0)
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
end

function create_powerup()
    local powerup={}
    powerup.x=59
    powerup.y=-10
    powerup.width = 8
    powerup.height = 6
    powerup.speed=1
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

function spawn_enemy_event(x, y,direction)
    local enemy={}
    enemy.alive=true
    enemy.x=x
    enemy.y=y
    enemy.speed=1
    enemy.tick_count=1 --used to calculate how often the enemys move updates, change this to change how often the enemy updates
    enemy.value=200
    enemy.counter=0
    enemy.direction=direction
    enemy.spawn_time = cur_frame-1
    enemy.attack={}
    enemy.attack.freq = 0
    enemy.attack.speed = 0
    enemy.attack.direction = 0
    enemy.attack.sprite = 0
    enemy.height = 6
    enemy.width = 6
    enemy.type = "enemy1"
    enemy.logic = create_enemy_data()
    add(enemies, enemy)
end


function check_event_timeline()
    for event in all(event_timeline) do
        if(event.eventType=="enemy1" and cur_frame==event.startFrame) then
            spawn_enemy_event(event.x,event.y,event.d)
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
            player_fire()    
        end
        if btnp(fire2) then
            create_powerup()
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
        powerup.y += powerup.speed
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
    if enemy.tick_count%4 == 0 then        
        enemy.tick_count = 1
        for coord in all(enemy.logic.path) do
            local x = coord[1]
            local y = coord[2]
            
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

            if enemy.x == x then
                if enemy.y == y then
                    del(enemy.logic.path, coord)
                end
            end
            return
        end
        if #enemy.logic.path == 0 then
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
    for bullet in all(bullets) do
        for enemy in all(enemies) do   
            if (objects_have_collided(bullet, enemy)) then
                enemy.alive = false
                player.score += enemy.value
                create_explosion(enemy.x,enemy.y)
                del(bullets, bullet)
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
        if ((cur_frame - enemy.spawn_time)%60) == 0 then
            if flr(rnd(3)) == 1 then
                create_enemy_bullet(enemy)
            end
        else
        end
    end
    for enemy_bullet in all(enemy_bullets) do
        enemy_bullet.y += 0.75
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
    enemy_bullet.x  = enemy.x
    enemy_bullet.y  = enemy.y+3
    enemy_bullet.width = 2
    enemy_bullet.height = 2
    enemy_bullet.sprite = 7
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

    function draw_powerup()
        for powerup in all(powerups) do
            spr(2,powerup.x,powerup.y)
        end
    end
    
    function draw_enemies()
        for enemy in all(enemies) do 
            spr(3,enemy.x,enemy.y)
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
00000000000770000000b000005500000088bb00009999000000b333880000000022000000000000000000000000000000000000000000000000000000000000
0000000000eeee00000b0b000511500009993b8009777790000b3773880000000488400000000000000000000000000000000000000000000000000000000000
000000000eeeeee000300030517c150099a999889799997900b37733000000000811800000000000000000000000000000000000000000000000000000000000
00000000881111880880088051cc150099999988979a99790b3773b3000000008855880000000000000000000000000000000000000000000000000000000000
00000000881cc18888e888e8051150009aa99988979a9979b3773bb3000000004555540000000000000000000000000000000000000000000000000000000000
00000000881cc18888888888005500009aa99988979999793773bb33000000008566580000000000000000000000000000000000000000000000000000000000
000000008811118808800880000000000999988009777790373bb3b3000000000444400000000000000000000000000000000000000000000000000000000000
00000000888888880000000000000000008888000099990033333333000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000060000000000055000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000606055000000555500005050000000000500005000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000060500500000555500500500000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000500500600055000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000055000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000010000000000000000012100005000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000600000001000000005000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000300001a550185501555013550115500c5500a55006550055500050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
0006000027550295502c5503055034550345500050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001963500605000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
0112002004135040200413500105070250b1140b0130e1250b13400105040240212102035070251710509135001050904500105090230e122001050414507135091350b125091250b0350e055100350000000000
011200201073502744177001774515735107030474313745157421a72202700107451c7200474209705137420970515740097031574000705137401c720117400b7050e742107410472002750007001375017720
011200200c0430c04300004000043c6150000400004000040c043000040c043000043c61500004000040c0430c0430c043000040c0433c615000040c043000040004400004000040c0433c6150c0430000400004
01120000107600e740107500e74010762007011375210752007000070115774157551176211752107740070015735157071577011755107600e7550070011762107400e7550070011762107600e775107440e760
__music__
00 03040544
02 05030644

