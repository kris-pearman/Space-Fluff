pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
left,right,up,down,fire1,fire2=0,1,2,3,4,5
black,dark_blue,dark_purple,dark_green,brown,dark_gray,light_gray,white,red,orange,yellow,green,blue,indigo,pink,peach=0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15

function _init()
    create_player_vars()
    enemies = {}
    bullets={}
    game_state = "start"
    powerups={}
end

function _update60()
    if game_state == "start" then
        check_game_started()
    else
        handle_input()
        move_bullets()
        move_powerup()
        hit_detect_powerup()
        hide_dead_enemies()
        enemy_collision()
    end
end

function _draw()
    cls(black)
    if game_state == "start" then
        print("press fire to start",28,60,white)  
    else
        draw_player()
        draw_bullets()
        draw_hud()
        draw_powerup()
        draw_enemies()
    end
end

-->8
--functions in here

function check_game_started()
    if btnp(fire1) then
        game_state = "gameplay"
   end
end

function create_player_vars()
    player={}
    player.alive=false
    player.x=59
    player.y=105
    player.score=0
end

function create_powerup()
    local powerup={}
    powerup.x=59
    powerup.y=-10
    powerup.speed=1
    powerup.collected=false
    powerup.value=100
    add(powerups,powerup)
end

function draw_player()
    spr(1,player.x,player.y)
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
end
    
-->8
--player input functions here
function handle_input() 
    if btn(left) then
        player.x -= 1
    end
    if btn(right) then
        player.x += 1
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
        spawn_enemy()
        create_powerup()
    end
end

function player_fire()
    local bullet = {}
    bullet.x = player.x+3
    bullet.y = player.y+1
    bullet.speed=1
    add(bullets, bullet)
    sfx(0)
end

function draw_enemies()
    for enemy in all(enemies) do 
        spr(3,enemy.x,enemy.y)
    end
end

function spawn_enemy()
    local enemy={}
    enemy.alive=true
    enemy.x=59
    enemy.y=60
    enemy.speed=1
    enemy.tick_count=1 --used to calculate how often the enemys move updates, change this to change how often the enemy updates
    enemy.value=200
    enemy.counter=0
    enemy.direction=1 
    add(enemies, enemy)
end
    
-->8
--powerup functions here

function draw_powerup()
    for powerup in all(powerups) do
        spr(2,powerup.x,powerup.y)
    end 
end

function move_powerup()
    for powerup in all(powerups) do
        if powerup.collected == false then
            powerup.y += powerup.speed
        else
            del(powerups,powerup)
        end
    end
end

function hit_detect_powerup()
    for powerup in all(powerups) do
        if (player.x > powerup.x-2 and player.x < powerup.x+2 and player.y == powerup.y) then
            powerup.collected = true
            player.score += powerup.value
            sfx(1)
        end
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
--AI

function hide_dead_enemies()
    for enemy in all(enemies) do
        if enemy.alive then
            check_enemy_moves(enemy)
            enemy.tick_count += 1
        else
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
    end   
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
            if (bullet.x > enemy.x+1 and
                bullet.x < enemy.x+6 and
                bullet.y > enemy.y and
                bullet.y < enemy.y +7
            ) then
                enemy.alive = false
                player.score += enemy.value
                del(bullets, bullet)
                sfx(2) 
            end
        end
    end
end


-- function draw_enemy_hitbox () --testing where the hitbox is
--     rect(enemy.x+1,enemy.y+7,enemy.x+6,enemy.y,white)
-- end 

--draw_particles() enable this to show a small effect in the corner
    --pset(30,30,dark_blue) draws to an individual pixel
    --draw_enemy_hitbox()
__gfx__
00000000000000000000b000000000000088bb00009999000000b333000000000000000000000000000000000000000000000000000000000000000000000000
0000000000077000000b0b000005500009993b8009777790000b3773000000000000000000000000000000000000000000000000000000000000000000000000
00000000006ee600003000300051150099a999889799997900b37733000000000000000000000000000000000000000000000000000000000000000000000000
0000000005888850088008800517c15099999988979a99790b3773b3000000000000000000000000000000000000000000000000000000000000000000000000
00000000058cc85088e888e8051cc1509aa99988979a9979b3773bb3000000000000000000000000000000000000000000000000000000000000000000000000
000000000588885088888888005115009aa99988979999793773bb33000000000000000000000000000000000000000000000000000000000000000000000000
000000000555555008800880000550000999988009777790373bb3b3000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000008888000099990033333333000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000300001a550185501555013550115500c5500a55006550055500050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
0006000027550295502c5503055034550345500050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001963500605000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
