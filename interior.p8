pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
WALL_FLAG = 1
DESK_FLAG = 2

ITEM_TYPES = {
  bed            = { sprite = 0 },
  chair          = { sprite = 1 },
  flower         = { sprite = 2 },
  table          = { sprite = 3 },
  tv             = { sprite = 4 },
  rug            = { sprite = 5 },
  mirror         = { sprite = 6 },
  acquarium      = { sprite = 7 },
  nes            = { sprite = 8 },
  tree           = { sprite = 9 },
  stereo         = { sprite = 10 },
  washer         = { sprite = 11 },
  clock          = { sprite = 12 },
  sink           = { sprite = 13 },
  frog           = { sprite = 14 },
  goomba         = { sprite = 15 },
  dog            = { sprite = 16 },
  shovel         = { sprite = 17 },
  pick_axe       = { sprite = 18 },
  lava_lamp      = { sprite = 19 },
  chest          = { sprite = 20 },
  bag            = { sprite = 21 },
  old_man        = { sprite = 22 },
  mouse          = { sprite = 23 },
  old_tv         = { sprite = 24 }, 
  computer       = { sprite = 54 }, 
  computer_chair = { sprite = 25 }, 
}

COST = 40

function shuffle(tbl)
  for i = #tbl, 2, -1 do
    local j = flr(rnd(i)) + 1
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end

  return tbl
end

function keys(t)
  local ks = {}
  local n = 0

  for k,v in pairs(t) do
    n += 1
    ks[n] = k
  end

  return ks, n
end

ITEM_KEYS, ITEM_COUNT = keys(ITEM_TYPES) 

NE = 0
ENTITY_ID = 0

MAP_X_COUNT = 10
MAP_Y_COUNT = 7

MAP_POS = {
  x = 2,
  y = 3,
}


MAP = {
  { NE, NE, NE, NE, NE, NE, NE, NE, NE, NE },
  { NE, NE, NE, NE, NE, NE, NE, NE, NE, NE },
  { NE, NE, NE, NE, NE, NE, NE, NE, NE, NE },
  { NE, NE, NE, NE, NE, NE, NE, NE, NE, NE },
  { NE, NE, NE, NE, NE, NE, NE, NE, NE, NE },
  { NE, NE, NE, NE, NE, NE, NE, NE, NE, NE },
  { NE, NE, NE, NE, NE, NE, NE, NE, NE, NE },
}

function pos_to_str(pos)
  return "{".. pos.x ..", ".. pos.y .. "}"
end

function map_get(pos)
  e = MAP[pos.y][pos.x]

  if e == 0 then
    return nil
  end

  return e
end

function map_insert(pos, entity)
  MAP[pos.y][pos.x] = entity
end

function merge(a, b)
  for k,v in pairs(b) do
    a[k] = v
  end

  return a
end

function next_id()
  ENTITY_ID += 1
  return ENTITY_ID
end

-- quick note because I often forget the background map is in tiles not pixels
-- WHOAT okay so this mget function seems to be absolute to its position
-- in the screen. So this function is /uneffected/ by the shift down for text
function bg_collision(pos, flag)
  local pos = {
    x = pos.x + MAP_POS.x,
    -- this -1 accomodates the shift down for text
    y = pos.y + MAP_POS.y - 1, 
  }

  if fget(mget(pos.x, pos.y), flag) then
    return true
  end

  return false
end

function entity_collision(entity_a, entity_b)
  if
    ((entity_a.pos.x + entity_a.dim.x) > entity_b.pos.x) and
    (entity_a.pos.x                    < (entity_b.pos.x + entity_b.dim.x)) and
    ((entity_a.pos.y + entity_a.dim.y) > entity_b.pos.y) and
    (entity_a.pos.y                    < (entity_b.pos.y + entity_b.dim.y)) then
    return true
  end

 return false
end

-- takes a map relative sprite position and maps it into the pixel
-- positions of the screen.
-- 
-- given a map draw at 16,16 we previously converted the pixel locations
-- into sprite boundaries for easyness so this is represented as 2,2
-- and a map relative position of 3,3
--
-- we would first add the map position and the relative positions together
-- to get 5,5 then multiply by 8 to get the pixel location (40,40)
function scale_position(pos)
  return {
    x = (pos.x + MAP_POS.x) * 8,
    y = (pos.y + MAP_POS.y) * 8,
  }
end

function entity_new(opts)
  id = next_id()

  local entity = {
    label = opts.label or "unlabeled",
    id = id,
    pos = opts.pos,
    vel = opts.vel or {x = 1, y = 1},
    dim = opts.dim or {x = 0, y = 0},
    sprite = opts.sprite,
    visible = opts.visible or true,
    movable = opts.movable,
    _draw = opts._draw,
  }

   map_insert(opts.pos, entity)

  return entity
end

function entity_draw(entity, pos)
  if entity.visible then
    if entity._draw then
      entity:_draw(pos)
    else
      sprite_draw(merge(entity.sprite, scale_position(pos)))
    end
  end
end

function sprite_draw(sprite)
  spr(
    sprite.index,
    sprite.x, sprite.y,
    sprite.scale_x or 1, sprite.scale_y or 1,
    sprite.flip_x or false, sprite.flip_y or false
  )
end

function btn_direction()
  if (btnp(0)) then
    return "w"
  elseif (btnp(1)) then
    return "e"
  elseif (btnp(2)) then
    return "n"
  elseif (btnp(3)) then
    return "s"
  end
end

function game_new()
  return {
    cash = 200,
    target_cash = 200,
    drop_timer = 0,
    work_timer = 0,
    cursor_blink_timer = 0,
    cusor_state = true,
    state = "decorating",
    problem = problem_new(),
  }
end

function hero_new(opts)
  return entity_new {
    label = "hero",
    sprite = { index = 48 },
    pos = opts.pos,
    vel = { x = 1, y = 1},
    dim = { x = 5, y = 8},
    map = false,
  }
end

function item_new(item_type, opts)
  item_config = ITEM_TYPES[item_type]

  return entity_new {
    label = item_type,
    sprite = { index = item_config.sprite },
    pos = opts.pos,
    dim = { x = 8, y = 8},
    map = true,
    movable = opts.movable,
    _draw = opts._draw,
  }
end

function rnd_math_p()
  local x = flr(rnd(100))
  local y = flr(rnd(100))
  return x + y
end

function problem_new()
  local x = flr(rnd(100))
  local y = flr(rnd(100))

  local answer = x + y
  
  local options = {
    rnd_math_p(), rnd_math_p(), rnd_math_p(), answer
  }

  shuffle(options)

  return {
    x = x,
    y = y,
    options = options,
    answer = answer,
    selected = nil
  }
end

GAME = game_new()

COMPUTER = item_new("computer", {
  pos = {x = 9, y = 2},
  movable = false,
  _draw = function (self, pos)
    if GAME.cursor_state then
      self.sprite.index = 54 
    else
      self.sprite.index = 55
    end
    sprite_draw(merge(self.sprite, scale_position(pos)))
  end
})

CHAIR = item_new("table", {
  pos = {x = 9, y = 3},
  movable = false,
})

COMPUTER_CHAIR = item_new("computer_chair", {
  pos = {x = 8, y = 3},
  movable = false,
})

HERO = hero_new {pos = {x = 7, y = 4}}

DIR_TO_VEL = {
  n = { x = 0,  y = -1 },
  e = { x = 1,  y = 0  },
  s = { x = 0,  y = 1  },
  w = { x = -1, y = 0  },
}

function shift_dir(start, dir)
  local vel = DIR_TO_VEL[dir]

  local e = map_get(start)

  -- I don't remember why
  if e == NE then
    return false
  end

  local next_pos = apply_dir(start, dir)

  if not in_map(next_pos) then
    return false
  end

  map_insert(next_pos, e)
  map_insert(start, NE)
  e.pos = next_pos
  return true
end

function apply_dir(pos, dir)
  local vel = DIR_TO_VEL[dir]

  return {
    x = pos.x + vel.x,
    y = pos.y + vel.y,
  }
end

function hero_update(hero)
  local dir = btn_direction()

  if not dir then
    return
  end

  local old_pos = hero.pos
  local new_pos = apply_dir(old_pos, dir)

  if not bg_collision(new_pos, WALL_FLAG) then
    local collision = map_get(new_pos)

    if collision then
      if collision.label == "computer_chair" then
        GAME.state = "working"
      elseif collision.movable then
        if shift_dir(collision.pos, dir) then
          shift_dir(hero.pos, dir)
        end
      end
    else
      shift_dir(hero.pos, dir)
    end
  end
end

function can_move_into(e)
  if e == NE then
    return true
  end

  return e.movable
end

function in_map(pos)
  return pos.x >= 1 and pos.x <= MAP_X_COUNT and
         pos.y >= 1 and pos.y <= MAP_Y_COUNT
end

-- looks in a direction through MAP to find if
-- there we can shift items that direction
function can_shift(pos, dir)
  while in_map(pos) do
    if can_move_into(e) then
      return true
    end
  end
  return false
end

function shift(pos, dir)
  if dir == "n" then
    for y = pos.y, y-1, y > 0 do
      local e = map_get({x = pos.x, y = y})
      return can_move_into(e)
    end
  elseif dir == "e" then
    for x = pos.x, x+1, x <= MAP_X_COUNT do
      local e = map_get({x = x, y = pos.y})
      return can_move_into(e)
    end
  elseif dir == "s" then
    for y = pos.y, y+1, y <= MAP_Y_COUNT do
      local e = map_get({x = pos.x, y = y})
      return can_move_into(e)
    end
  elseif dir == "w" then
    for x = pos.x, x-1, x > 0 do
      local e = map_get({x = x, y = pos.y})
      return can_move_into(e)
    end
  end

  -- this is a failure scenario
  return false
end

function find_empty()
  local slots = {}
  local count = 0

  for y, row in ipairs(MAP) do
    for x, e in ipairs(row) do
      if e == NE then
        add(slots, {x = x, y = y})
        count += 1
      end
    end
  end

  if count == 0 then
    return nil
  end

  return slots[flr(rnd(count))]
end

function random_item(pos)
  t = ITEM_KEYS[flr(rnd(ITEM_COUNT) + 1)]

  return item_new(t, {
    pos = pos,
    movable = true,
  })
end

function btn_choice_index()
  if (btnp(0)) then
    return 1
  elseif (btnp(1)) then
    return 2
  elseif (btnp(2)) then
    return 3
  elseif (btnp(3)) then
    return 4
  end
end

function working_update()
  if btnp(4) and GAME.problem.selected then
    if GAME.problem.selected == GAME.problem.answer then
      printh("CORRECT")
      GAME.target_cash += 10
      GAME.problem = problem_new()
    else
      printh("INCORRECT")
      GAME.problem = problem_new()
    end
  elseif btnp(5) then
    GAME.state = "decorating"
  else
    local choice = GAME.problem.options[btn_choice_index()]

    if choice then
      GAME.problem.selected = choice
    end
  end
end

function _update()
  if GAME.state == "working" then
    working_update()
  elseif GAME.state == "decorating" then
    -- 30fps * 10s
    if GAME.drop_timer > 200 then
      GAME.drop_timer = 0
      GAME.target_cash -= COST

      if GAME.cash <= 0 then
        GAME.state = "starved"
        return
      end

      local pos = find_empty()

      if not pos then
        GAME.state = "crushed"
        return
      end

      random_item(pos)
    end

    hero_update(HERO)
  end
end

function update_cursor_state()
    GAME.cursor_blink_timer += 1

    if GAME.cursor_blink_timer >= 15 then
      GAME.cursor_blink_timer = 0

      if GAME.cursor_state then
        GAME.cursor_state = false
      else
        GAME.cursor_state = true
      end
    end
end

options_map = {"\139", "\145", "\148", "\131"}

function _draw()
  update_cursor_state()
  if GAME.state == "decorating" then

    if GAME.cash > GAME.target_cash then
      GAME.cash -= 1
    elseif GAME.cash < GAME.target_cash then
      GAME.cash += 1
    end

    GAME.drop_timer += 1

    cls()
    map(0,0,0,8,64,64)

    for y, row in ipairs(MAP) do
      for x, e in ipairs(row) do 
        if e != NE then
          entity_draw(e, {x = x, y = y})
        end
      end
    end
    print("CASH: $"..GAME.cash)
  elseif GAME.state == "working" then
    cls()

    if GAME.cursor_state then
      cursor = "_"
    else
      cursor = " "
    end

    problem = "what is " .. GAME.problem.x .. " + " .. GAME.problem.y .. "?"

    color(11)
    print(problem)

    for i, v in ipairs(GAME.problem.options) do
      print(options_map[i] .. ": " .. v)
    end

    if GAME.problem.selected then
      print("> " .. GAME.problem.selected .. " " .. cursor)
    else
      print("> " .. cursor)
    end
    color(7)
  elseif GAME.state == "crushed" then
    cls()
    print("YOU ARE CRUSHED")
  elseif GAME.state == "starved" then
    cls()
    print("YOU MUST WORK TO EAT")
  end
end

__gfx__
000000000000000000889880004444440060060000000000004444000055555000000000000b3000000000007777777706600660000000000000000000044000
00000000000444000088888004444444000660000000000004cccc4005ccccc50000000000bbb300000000007977770700888800000550000000000000444400
00400004004040400008380044444445055555500009090904cccc40455555540006666603bbbb30555555557755557708077780005005000000000005444450
044ccc44004040400000300044444405056dd65000dedede04cccc405c8848b500655566003bb30055551a15750000570870708000500500000000004f0000f4
4477c44500455540044444445050050505d6dd500dedede004ccc64058088ec506555656000b30005005a9a5750000570877578077c7757700e0e0004f0440f4
4cccc440044444500449494450000500056dd650dedede0004cc6c405c8ec8450655866000045000555591957500005708777780077cc5700333350004444440
4000040006506050004494400000000005555550edede0000544445055555555066666000d5445d055555555775555770088880007ccc77000bbb35045ffff00
00000000060060000004440000000000040000409090900004000040050000500000000000d55500000000005777777505500550007777000b3b3330045f5550
09fff000400000000000000000066000044444400000000000ffff00000000000060600000000000000000000000000000000000000000000000000000000000
475f570044000000005556000068760095555559449999440ffffff0000000000006000004440000000000000000000000000000000000000000000000000000
4fff455004400000055555600067760000000000044594400f0ff0f0000000000444449040404000000000000000000000000000000000000000000000000000
4994444000440500555945560067860000000000004444000f0770f0000500004500074940404000000000000000000000000000000000000000000000000000
40880e00000446506500405600686600a9aa999904544540087ff780006760004500004945554000000000000000000000000000000000000000000000000000
0fffa0000055666500094000000660004555555444444454887777880606660f4600004944444400000000000000000000000000000000000000000000000000
ffff00000005566500004000000550004555555444444454f887788fe66666ef4665504960506050000000000000000000000000000000000000000000000000
09f09000000055500009400000555500944444490444454008888880005050000444449060506050000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
94440000544440540000000044444440005445003b33333300555550005555500000000000000000000000000000000000000000000000000000000000000000
ffff0000544440540000000056614140007c4c00bb3333b306666650066666500000000000000000000000000000000000000000000000000000000000000000
75f50000000000000000000055554140007c7c003333b33306000650060006500000000000000000000000000000000000000000000000000000000000000000
ffff0000505555550000000041414540007ccc003b333b330600065006b006500000000000000000000000000000000000000000000000000000000000000000
3bbb0000405444440000000041415650007cc700b333bbb306000650060006500000000000000000000000000000000000000000000000000000000000000000
f3bbf000405444440000000041414540007c7c003b33333306666650066666500000000000000000000000000000000000000000000000000000000000000000
111100000000000000000000566141400074cc00bbb3333367778670677786700000000000000000000000000000000000000000000000000000000000000000
10010000555550550000000055554440005445003333333366666006666660060000000000000000000000000000000000000000000000000000000000000000
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888ffffff882222228888888888888888888888888888888888888888888888888888888888888888228228888ff88ff888222822888888822888888228888
88888f8888f882888828888888888888888888888888888888888888888888888888888888888888882288822888ffffff888222822888882282888888222888
88888ffffff882888828888888888888888888888888888888888888888888888888888888888888882288822888f8ff8f888222888888228882888888288888
88888888888882888828888888888888888888888888888888888888888888888888888888888888882288822888ffffff888888222888228882888822288888
88888f8f8f88828888288888888888888888888888888888888888888888888888888888888888888822888228888ffff8888228222888882282888222288888
888888f8f8f8822222288888888888888888888888888888888888888888888888888888888888888882282288888f88f8888228222888888822888222888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555550000000000000000000000000000000000000000000000000000000000000000005555550000000000000000000000000000007777777777775555555
5555555033333333bbbbbbbb33333333333333333333333333333333333333333333333305555550000000000011111111112222222227000000000075555555
5555555033333333bbbbbbbb33333333333333333333333333333333333333333333333305555550000000000011111111112222222227033333333075555555
5555555033333333bbbbbbbb33333333333333333333333333333333333333333333333305555550000000000011111111112222222227033333333075555555
5555555033333333bbbbbbbb33333333333333333333333333333333333333333333333305555550000000000011111111112222222227033333333075555555
5555555033333333bbbbbbbb33333333333333333333333333333333333333333333333305555550000000000011111111112222222227033333333075555555
5555555033333333bbbbbbbb33333333333333333333333333333333333333333333333305555550000000000011111111112222222227033333333075555555
5555555033333333bbbbbbbb33333333333333333333333333333333333333333333333305555550000000000011111111112222222227033333333075555555
5555555033333333bbbbbbbb33333333333333333333333333333333333333333333333305555550000000000011111111112222222227033333333075555555
55555550bbbbbbbbbbbbbbbb33333333333333333333333333333333bbbbbbbb3333333305555550000000000011111111112222222227000000000075555555
55555550bbbbbbbbbbbbbbbb33333333333333333333333333333333bbbbbbbb3333333305555550444444444455555555556666666667777777777775555555
55555550bbbbbbbbbbbbbbbb33333333333333333333333333333333bbbbbbbb3333333305555550444444444455555555556666666666777777777705555555
55555550bbbbbbbbbbbbbbbb33333333333333333333333333333333bbbbbbbb3333333305555550444444444455555555556666666666777777777705555555
55555550bbbbbbbbbbbbbbbb33333333333333333333333333333333bbbbbbbb3333333305555550444444444455555555556666666666777777777705555555
55555550bbbbbbbbbbbbbbbb33333333333333333333333333333333bbbbbbbb3333333305555550444444444455555555556666666666777777777705555555
55555550bbbbbbbbbbbbbbbb33333333333333333333333333333333bbbbbbbb3333333305555550444444444455555555556666666666777777777705555555
55555550bbbbbbbbbbbbbbbb33333333333333333333333333333333bbbbbbbb3333333305555550444444444455555555556666666666777777777705555555
5555555033333333333333333333333333333333bbbbbbbb33333333333333333333333305555550444444444455555555556666666666777777777705555555
5555555033333333333333333333333333333333bbbbbbbb33333333333333333333333305555550444444444455555555556666666666777777777705555555
5555555033333333333333333333333333333333bbbbbbbb3333333333333333333333330555555088888888889999999999aaaaaaaaaabbbbbbbbbb05555555
5555555033333333333333333333333333333333bbbbbbbb3333333333333333333333330555555088888888889999999999aaaaaaaaaabbbbbbbbbb05555555
5555555033333333333333333333333333333333bbbbbbbb3333333333333333333333330555555088888888889999999999aaaaaaaaaabbbbbbbbbb05555555
5555555033333333333333333333333333333333bbbbbbbb3333333333333333333333330555555088888888889999999999aaaaaaaaaabbbbbbbbbb05555555
5555555033333333333333333333333333333333bbbbbbbb3333333333333333333333330555555088888888889999999999aaaaaaaaaabbbbbbbbbb05555555
5555555033333333333333333333333333333333bbbbbbbb3333333333333333333333330555555088888888889999999999aaaaaaaaaabbbbbbbbbb05555555
5555555033333333bbbbbbbb333333333333333333333333bbbbbbbb33333333333333330555555088888888889999999999aaaaaaaaaabbbbbbbbbb05555555
5555555033333333bbbbbbbb333333333333333333333333bbbbbbbb33333333333333330555555088888888889999999999aaaaaaaaaabbbbbbbbbb05555555
5555555033333333bbbbbbbb333333333333333333333333bbbbbbbb33333333333333330555555088888888889999999999aaaaaaaaaabbbbbbbbbb05555555
5555555033333333bbbbbbbb333333333333333333333333bbbbbbbb333333333333333305555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
5555555033333333bbbbbbbb333333333333333333333333bbbbbbbb333333333333333305555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
5555555033333333bbbbbbbb333333333333333333333333bbbbbbbb333333333333333305555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
5555555033333333bbbbbbbb333333333333333333333333bbbbbbbb333333333333333305555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
5555555033333333bbbbbbbb333333333333333333333333bbbbbbbb333333333333333305555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
55555550bbbbbbbb333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbb3333333305555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
55555550bbbbbbbb333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbb3333333305555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
55555550bbbbbbbb333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbb3333333305555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
55555550bbbbbbbb333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbb3333333305555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
55555550bbbbbbbb333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbb3333333305555550000000000000000000000000000000000000000005555555
55555550bbbbbbbb333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbb3333333305555555555555555555555555555555555555555555555555555555
55555550bbbbbbbb333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbb3333333305555555555555555555555555555555555555555555555555555555
55555550bbbbbbbb333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbb3333333305555555555555555555555555555555555555555555555555555555
5555555033333333bbbbbbbb33333333333333333333333333333333333333333333333305555550000000555556667655555555555555555555555555555555
5555555033333333bbbbbbbb33333333333333333333333333333333333333333333333305555550000000555555666555555555555555555555555555555555
5555555033333333bbbbbbbb3333333333333333333333333333333333333333333333330555555000000055555556dddddddddddddddddddddddd5555555555
5555555033333333bbbbbbbb333333333333333333333333333333333333333333333333055555500030005555555655555555555555555555555d5555555555
5555555033333333bbbbbbbb33333333333333333333333333333333333333333333333305555550000000555555576666666d6666666d666666655555555555
5555555033333333bbbbbbbb33333333333333333333333333333333333333333333333305555550000000555555555555555555555555555555555555555555
5555555033333333bbbbbbbb33333333333333333333333333333333333333333333333305555550000000555555555555555555555555555555555555555555
5555555033333333bbbbbbbb33333333333333333333333333333333333333333333333305555555555555555555555555555555555555555555555555555555
55555550bbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333305555555555555555555555555555555555555555555555555555555
55555550bbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333305555556665666555556667655555555555555555555555555555555
55555550bbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333305555556555556555555666555555555555555555555555555555555
55555550bbbbbbbbbbbbbbbbbbbbbbbb33333333333333333333333333333333333333330555555555555555555556dddddddddddddddddddddddd5555555555
55555550bbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333333333333333333055555565555565555555655555555555555555555555d5555555555
55555550bbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333305555556665666555555576666666d6666666d666666655555555555
55555550bbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333305555555555555555555555555555555555555555555555555555555
55555550bbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333305555555555555555555555555555555555555555555555555555555
55555550333333333333333333333333333333333333333333333333333333333333333305555555555555555555555555555555555555555555555555555555
55555550333333333333333333333333333333333333333333333333333333333333331305555555555555555555555555555555555555555555555555555555
55555550333333333333333333333333333333333333333333333333333333333333317105555550005550005550005550005550005550005550005550005555
555555503333333333333333333333333333333333333333333333333333333333331333155555011d05011d05011d05011d05011d05011d05011d05011d0555
55555550333333333333333333333333333333333333333333333333333333333331733371555501110501110501110501110501110501110501110501110555
55555550333333333333333333333333333333333333333333333333333333333333133315555501110501110501110501110501110501110501110501110555
55555550333333333333333333333333333333333333333333333333333333333333317105555550005550005550005550005550005550005550005550005555
55555550333333333333333333333333333333333333333333333333333333333333331305555555555555555555555555555555555555555555555555555555
55555550000000000000000000000000000000000000000000000000000000000000000005555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555555575555555ddd55555d5d5d5d55555d5d555555555d5555555ddd5555553b33333355555555555555555555555555555555555555555555555555
555555555555777555555ddd55555555555555555d5d5d55555555d55555d555d55555bb3333b356666666666666555557777755555555555555555555555555
555555555557777755555ddd55555d55555d55555d5d5d555555555d555d55555d55553333b33356ddd6ddd6ddd6555577ddd775566666555666665556666655
555555555577777555555ddd55555555555555555ddddd5555ddddddd55d55555d55553b333b3356d6d6d66666d6555577d7d77566dd666566ddd66566ddd665
5555555557577755555ddddddd555d55555d555d5ddddd555d5ddddd555d55555d5555b333bbb356d6d6ddd66dd6555577d7d775666d66656666d665666dd665
5555555557557555555d55555d55555555555555dddddd555d55ddd55555d555d555553b33333356d6d666d666d6555577ddd775666d666566d666656666d665
5555555557775555555ddddddd555d5d5d5d555555ddd5555d555d5555555ddd555555bbb3333356ddd6ddd6ddd655557777777566ddd66566ddd66566ddd665
55555555555555555555555555555555555555555555555555555555555555555555553333333356666666666666555577777775666666656666666566666665
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555566666665ddddddd5ddddddd5ddddddd5
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000044444000088988000000000006006000000000000444400005555500000000000033000000000007777777706600660000000000000000000044000
00000000040404000088888000000000000660000000000004cccc4005ccccc50000000000b3b300000000007977770700888800000550000000000000444400
00400004040404000008380000444444055555500009090904cccc40455555540006666603333b30555555557755557708077780005005000000000005444450
044ccc44044444000000300004444444056dd65000dedede04cccc405c8c43b500655566003b330055551a15750000570870708000500500000000004f0000f4
4477c44505444440044444444444444505d6dd500dedede004ccc640580cc4c506555656000330005005a9a5750000570877578077c7757700e0e0004f0440f4
4cccc440050444500449494444444405056dd650dedede0004cc6c405c8ccc450655866000044000555591957500005708777780077cc5700333350004444440
4000040005055050004494405050050505555550edede0000544445055555555066666000554455055555555775555770088880007ccc77000bbb35045ffff00
00000000000050000004440050000500040000409090900004000040050000500000000000555500000000005777777505500550007777000b3b3330045f5550
09fff000400000000000000000066000044444400000000000ffff00000000000000000000000000000000000000000000000000000000000000000000000000
475f570044000000005556000068760095555559449999440ffffff0000000000000000000000000000000000000000000000000000000000000000000000000
4fff455004400000055555600067760000000000044594400f0ff0f0000000000000000000000000000000000000000000000000000000000000000000000000
4994444000440500555945560067860000000000004444000f0770f0000500000000000000000000000000000000000000000000000000000000000000000000
40880e00000446506500405600686600a9aa999904544540087ff780006760000000000000000000000000000000000000000000000000000000000000000000
0fffa0000055666500094000000660004555555444444454887777880606660f0000000000000000000000000000000000000000000000000000000000000000
ffff00000005566500004000000550004555555444444454f887788fe66666ef0000000000000000000000000000000000000000000000000000000000000000
09f09000000055500009400000555500944444490444454008888880005050000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000077777777770000000000000000000000000000000000000000000000000000000000000000000000000000000
94440000544440540000000044444440005445073b33333370000000000000000000000000000000000000000000000000000000000000000000000000000000
ffff000054444054000000005661414000cc4c07bb3333b370000000000000000000000000000000000000000000000000000000000000000000000000000000
75f5000000000000000000005555414000cccc073333b33370000000000000000000000000000000000000000000000000000000000000000000000000000000
ffff000050555555000000004141454000cccc073b333b3370000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbb000040544444000000004141565000cccc07b333bbb370000000000000000000000000000000000000000000000000000000000000000000000000000000
f3bbf00040544444000000004141454000cccc073b33333370000000000000000000000000000000000000000000000000000000000000000000000000000000
1111000000000000000000005661414000c4cc07bbb3333370000000000000000000000000000000000000000000000000000000000000000000000000000000
10010000555550550000000055554440005445073333333370000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000077777777770000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
3535353535353535353535353535353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3535353535353535353535353535353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3535313131313131313131313131353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
35353100000000000000003b0031353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
353531000000000000003b3b0031353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3535340000000000000000000034353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3535340000000000000000000034353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3535340000000000000000000034353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3535310000000000000000000031353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3535310000000000000000000031353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3535313131313131333131313131353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3535353535353535353535353535353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3535353535353535353535353535353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3535353535353535353535353535353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
