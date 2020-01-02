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
    create_events("enemy1", 2, 100, 75 ,10,-20)  
    create_events("enemy1", 1, 300, 75,80,-20)  
    create_events("enemy1", 1, 350, 75 ,30,-20)  
    create_events("enemy1", 1, 350, 75,100,-20)
    create_events("enemy1", 4, 600, 60 ,40,-20)  
    create_events("enemy1", 4, 600, 60, 80,-20)  
    create_events("enemy1", 1, 850, 75 ,50,-20)  
    create_events("enemy1", 1, 950, 75, 80,-20)  
    init_session()

    
end

function init_session()
    create_player_vars()
    enemies={}
    bullets={}
    powerups={}
    cur_frame=0
    init_star_array()
    background_initialised = 0
    background_array = {}
    background_tile_1_offset = 128
    background_tile_2_offset = 0
    enemy_bullets = {}
    invuln_timer = 0
    
    for i=1,256 do
        local background_star = {}
        background_star.x = flr(rnd(256)) - 128
        background_star.y = i%24*10-10
        background_star.speed = flr(rnd(2))+1
        if background_star.speed == 1 then
            background_star.color = white
        else
            if background_star.speed == 2 then
                background_star.color = dark_blue
            else
                background_star.color = dark_gray
            end
        end
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
            --KEEP THIS LAST. THAT MEANS YOU KRIS.
            draw_hud()
        else 
            if game_state == "game over" then
                draw_game_over()
            end
            print(cur_frame,5,5,white)
            
        end
        print(invuln_timer,50,5,blue)
    end
end

-->8
--creation functions

function init_star_array ()
    star_array = {}
    for i=1,17 do 
        star_array[i] = 52
        i+= 1
    end
    for i=12,14 do
        star_array[i] = 51
        i+=1
    end
    for i=14,15 do
        star_array[i] = 50
        i+=1
    end
    for i=15,16 do
        star_array[i] = 49
    end
    for i=16,17 do
        star_array[i] = 53
    end
end

function create_events(eventType, quantity, initialFrame, frequency,x,y)
    for i=1,quantity do 
        local event = {}
        event.eventType = eventType
        event.startFrame = initialFrame + (i*frequency)
        event.x = x
        event.y = y
        add(event_timeline, event)
    end
end

function check_game_started()
    if btnp(fire2) then
        game_state = "gameplay"
        music(-1)
        init_session()
    end
end

function create_player_vars()
    player={}
    player.alive=true
    player.x=59
    player.y=105
    player.width = 7
    player.height = 7
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
    bullet.x = player.x+3
    bullet.y = player.y+1
    bullet.width = 2
    bullet.height = 2
    bullet.speed=1
    add(bullets, bullet)
    sfx(0)
end

function spawn_enemy_event(x, y)
    local enemy={}
    enemy.alive=true
    enemy.x=x
    enemy.y=y
    enemy.speed=1
    enemy.tick_count=1 --used to calculate how often the enemys move updates, change this to change how often the enemy updates
    enemy.value=200
    enemy.counter=0
    enemy.direction=1 
    enemy.spawn_time = cur_frame-1
    enemy.attack={}
    enemy.attack.freq = 0
    enemy.attack.speed = 0
    enemy.attack.direction = 0
    enemy.attack.sprite = 0
    enemy.height = 6
    enemy.width = 6
    add(enemies, enemy)
end


function check_event_timeline()
    for event in all(event_timeline) do
        if(event.eventType=="enemy1" and cur_frame==event.startFrame) then
            spawn_enemy_event(event.x,event.y)
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

function check_enemy_moves(enemy)
    if enemy.tick_count%4 == 0 then        
        enemy.tick_count = 1
        if  (enemy.counter < 5 and enemy.direction == 1)  then
            move_enemy_right(enemy)
        else 
            enemy.direction = 0
        end
        
        if enemy.direction == 0 then
            move_enemy_left(enemy)
            
            if enemy.counter <-5 then
                enemy.direction = 1
            end
        end
        move_enemy_down(enemy)
    end   
    
end
function move_enemy_down(enemy)
    enemy.y+=enemy.speed
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
                del(bullets, bullet)
                sfx(2) 
            end
        end
    end
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
    sfx(0)
    
end

-->8
--drawing

function draw_background ()
    for background_star in all(background_array) do
        pset(background_star.x,background_star.y,background_star.color)
    end
end

function move_background()
        for background_star in all(background_array) do
            if cur_frame % background_star.speed == 0 then
                background_star.y += 1
                if background_star.y > 128 then 
                    background_star.y = -8-flr(rnd(128))
                    background_star.speed = flr(rnd(3)) + 1
                    background_star.x = flr(rnd(256)) - 129
                    if background_star.speed == 1 then
                        background_star.color = white
                    else
                        if background_star.speed == 2 then
                            background_star.color = dark_blue
                        else
                            background_star.color = dark_gray
                        end
                    end
            end
        end
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
            spr(1,player.x,player.y)
        else
            if invuln_timer > 30 then
                if invuln_timer % 4 == 0 then
                   spr(1,player.x,player.y)
                end
            else
                spr(1,player.x,player.y)
            end
        end
    end
    
    function draw_bullets()
        for bullet in all(bullets) do
            rect(bullet.x,bullet.y,bullet.x+1,bullet.y-1,white)
        end 
    end
    
    function draw_hud()
        rectfill(0,117,127,128,red)
        print("score:",5,120,white)
        print(player.score,30,120,white)
        print("lives: ",80,120,white)
        print(player.lives,105,120,white)
    end

    function draw_game_over()
        print(game_state,50,50,blue)
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
00000000000770000000b000005500000088bb00009999000000b333880000000000000000000000000000000000000000000000000000000000000000000000
0000000000eeee00000b0b000511500009993b8009777790000b3773880000000000000000000000000000000000000000000000000000000000000000000000
000000000eeeeee000300030517c150099a999889799997900b37733000000000000000000000000000000000000000000000000000000000000000000000000
00000000881111880880088051cc150099999988979a99790b3773b3000000000000000000000000000000000000000000000000000000000000000000000000
00000000881cc18888e888e8051150009aa99988979a9979b3773bb3000000000000000000000000000000000000000000000000000000000000000000000000
00000000881cc18888888888005500009aa99988979999793773bb33000000000000000000000000000000000000000000000000000000000000000000000000
000000008811118808800880000000000999988009777790373bb3b3000000000000000000000000000000000000000000000000000000000000000000000000
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
__music__
03 03040544

