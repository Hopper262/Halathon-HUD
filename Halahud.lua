-- Halathon HUD version 1.0
-- by Hopper and TychoVII

-- colors, in R, G, B, alpha format
clrs = {}

clrs["shields_single"] = { 0.20, 0.54, 1.00, 1.0 }
clrs["shields_double"] = { 1.00, 0.20, 0.48, 1.0 }
clrs["shields_triple"] = { 0.20, 1.00, 0.75, 1.0 }

clrs["shields_underlay"] = { 0.69, 0.85, 1.00, 1.0 }
clrs["shields_underlay_low1"] = { 1.0, 1.0, 1.0, 1.0 }
clrs["shields_underlay_low2"] = { 1.0, 0.0, 0.0, 1.0 }

clrs["shields_overlay"] = clrs["shields_underlay"]
clrs["shields_overlay_low1"] = clrs["shields_underlay_low1"]
clrs["shields_overlay_low2"] = clrs["shields_underlay_low2"]

lowshields_level = 150 * 1/5    -- in native health units
lowshields_flash = 15           -- cycle time, in ticks
shields_damage_flash = 0        -- damage-shown time, in ticks


clrs["health_high"] = { 0.20, 0.63, 1.00, 1.0 }
clrs["health_med"] =  { 0.80, 0.80, 0.20, 1.0 }
clrs["health_low"] =  { 1.00, 0.00, 0.00, 1.0 }

medhealth_level = 10800 * 2/3   -- in native oxygen units
lowhealth_level = 10800 * 1/3   -- in native oxygen units


clrs["weapons_underlay"] = clrs["shields_underlay"]
clrs["weapons_underlay_low1"] = clrs["weapons_underlay"]
clrs["weapons_underlay_low2"] = { 1.00, 0.40, 0.10, 1.0 }

clrs["weapons_overlay"] = clrs["shields_overlay"]

clrs["bullet_ready"] = { 0.20, 0.63, 1.00, 1.0 }
clrs["bullet_spent"] = { 0.20, 0.63, 1.00, 0.5 }

clrs["weapons_data"] = { 1.00, 1.00, 1.00, 1.0 }

clrs["uplink_chip"] = clrs["bullet_ready"]

clrs["energy_underlay"] = clrs["bullet_ready"]
clrs["energy_overlay"] = clrs["shields_overlay"]

-- color animations
-- each animation is an array of: color, repeat ticks, blend-with-next ticks
anims = {}

-- low ammo flash animation
anims["lowammo_flash"] = {
  { clrs["weapons_underlay_low2"], 0, 3 },
  { clrs["weapons_underlay_low1"], 0, 2 },
  { clrs["weapons_underlay_low2"], 0, 3 },
  { clrs["weapons_underlay_low1"], 0, 2 },
  { clrs["weapons_underlay_low2"], 0, 5 },
  { clrs["weapons_underlay_low1"], 30, 2 } }

-- weapon ammo readout adjustments
ammo_mult = {}
ammo_mult["flamethrower ammo"] = 1 / 9
ammo_mult["shotgun ammo"] = 1 / 12

-- energy timing adjustments
energy_mult = {}
energy_mult["plasma pistol"] = 1.25
energy_mult["plasma rifle"] = 1 / 1.5
energy_mult["flamethrower"] = 1 / 15

-- energy dip animation
anims["energy_dip"] = {
  { { 1.0, 1.0, 1.0, 1.0 }, 0, 0 },
  { { 0.8, 0.8, 0.8, 1.0 }, 0, 2 },
  { { 0.9, 0.9, 0.9, 1.0 }, 0, 5 } }


-- Distance from the corners
margin_amount_x = 60
margin_amount_y = 40
margin_weaponamount_x = 120
margin_netamount_x = 40
margin_netamount_y = 40

-- widest game aspect ratio allowed (2 == 2:1 width:height)
max_aspect_ratio = 2
-- narrowest game aspect ratio allowed
min_aspect_ratio = 1.6

-- largest scale factor for the graphics
max_scale_factor = 3.0
-- smallest scale factor for the graphics
min_scale_factor = 0.3
-- screen width at which the graphics are drawn at 1:1 scale
scale_width = 2880
-- scaling rate
scale_rate = 1.0
-- scale adjust for net stats
scale_netadjust = 1.5
-- scale adjust for crosshairs
scale_crosshair = 0.5

-- weapon switch animation time, in ticks
weapon_switch = 10
-- opacity level for holstered weapons
weapon_undrawn_alpha = 0.5
-- bullet slide/fade animation time, in ticks
bullet_switch = 10

-- low ammo warning level, in clips
lowammo_level = 2

-- radar ping animation time, in ticks
radar_ping = 60

-- top left corner of first digit in readouts
readout_digit_x = 50
readout_digit_y = 12

-- energy bar padding in image (where 0% and 100% are, relative to image edges)
energy_margin_left = 11
energy_margin_right = 11

-- time to fall, in ticks (from 100% to 0%)
--energy_anim_fall = 60

-- shield bar length in pixels, used when masking
shieldbar_width = 335
-- shield mask shift to reach start of shield bar
shieldbar_margin_left = 35
-- shield mask shift to mask off icon area
shieldbar_margin_icon = 27

-- top right of rightmost health bar, relative to full-size health and shield images
healthbar_offx = 310
healthbar_offy = 66

-- tangent of skew angle for graphics (0.4 = tan(22 degrees))
skewtangent = 0.4

-- time in ticks for net standings row to show new player
anim_netscroll = 10
-- time in ticks for net standings rows to switch places
anim_netswap = 10

Triggers = {}
function Triggers.draw()

  if Screen.renderer == "software" then error("Halathon HUD requires OpenGL") end
  
  detect_plasma()
  ShotgunAnim.sync()
  
  -- net stats
  if #Game.players > 1 then
    local net_w = netheader.width
    local net_h = (45*scale*scale_netadjust)
    local net_x = sx + sw - margin_netamount_x*scalemargin - net_w
    local net_y = sy + sh - margin_netamount_y*scalemargin - 3*net_h
    
    local gametype = Game.type
    if gametype == "netscript" then
      gametype = Game.scoring_mode
    end
    netrow_header(net_x, net_y, net_w, net_h, gametype)
    
    local one, two = top_two()
--local one = Game.players[0]
--local two = Game.players[0]
    local ly = net_h
    local ny = 2*net_h
    local lplayer = one
    local nplayer = two
    if not one.local_ then
      ly = 2*net_h
      ny = net_h
      lplayer = two
      nplayer = one
    end
    
    netrow_nonlocal(net_x, net_y + ny, net_w, net_h, gametype, nplayer)
    netrow_local(net_x, net_y + ly, net_w, net_h, gametype, lplayer)
  end

  if Player.dead then return end
      
  local r_w = imgs["radar_underlay"].width
  local r_rad = (r_w / 2)
  local r_x = sx + (margin_amount_x*scale)
  local r_y = sy + sh - r_w - (margin_amount_y*scale)
  
  -- motion sensor
  if Player.motion_sensor.active then
    imgs["radar_underlay"]:draw(r_x, r_y)
    
    -- FOV indicator
    if Screen.field_of_view.horizontal > 0 then
      local fov = Screen.field_of_view.horizontal/2
      local fovm = imgs["radar_fov_mask"]
      Screen.clear_mask()
      Screen.masking_mode = MaskingModes["drawing"]
      fovm.rotation = 0 - fov
      fovm:draw(r_x, r_y)
      Screen.masking_mode = MaskingModes["erasing"]
      fovm.rotation = fov
      fovm:draw(r_x, r_y)
      Screen.masking_mode = MaskingModes["enabled"]
      imgs["radar_fov"]:draw(r_x, r_y)
      Screen.masking_mode = MaskingModes["disabled"]
    end
    
    -- ping animation
    local pingcycle = Game.ticks % radar_ping
    if pingcycle < (radar_ping / 2) then  
      local alpha = 1 - math.max(0, (pingcycle - (radar_ping / 4))/(radar_ping / 4))
      local ping = imgs["radar_ping"]
      ping.tint_color = { 1, 1, 1, alpha }
      
      local nrad = ((pingcycle + 1) * r_rad / (radar_ping / 2))
      local off = r_rad - nrad
      ping:rescale(nrad * 2, nrad * 2)
      ping:draw(r_x + off, r_y + off)
    end
    
    -- compass
    if Player.compass.nw or Player.compass.ne or Player.compass.sw or Player.compass.se then
    
      -- draw each active quadrant into mask
      Screen.clear_mask()
      Screen.masking_mode = MaskingModes["drawing"]
      if Player.compass.nw then
        Screen.fill_rect(r_x, r_y, r_rad, r_rad, { 1, 1, 1, 1 })
      end
      if Player.compass.ne then
        Screen.fill_rect(r_x + r_rad, r_y, r_rad, r_rad, { 1, 1, 1, 1 })
      end
      if Player.compass.sw then
        Screen.fill_rect(r_x, r_y + r_rad, r_rad, r_rad, { 1, 1, 1, 1 })
      end
      if Player.compass.se then
        Screen.fill_rect(r_x + r_rad, r_y + r_rad, r_rad, r_rad, { 1, 1, 1, 1 })
      end

      Screen.masking_mode = MaskingModes["enabled"]
      imgs["radar_compass"]:draw(r_x, r_y)
      Screen.masking_mode = MaskingModes["disabled"]
    end
    
    -- blips
    local r_mult = (r_rad - imgs["radar_alien"].width) / 8
    for i = 1,#Player.motion_sensor.blips do
      local blip = Player.motion_sensor.blips[i - 1]
      local mult = blip.distance * r_mult
      local rad = math.rad(blip.direction)
      local xoff = r_x + r_rad + math.cos(rad) * mult
      local yoff = r_y + r_rad + math.sin(rad) * mult
      
      local alpha = 1 / (blip.intensity + 1)
      local img = imgs["radar_" .. blip.type.mnemonic]
      local img1 = imgs["radar_" .. blip.type.mnemonic .. "_overlay"]
      
      img.tint_color = { 1, 1, 1, alpha }
      img:draw(xoff - (img.width/2), yoff - (img.height/2))
      
      if blip.intensity == 0 then
        local pinghalf = pingcycle / 2
        local pingoff = pingcycle - (blip.distance * pinghalf / 8)
        if pingoff < 0 then pingoff = pinghalf end
        alpha = math.max(0, pinghalf - pingoff)/pinghalf
        img1.tint_color = { 1, 1, 1, alpha }
        img1:draw(xoff - (img1.width/2), yoff - (img1.height/2))
      end
    end
  end

  -- health/shields area
  local h_x = sx + sw - (margin_amount_x*scale) - imgs["shields_underlay"].width
  local h_y = sy + (margin_amount_y*scale)
  
  -- health
  local amt = Player.oxygen
  local clr_health = clrs["health_high"]
  if amt <= lowhealth_level then
    clr_health = clrs["health_low"]
  elseif amt <= medhealth_level then
    clr_health = clrs["health_med"]
  end
  
  imgs["health_cross"].tint_color = clr_health
  imgs["health_cross"]:draw(h_x, h_y)
  
  draw_health(amt, clr_health, h_x + (healthbar_offx*scale), h_y + (healthbar_offy*scale))
  
  -- shields
  local clr_shield_over = clrs["shields_overlay"]
  local clr_shield_under = clrs["shields_underlay"]
  if Player.life < lowshields_level then
    local frac = ((Game.ticks % lowshields_flash) / lowshields_flash) * 2
    if frac > 1.0 then
      frac = 2.0 - frac
    end
    local easefrac = ease_inout(frac)
    easefrac = frac
    
    clr_shield_over = blend_color(clrs["shields_overlay_low1"], clrs["shields_overlay_low2"], easefrac)
    clr_shield_under = blend_color(clrs["shields_underlay_low1"], clrs["shields_underlay_low2"], easefrac)
  end

  imgs["shields_underlay"].tint_color = clr_shield_under
  imgs["shields_underlay"]:draw(h_x, h_y)
  
  amt = Player.life
  if amt >= 0 then
    local moreclr = clrs["shields_single"]
    local lessclr = nil
    if amt > 300 then
      amt = amt - 300
      moreclr = clrs["shields_triple"]
      lessclr = clrs["shields_double"]
    elseif amt > 150 then
      amt = amt - 150
      moreclr = clrs["shields_double"]
      lessclr = clrs["shields_single"]
    end
    
    if imgs["shields_bar"].width == imgs["shields_overlay"].width then
    imgs["shields_bar"].tint_color = moreclr
    draw_shields(imgs["shields_bar"], amt, 0, true, h_x, h_y)
    if lessclr then
      imgs["shields_bar"].tint_color = lessclr
      draw_shields(imgs["shields_bar"], 150, amt, false, h_x, h_y)
    end
    end
  end
  
  -- damage effect
  amt = Player.life
  if amt >= damage_start then
    -- recovered from any damage, reset
    damage_start = amt
    damage_timer = 0
  elseif damage_timer == 0 then
    -- took damage outside of timer, reset timer
    damage_timer = Game.ticks + shields_damage_flash
  end
  
  if Game.ticks < damage_timer then
    -- in timer, draw any damage
    local max = damage_start
    while max > 150 do
      max = max - 150
      amt = amt - 150
    end
    
    draw_damage(max, amt, h_x, h_y)
    if amt < 0 then
      draw_damage(150, amt + 150, h_x, h_y)
    end
  elseif damage_timer > 0 then
    -- leaving timer, reset
    damage_timer = 0
    damage_start = Player.life
  end
     
  -- shields overlay
  imgs["shields_overlay"].tint_color = clr_shield_over
  imgs["shields_overlay"]:draw(h_x, h_y)

  -- uplink chip
  if Player.items["uplink chip"].count > 0 then
    local image = imgs["uplink chip"]
    if image then
      local c_x = sx + (margin_weaponamount_x*scale) + dwidth(imgs["readout_left_underlay"]) + dwidth(imgs["readout_right_underlay"])
      local c_y = h_y
      local ct = Player.items["uplink chip"].count
      
      for i = 1,ct do
        image:draw(c_x, c_y)
        c_x = c_x + dwidth(image)
      end
    end
  end
    
  -- weapon
  local w_x = sx + (margin_weaponamount_x*scale)
  local w_y = h_y
  
  local weapon = Player.weapons.desired
  if weapon then
    local wp = weapon.primary
    local ws = weapon.secondary
    local primary_ammo = nil
    local primary_clips = 0
    local secondary_ammo = nil
    reset_energy_animation(weapon)
--    reset_shotgun_animation(weapon)
    
    if wp then
      primary_ammo = wp.ammo_type
      if primary_ammo then
        primary_clips = Player.items[primary_ammo].count
      else
        primary_ammo = ItemTypes[weapon.type.mnemonic .. " ammo"]
      end
    end
    if primary_ammo then
      draw_ammo(primary_ammo, primary_clips, wp.total_rounds, wp.rounds, "left", w_x, w_y)
    else
      draw_ammo_empty("left", w_x, w_y)
    end

    local wr_x = w_x + dwidth(imgs["readout_left_underlay"])
    
    local dual_wield = false
    local right_drawn = false
--    if ws and ws.ammo_type then
--      secondary_ammo = ws.ammo_type
--      if secondary_ammo == primary_ammo then
--        if Player.items[weapon.type.mnemonic].count < 2 then
--          secondary_ammo = nil
--          ws = nil
--        else
--          dual_wield = true
--        end
--      else
--        draw_ammo(secondary_ammo, ws.total_rounds, ws.rounds, "right", wr_x, w_y)
--        right_drawn = true
--      end
--    end
    if not right_drawn then
        draw_weapon(weapon, "right", wr_x, w_y)
    end
    
    w_y = w_y + imgs["readout_left_underlay"].height
    
    if is_energy(weapon.type) then
      draw_energy(wp, wp.rounds, wp.total_rounds, w_x - damt(imgs["energy_underlay"]), w_y)
    else
--      if secondary_ammo then
--        local total = ws.total_rounds
--        if weapon.type == "shotgun" then
--          total = 1
--        end
--        draw_bullets(weapon, secondary_ammo, ws.rounds, total, 1, true, dual_wield, w_x, wr_x + dwidth(imgs["readout_right_underlay"]), w_y)
--      end
      if primary_ammo then
        local rows = 1
        if weapon.type == "assault rifle" then
          rows = 3
        end
        local total = wp.total_rounds
--        if weapon.type == "shotgun" then
--          total = 1
--        end
        draw_bullets(weapon, primary_ammo, wp.rounds, total, rows, false, dual_wield, w_x, wr_x + dwidth(imgs["readout_right_underlay"]), w_y)
      end
    end
  
    -- crosshairs
    draw_crosshair(weapon)
  else
    reset_energy_animation()
  end
end

function Triggers.resize()

  Screen.clip_rect.width = Screen.width
  Screen.clip_rect.x = 0
  Screen.clip_rect.height = Screen.height
  Screen.clip_rect.y = 0

  Screen.map_rect.width = Screen.width
  Screen.map_rect.x = 0
  Screen.map_rect.height = Screen.height
  Screen.map_rect.y = 0
  
  local h = math.min(Screen.height, Screen.width / min_aspect_ratio)
  local w = math.min(Screen.width, h*max_aspect_ratio)
  Screen.world_rect.width = w
  Screen.world_rect.x = (Screen.width - w)/2
  Screen.world_rect.height = h
  Screen.world_rect.y = (Screen.height - h)/2
  
  if Screen.map_overlay_active then
    Screen.map_rect.x = Screen.world_rect.x
    Screen.map_rect.y = Screen.world_rect.y
    Screen.map_rect.width = Screen.world_rect.width
    Screen.map_rect.height = Screen.world_rect.height
  end
    
  sx = Screen.world_rect.x
  sy = Screen.world_rect.y
  sw = Screen.world_rect.width
  sh = Screen.world_rect.height

  scalemargin = 1 + (sw - scale_width)*scale_rate/scale_width
  scale = math.min(max_scale_factor, math.max(min_scale_factor, scalemargin))

  for k in pairs(imgs) do
    rescale(imgs[k])
  end
  for k in pairs(crosshairs) do
    rescale_crosshair(crosshairs[k])
  end
  
  local rscale = scale
  scale = scale*scale_netadjust
  rescale(netheader)
  for k in pairs(netplayers) do
    rescale(netplayers[k])
  end
  for k in pairs(netteams) do
    rescale(netteams[k])
  end
  scale = rscale
  
  netf = Fonts.new{file = "squarishsans/Squarish Sans CT Regular SC.ttf", size = (18*scale*scale_netadjust), style = 0}

  local th = math.max(320, sh * 0.75)
  local tw = math.max(640, sw * 0.75)
  h = math.min(tw / 2, th)
  w = h*2
  Screen.term_rect.width = w
  Screen.term_rect.x = sx + (sw - w)/2
  Screen.term_rect.height = h
  Screen.term_rect.y = sy + (sh - h)/2
end


function Triggers.init()

  -- align weapon and item mnemonics
  ItemTypes["knife"].mnemonic = "fist"
  
  -- plasma mnemonics adjusted in Triggers.draw()
  
  ItemTypes["alien weapon"].mnemonic = "fuel rod gun"
  WeaponTypes["alien weapon"].mnemonic = "fuel rod gun"
  ItemTypes["alien weapon ammo"].mnemonic = "fuel rod gun ammo"
  
  ItemTypes["smg"].mnemonic = "needler"
  WeaponTypes["smg"].mnemonic = "needler"
  ItemTypes["smg ammo"].mnemonic = "needler ammo"
  
  if Screen.crosshairs then Screen.crosshairs.lua_hud = true end
  damage_start = 0
  damage_timer = 0
  
  imgs = {}
  imgs["shields_angle_mask"] = Images.new{path = "resources/shields/shields_angle_mask.png"}
  imgs["shields_bar_mask"] = Images.new{path = "resources/shields/shields_bar_mask.png"}
  
  imgs["shields_damage"] = Images.new{path = "resources/shields/shields_damage.png"}
  imgs["shields_bar"] = Images.new{path = "resources/shields/shields_bar.png"}

  imgs["shields_underlay"] = Images.new{path = "resources/shields/shields_underlay.png"}
  imgs["shields_overlay"] = Images.new{path = "resources/shields/shields_overlay.png"}


  imgs["health_cross"] = Images.new{path = "resources/health/health_cross.png"}
  imgs["health_bar"] = Images.new{path = "resources/health/health_bar.png"}
  
  imgs["radar_underlay"] = Images.new{path = "resources/radar/background.png"}
  imgs["radar_compass"] = Images.new{path = "resources/radar/compass.png"}
  imgs["radar_ping"] = Images.new{path = "resources/radar/ping.png"}
  
  imgs["radar_fov"] = Images.new{path = "resources/radar/range.png"}
  imgs["radar_fov_mask"] = Images.new{path = "resources/radar/range_mask.png"}
  
  imgs["radar_alien"] = Images.new{path = "resources/radar/dot_enemy.png"}
  imgs["radar_alien_overlay"] = Images.new{path = "resources/radar/dot_enemy_overlay.png"}
  imgs["radar_friend"] = Images.new{path = "resources/radar/dot_friendly.png"}
  imgs["radar_friend_overlay"] = Images.new{path = "resources/radar/dot_friendly_overlay.png"}
  imgs["radar_hostile player"] = Images.new{path = "resources/radar/dot_friendly.png"}
  imgs["radar_hostile player_overlay"] = Images.new{path = "resources/radar/dot_friendly_overlay.png"}
  
  imgs["uplink chip"] = Images.new{path = "resources/weapons/data_disk.png"}
  imgs["uplink chip"].tint_color = clrs["uplink_chip"]
  
  imgs["digit_0"] = Images.new{path = "resources/weapons/numbers/0.png"}
  imgs["digit_0"].tint_color = clrs["weapons_data"]
  imgs["digit_1"] = Images.new{path = "resources/weapons/numbers/1.png"}
  imgs["digit_1"].tint_color = clrs["weapons_data"]
  imgs["digit_2"] = Images.new{path = "resources/weapons/numbers/2.png"}
  imgs["digit_2"].tint_color = clrs["weapons_data"]
  imgs["digit_3"] = Images.new{path = "resources/weapons/numbers/3.png"}
  imgs["digit_3"].tint_color = clrs["weapons_data"]
  imgs["digit_4"] = Images.new{path = "resources/weapons/numbers/4.png"}
  imgs["digit_4"].tint_color = clrs["weapons_data"]
  imgs["digit_5"] = Images.new{path = "resources/weapons/numbers/5.png"}
  imgs["digit_5"].tint_color = clrs["weapons_data"]
  imgs["digit_6"] = Images.new{path = "resources/weapons/numbers/6.png"}
  imgs["digit_6"].tint_color = clrs["weapons_data"]
  imgs["digit_7"] = Images.new{path = "resources/weapons/numbers/7.png"}
  imgs["digit_7"].tint_color = clrs["weapons_data"]
  imgs["digit_8"] = Images.new{path = "resources/weapons/numbers/8.png"}
  imgs["digit_8"].tint_color = clrs["weapons_data"]
  imgs["digit_9"] = Images.new{path = "resources/weapons/numbers/9.png"}
  imgs["digit_9"].tint_color = clrs["weapons_data"]
  
  imgs["readout_left_underlay"] = Images.new{path = "resources/weapons/weapon_left_underlay.png"}
  imgs["readout_right_underlay"] = Images.new{path = "resources/weapons/weapon_right_underlay.png"}
  imgs["readout_left_overlay"] = Images.new{path = "resources/weapons/weapon_left_overlay.png"}
  imgs["readout_right_overlay"] = Images.new{path = "resources/weapons/weapon_right_overlay.png"}

  imgs["energy_underlay"] = Images.new{path = "resources/weapons/energy/underlay.png"}
  imgs["energy_underlay"].tint_color = clrs["energy_underlay"]
  imgs["energy_bar"] = Images.new{path = "resources/weapons/energy/energy_bar.png"}
  imgs["energy_overlay"] = Images.new{path = "resources/weapons/energy/overlay.png"}
  imgs["energy_overlay"].tint_color = clrs["energy_overlay"]

  imgs["pistol ammo"] = Images.new{path = "resources/weapons/bullets/rounds.png"}
  imgs["pistol ammo"].tint_color = clrs["weapons_data"]
  imgs["plasma rifle ammo"] = Images.new{path = "resources/weapons/energy/battery.png"}
  imgs["plasma rifle ammo"].tint_color = clrs["weapons_data"]
  imgs["assault rifle ammo"] = Images.new{path = "resources/weapons/bullets/rounds.png"}
  imgs["assault rifle ammo"].tint_color = clrs["weapons_data"]
  imgs["missile launcher ammo"] = Images.new{path = "resources/weapons/bullets/rounds.png"}
  imgs["missile launcher ammo"].tint_color = clrs["weapons_data"]
  imgs["shotgun ammo"] = Images.new{path = "resources/weapons/bullets/rounds.png"}
  imgs["shotgun ammo"].tint_color = clrs["weapons_data"]
  imgs["needler ammo"] = Images.new{path = "resources/weapons/bullets/rounds.png"}
  imgs["needler ammo"].tint_color = clrs["weapons_data"]
  imgs["flamethrower ammo"] = Images.new{path = "resources/weapons/energy/battery.png"}
  imgs["flamethrower ammo"].tint_color = clrs["weapons_data"]
  imgs["fuel rod gun ammo"] = Images.new{path = "resources/weapons/bullets/rounds.png"}
  imgs["fuel rod gun ammo"].tint_color = clrs["weapons_data"]
  
  imgs["fist"] = Images.new{path = "resources/weapons/diagrams/melee_diagram.png"}
  imgs["fist"].tint_color = clrs["weapons_data"]
  imgs["pistol"] = Images.new{path = "resources/weapons/diagrams/pistol_diagram.png"}
  imgs["pistol"].tint_color = clrs["weapons_data"]
  imgs["plasma pistol"] = Images.new{path = "resources/weapons/diagrams/plasmapistol_diagram.png"}
  imgs["plasma pistol"].tint_color = clrs["weapons_data"]
  imgs["plasma rifle"] = Images.new{path = "resources/weapons/diagrams/plasmarifle_diagram.png"}
  imgs["plasma rifle"].tint_color = clrs["weapons_data"]
  imgs["assault rifle"] = Images.new{path = "resources/weapons/diagrams/ar_diagram.png"}
  imgs["assault rifle"].tint_color = clrs["weapons_data"]
  imgs["missile launcher"] = Images.new{path = "resources/weapons/diagrams/rocketlauncher_diagram.png"}
  imgs["missile launcher"].tint_color = clrs["weapons_data"]
  imgs["flamethrower"] = Images.new{path = "resources/weapons/diagrams/flamethrower_diagram.png"}
  imgs["shotgun"] = Images.new{path = "resources/weapons/diagrams/shotgun_diagram.png"}
  imgs["shotgun"].tint_color = clrs["weapons_data"]
  imgs["needler"] = Images.new{path = "resources/weapons/diagrams/needler_diagram.png"}
  imgs["needler"].tint_color = clrs["weapons_data"]
  imgs["fuel rod gun"] = Images.new{path = "resources/weapons/diagrams/fuelrodgun_diagram.png"}
  imgs["fuel rod gun"].tint_color = clrs["weapons_data"]
  
  imgs["round_pistol ammo"] = Images.new{path = "resources/weapons/bullets/pistol_rounds.png"}
  imgs["empty_pistol ammo"] = Images.new{path = "resources/weapons/bullets/pistol_rounds.png"}
  imgs["round_missile launcher ammo"] = Images.new{path = "resources/weapons/bullets/rocket_rounds.png"}
  imgs["empty_missile launcher ammo"] = Images.new{path = "resources/weapons/bullets/rocket_rounds.png"}
  imgs["round_shotgun ammo"] = Images.new{path = "resources/weapons/bullets/shotgun_rounds.png"}
  imgs["empty_shotgun ammo"] = Images.new{path = "resources/weapons/bullets/shotgun_rounds.png"}
  imgs["round_needler ammo"] = Images.new{path = "resources/weapons/bullets/needler_rounds.png"}
  imgs["empty_needler ammo"] = Images.new{path = "resources/weapons/bullets/needler_rounds.png"}
  imgs["round_fuel rod gun ammo"] = Images.new{path = "resources/weapons/bullets/frg_rounds.png"}
  imgs["empty_fuel rod gun ammo"] = Images.new{path = "resources/weapons/bullets/frg_rounds.png"}
  imgs["round_assault rifle ammo"] = Images.new{path = "resources/weapons/bullets/ar_rounds.png"}
  imgs["empty_assault rifle ammo"] = Images.new{path = "resources/weapons/bullets/ar_rounds.png"}
        
  crosshairs = {}
  crosshairs["pistol"] = Images.new{path = "resources/crosshairs/pistol.png"}
  crosshairs["plasma pistol"] = Images.new{path = "resources/crosshairs/plasmapistol.png"}
  crosshairs["plasma rifle"] = Images.new{path = "resources/crosshairs/plasmarifle.png"}
  crosshairs["assault rifle"] = Images.new{path = "resources/crosshairs/assaultrifle.png"}
  crosshairs["missile launcher"] = Images.new{path = "resources/crosshairs/rocketlauncher.png"}
  crosshairs["flamethrower"] = Images.new{path = "resources/crosshairs/shotgun_flamethrower.png"}
  crosshairs["shotgun"] = Images.new{path = "resources/crosshairs/shotgun_flamethrower.png"}
  crosshairs["needler"] = Images.new{path = "resources/crosshairs/needler.png"}
  crosshairs["fuel rod gun"] = Images.new{path = "resources/crosshairs/fuelrodgun.png"}
  
  netheader = Images.new{path = "resources/HUD_Netstats/backdrop_black.png"}
  
  netplayers = { }
  netplayers["blue"] = Images.new{path = "resources/HUD_Netstats/backdrop_blue.png"}
  netplayers["green"] = Images.new{path = "resources/HUD_Netstats/backdrop_green.png"}
  netplayers["orange"] = Images.new{path = "resources/HUD_Netstats/backdrop_orange.png"}
  netplayers["red"] = Images.new{path = "resources/HUD_Netstats/backdrop_red.png"}
  netplayers["slate"] = Images.new{path = "resources/HUD_Netstats/backdrop_slate.png"}
  netplayers["violet"] = Images.new{path = "resources/HUD_Netstats/backdrop_violet.png"}
  netplayers["white"] = Images.new{path = "resources/HUD_Netstats/backdrop_white.png"}
  netplayers["yellow"] = Images.new{path = "resources/HUD_Netstats/backdrop_yellow.png"}
    
  netteams = { }
  netteams["blue"] = Images.new{path = "resources/HUD_Netstats/team_blue.png"}
  netteams["green"] = Images.new{path = "resources/HUD_Netstats/team_green.png"}
  netteams["orange"] = Images.new{path = "resources/HUD_Netstats/team_orange.png"}
  netteams["red"] = Images.new{path = "resources/HUD_Netstats/team_red.png"}
  netteams["slate"] = Images.new{path = "resources/HUD_Netstats/team_slate.png"}
  netteams["violet"] = Images.new{path = "resources/HUD_Netstats/team_violet.png"}
  netteams["white"] = Images.new{path = "resources/HUD_Netstats/team_white.png"}
  netteams["yellow"] = Images.new{path = "resources/HUD_Netstats/team_yellow.png"}

  canims = {}
  for k,v in pairs(anims) do
    canims[k] = compile_anim(v)
  end
  
  Triggers.resize()
end

function detect_plasma()
  
  if Player.items[3].singular == "PLASMA PISTOL" then
    ItemTypes[3].mnemonic = "plasma pistol"
    WeaponTypes[2].mnemonic = "plasma pistol"
    ItemTypes[4].mnemonic = "plasma pistol ammo"
  else
    ItemTypes[3].mnemonic = "plasma rifle"
    WeaponTypes[2].mnemonic = "plasma rifle"
    ItemTypes[4].mnemonic = "plasma rifle ammo"
  end
end

function rescale(img)
  if not img then return end
  local w = math.max(1, (img.unscaled_width * scale))
  local h = math.max(1, (img.unscaled_height * scale))
  img:rescale(w, h)
end
function rescale_crosshair(img)
  if not img then return end
  local w = math.max(1, (img.unscaled_width * scale * scale_crosshair))
  local h = math.max(1, (img.unscaled_height * scale * scale_crosshair))
  img:rescale(w, h)
end

function ease(frac)
  return math.sqrt(1 - math.pow(frac - 1.0, 2))
end

function ease_inout(frac)
  if frac < 0.5 then
    frac = ease(frac * 2) / 2
  elseif frac > 0.5 then
    frac = 1.0 - (ease(2.0 - (frac * 2)) / 2)
  end
  return frac
end

function blend_color(clr1, clr2, frac)
  local inv = 1.0 - frac
  r = (clr1[1] * inv) + (clr2[1] * frac)
  g = (clr1[2] * inv) + (clr2[2] * frac)
  b = (clr1[3] * inv) + (clr2[3] * frac)
  a = (clr1[4] * inv) + (clr2[4] * frac)
  return { r, g, b, a }
end

function mask_shields(max, min, icon, strict, x, y)
  
  local pointsize = shieldbar_width * scale / 150
  local iconshift = shieldbar_margin_icon * scale
  local pointshift = shieldbar_margin_left * scale
  Screen.clear_mask()
  local mask = imgs["shields_angle_mask"]
  
  if icon then
    -- add area for icon
    Screen.masking_mode = MaskingModes["drawing"]
    Screen.fill_rect(x, y, mask.width, mask.height, { 1, 1, 1, 1 })
    
    -- subtract bars above max
    if max < 150 then
      Screen.masking_mode = MaskingModes["erasing"]
      mask:draw(x + iconshift, y)
    end
  end
  
  -- add mask up to max
  local shift = (150 - max) * pointsize
  Screen.masking_mode = MaskingModes["drawing"]
  mask:draw(x + pointshift + shift, y)
  
  
  -- delete mask below min
  shift = (150 - min) * pointsize
  Screen.masking_mode = MaskingModes["erasing"]
  mask:draw(x + pointshift + shift, y)
  
  -- remove anything outside of bar
  if strict then
    imgs["shields_bar_mask"]:draw(x, y)
  end

  Screen.masking_mode = MaskingModes["enabled"]
end

function draw_shields(img, max, min, icon, x, y)
  if not img then return end
  if max <= min then return end
  mask_shields(max, min, icon, false, x, y)
  
  img:draw(x, y)
  
  Screen.masking_mode = MaskingModes["disabled"]
end

function draw_damage(max, min, x, y)
  if max <= min then return end
  
  mask_shields(max, 0, false, true, x, y)
  
  -- draw damage overlay 
  local pointsize = shieldbar_width * scale / 150
  local pointshift = shieldbar_margin_left * scale
  local shift = math.max(0, min) * pointsize
  imgs["shields_damage"]:draw(x + pointshift - shift, y)
  
  Screen.masking_mode = MaskingModes["disabled"]
end

function damt(img)
  if not img then return 0 end
  return (img.height * skewtangent)
end

function dwidth(img)
  if not img then return 0 end
  return (img.width - (img.height * skewtangent))
end

function is_energy(item)
  local which = string.gsub(item.mnemonic, " ammo", "")
  if ((which == "plasma pistol") or
      (which == "plasma rifle") or
      (which == "flamethrower")) then
    return true
  end
  return false
end

function draw_number(num, x, y)
  if num > 999 then num = 999 end
  num = math.floor(num)
  local hundreds = math.floor(num / 100) % 10
  local tens = math.floor(num / 10) % 10
  local ones = num % 10
  
  local dw = dwidth(imgs["digit_0"])
  imgs["digit_" .. hundreds]:draw(x, y)
  imgs["digit_" .. tens]:draw(x + dw, y)
  imgs["digit_" .. ones]:draw(x + dw + dw, y)
end

function draw_energy(weapon, amt, total, x, y)
  imgs["energy_underlay"]:draw(x, y)
  
  local left_off = energy_margin_left*scale
  local right_off = energy_margin_right*scale
  
  local i = imgs["energy_bar"]
  local iw = i.width - left_off - right_off
  i.crop_rect.width = left_off + (EnergyAnim.get_phase() * iw)
  i:draw(x, y)
  
  imgs["energy_overlay"]:draw(x, y)
end

function draw_weapon(weapon, side, x, y)
  if ((not weapon) or (not weapon.type)) then
    return
  end
  
  local img = imgs[weapon.type.mnemonic]
  
  local backimg = imgs["readout_" .. side .. "_underlay"]
  backimg.tint_color = clrs["weapons_underlay"]
--  if img then
    backimg:draw(x, y)
--  end
  
  if not img then
    last_weapon = nil
  else
  
    local off = backimg.width - img.width
    
    if (not last_weapon) or (not (last_weapon.which == weapon.type.mnemonic)) then
      last_weapon = {}
      last_weapon.which = weapon.type.mnemonic
      last_weapon.count = Player.items[weapon.type.mnemonic].count
      last_weapon.anim = Animation:new()
      if last_weapon.count > 1 then
        last_weapon.anim:set(off)
      else
        last_weapon.anim:set(0)
      end
    elseif last_weapon.count < Player.items[weapon.type.mnemonic].count then
      last_weapon.count = Player.items[weapon.type.mnemonic].count
      last_weapon.anim:target(0, off, weapon_switch)
    else
      last_weapon.anim:update()
    end

  
--    off = last_weapon.anim:current()
--    if off > 0 then
--      if not weapon.secondary.weapon_drawn then
--        img.tint_color = {1,1,1,weapon_undrawn_alpha}
--      else
--        img.tint_color = {1,1,1,1}
--      end
--      img:draw(x - off, y)
--      if weapon.secondary.weapon_drawn and (not weapon.primary.weapon_drawn) then
--        img.tint_color = {1,1,1,weapon_undrawn_alpha}
--      else
--        img.tint_color = {1,1,1,1}
--      end
--      img:draw(x + off, y)
--    else
--      img.tint_color = {1,1,1,1}
      img:draw(x, y) 
--    end  
  
  end
  
--  if img then
    local frontimg = imgs["readout_" .. side .. "_overlay"]
    frontimg.tint_color = clrs["weapons_overlay"]
    frontimg:draw(x, y)
--  end
end

function draw_ammo_empty(side, x, y)
  local backimg = imgs["readout_" .. side .. "_underlay"]
  backimg.tint_color = clrs["weapons_underlay"]
  backimg:draw(x, y)

  local frontimg = imgs["readout_" .. side .. "_overlay"]
  frontimg.tint_color = clrs["weapons_overlay"]
  frontimg:draw(x, y)
end

function draw_ammo(ammo_type, clip_count, clip_size, loaded, side, x, y)
  local img = imgs[ammo_type.mnemonic]
  if not img then
    return
  end

  clip_count = ShotgunAnim.adjust_clip(ammo_type, clip_count)
  local ct = clip_count * clip_size
--  if is_energy(ammo_type) then
--    ct = ct + loaded
--  end
  local lowammo = false
  if ct < (lowammo_level * clip_size) then
    lowammo = true
  end
  if ammo_mult[ammo_type.mnemonic] then
    ct = math.ceil(ct * ammo_mult[ammo_type.mnemonic])
  end
  local backclr = clrs["weapons_underlay"]
  local frontclr = clrs["weapons_overlay"]
  if ct <= 0 then
    backclr = clrs["weapons_underlay_low2"]
    frontclr = clrs["weapons_overlay"]
  elseif lowammo then
    backclr = animated_color("lowammo_flash")
    frontclr = clrs["weapons_overlay"]
  end
  
  local backimg = imgs["readout_" .. side .. "_underlay"]
  backimg.tint_color = backclr
  backimg:draw(x, y)

  img:draw(x, y)
  draw_number(ct, x + readout_digit_x*scale, y + readout_digit_y*scale)
  
  local frontimg = imgs["readout_" .. side .. "_overlay"]
  frontimg.tint_color = frontclr
  frontimg:draw(x, y)
end

function draw_bullets(weapon, ammo_type, rounds, total_rounds, rows, right_align, dual_wield, left_x, right_x, top_y)
  if not ammo_type then
    return
  end
  rounds, total_rounds = ShotgunAnim.adjust_bullets(weapon, rounds, total_rounds)

  local img = imgs["round_" .. ammo_type.mnemonic]
  local img2 = imgs["empty_" .. ammo_type.mnemonic]
  if (not img) or (not img2) then
    return
  end
  
  if ammo_mult[ammo_type.mnemonic] then
    rounds = math.ceil(rounds * ammo_mult[ammo_type.mnemonic])
    total_rounds = math.ceil(total_rounds * ammo_mult[ammo_type.mnemonic])
  end
    
  local is_secondary = right_align
  if dual_wield then
    if is_secondary then
      right_align = false
    elseif (not right_align) and weapon.secondary.weapon_drawn then
      right_align = true
    end
  end

  local items_per_row = total_rounds / rows
  local w = dwidth(img)
  local h = img.height
  local off = damt(img)
  local lpos = left_x - off
  local rpos = right_x - (items_per_row*w) - off
  local llpos = lpos - (rpos - lpos)
  local x = lpos
  if right_align then
    x = rpos
  end
  local y = top_y
  local opacity = 1
  
  -- animation stuff for dual-wield
  -- last_weapon created above in draw_weapon
  -- yes, this code is ugly
  if dual_wield then
    if is_secondary then
      if not last_weapon.s_drawn_opac then
        last_weapon.s_drawn_opac = Animation:new()
        last_weapon.s_drawn_posy = Animation:new()
        last_weapon.s_drawn_posx = Animation:new()
        if weapon.secondary.weapon_drawn then
          last_weapon.s_drawn_opac:set(1)
          last_weapon.s_drawn_posy:set(top_y)
          last_weapon.s_drawn_posx:set(lpos)
        else
          last_weapon.s_drawn_opac:set(0)
          last_weapon.s_drawn_posy:set(top_y + img.height)
          last_weapon.s_drawn_posx:set(llpos)
        end
      else
        if weapon.secondary.weapon_drawn then
          last_weapon.s_drawn_opac:target(0, 1, bullet_switch)
          last_weapon.s_drawn_posy:target(top_y + img.height, top_y, bullet_switch)
          last_weapon.s_drawn_posx:target(llpos, lpos, bullet_switch)
        else
          last_weapon.s_drawn_opac:target(1, 0, bullet_switch)
          last_weapon.s_drawn_posy:target(top_y, top_y + img.height, bullet_switch)
          last_weapon.s_drawn_posx:target(lpos, llpos, bullet_switch)
        end
      end
      
--      x = last_weapon.s_drawn_posx:current()
--      y = last_weapon.s_drawn_posy:current()
--      opacity = last_weapon.s_drawn_opac:current()
    end
    
    if not is_secondary then
      if not last_weapon.p_drawn_opac then
        last_weapon.p_drawn_opac = Animation:new()
        last_weapon.p_drawn_posy = Animation:new()
        if weapon.primary.weapon_drawn or (not weapon.secondary.drawn) then
          last_weapon.p_drawn_opac:set(1)
          last_weapon.p_drawn_posy:set(top_y)
        else
          last_weapon.p_drawn_opac:set(0)
          last_weapon.p_drawn_posy:set(top_y + img.height)
        end
      else
        if weapon.primary.weapon_drawn or (not weapon.secondary.drawn) then
          last_weapon.p_drawn_opac:target(0, 1, bullet_switch)
          last_weapon.p_drawn_posy:target(top_y + img.height, top_y, bullet_switch)
        else
          last_weapon.p_drawn_opac:target(1, 0, bullet_switch)
          last_weapon.p_drawn_posy:target(top_y, top_y + img.height, bullet_switch)
        end
      end
      
      if not last_weapon.p_drawn_posx then
        last_weapon.p_drawn_posx = Animation:new()
        if weapon.secondary.weapon_drawn then
          last_weapon.p_drawn_posx:set(rpos)
        else
          last_weapon.p_drawn_posx:set(lpos)
        end
      else
        if weapon.secondary.weapon_drawn then
          last_weapon.p_drawn_posx:target(lpos, rpos, bullet_switch)
        else
          last_weapon.p_drawn_posx:target(rpos, lpos, bullet_switch)
        end
      end
    
      x = last_weapon.p_drawn_posx:current()
--      y = last_weapon.p_drawn_posy:current()
      opacity = last_weapon.p_drawn_opac:current()
    end
  end
  
  img.tint_color = { clrs["bullet_ready"][1], clrs["bullet_ready"][2], clrs["bullet_ready"][3], clrs["bullet_ready"][4] * opacity }
  img2.tint_color = { clrs["bullet_spent"][1], clrs["bullet_spent"][2], clrs["bullet_spent"][3], clrs["bullet_spent"][4] * opacity }
  local row = 0
  while row < rows do
    local min = items_per_row * row
    local max = min + items_per_row
    local rx = x
    
    while min < max do
      if min < rounds then
        img:draw(rx, y)
      else
        img2:draw(rx, y)
      end
      
      min = min + 1
      rx = rx + w
    end
  
    row = row + 1
    y = y + h
    x = x - off
  end  
end

function draw_crosshair(weapon)
  if Screen.term_active or Screen.map_active then return end
  if Screen.crosshairs and (not Screen.crosshairs.active) then return end
  if (not weapon) or (not weapon.type) then return end

  local img = crosshairs[weapon.type.mnemonic]
  if not img then return end
  
  img:draw(sx + sw/2 - img.width/2, sy + sh/2 - img.width/2)
end

function draw_health(amt, clr, right_x, top_y)

  if amt <= 0 then
    return
  end
  local img = imgs["health_bar"]
  if (not img) then
    return
  end
  
  local items_per_row = 8
  local w = dwidth(img)
  local left_x = right_x - (w * items_per_row)
  
  img.tint_color = clr
  local cur = 1
  local max = items_per_row
  local rx = left_x
    
  local min_bar = items_per_row + 1 - (amt * items_per_row / 10800)
  if min_bar > max then
    min_bar = max
  end
  while cur <= max do
    if cur >= min_bar then
      img:draw(rx, top_y)
    end
    
    cur = cur + 1
    rx = rx + w
  end

end

EnergyAnim = {weapon = nil, weapon_type = nil, rounds = 0, frac = 0, starttick = 0}
function EnergyAnim.reset()
  EnergyAnim.weapon = nil
  EnergyAnim.weapon_type = nil
  EnergyAnim.rounds = 0
  EnergyAnim.frac = 0
  EnergyAnim.starttick = 0
end
function EnergyAnim.set(weapon)
  EnergyAnim.weapon = weapon
  EnergyAnim.weapon_type = weapon.type
  EnergyAnim.rounds = weapon.primary.rounds
  EnergyAnim.frac = weapon.primary.rounds / weapon.primary.total_rounds
  EnergyAnim.starttick = 0
end
function EnergyAnim.reload(weapon)
  EnergyAnim.rounds = weapon.primary.rounds
  EnergyAnim.frac = weapon.primary.rounds / weapon.primary.total_rounds
  EnergyAnim.starttick = 0
end
function EnergyAnim.animate(weapon)
  EnergyAnim.weapon_type = weapon.type
  EnergyAnim.rounds = weapon.primary.rounds
  EnergyAnim.frac = weapon.primary.rounds / weapon.primary.total_rounds
  EnergyAnim.starttick = Game.ticks
end

--  local frac = math.max(weapon.primary.rounds, 1) / weapon.primary.total_rounds
--  local phase = 0.08 + (0.22 * (1.0 - frac))
--  if energy_mult[weapon.type.mnemonic] then
--    phase = phase * energy_mult[weapon.type.mnemonic]
--  end
--  EnergyAnim.phase = EnergyAnim.phase + phase
--  EnergyAnim.lasttick = Game.ticks
----  EnergyAnim.decay = (1.0 - math.pow(frac - 1.0, 2)) / energy_anim_fall
--  EnergyAnim.decay = 1.0 / energy_anim_fall
----  error("Frac: " .. frac .. "  Phase: " .. phase .. "  Cur: " .. EnergyAnim.phase .. "  Decay: " .. EnergyAnim.decay)
--end
function EnergyAnim.get_phase()
  if EnergyAnim.frac > 0 then
    local diff = Game.ticks - EnergyAnim.starttick
    local anim = canims["energy_dip"]
    if diff < #anim then
      return EnergyAnim.frac * anim[diff + 1][1]
    end
  end
  return EnergyAnim.frac
  
--  if EnergyAnim.phase > 0 then
--    local now = Game.ticks
--    EnergyAnim.phase = math.max(0.0, EnergyAnim.phase - (EnergyAnim.decay * (now - EnergyAnim.lasttick)))
--    EnergyAnim.lasttick = now
--  end
--  return math.min(1.0, EnergyAnim.phase)

--  return EnergyAnim.weapon.primary.rounds / EnergyAnim.weapon.primary.total_rounds
end

function reset_energy_animation(weapon)
  if (not weapon) or (not weapon.primary) then
    EnergyAnim.reset()
  elseif not (weapon.type == EnergyAnim.weapon_type) then
    EnergyAnim.set(weapon)
  elseif weapon.primary.rounds > EnergyAnim.rounds then
    EnergyAnim.reload(weapon)
  elseif weapon.primary.rounds < EnergyAnim.rounds then
    EnergyAnim.animate(weapon)
  end
end

ShotgunAnim = {shellct = 12, chambered = 0, last_total = 0}

function ShotgunAnim.totals()
  local reserve = Player.items["shotgun ammo"].count
  local in_gun = 0
  if Player.weapons["shotgun"].primary.rounds > 0 then in_gun = 1 end
  return reserve + in_gun, reserve, in_gun
end

function ShotgunAnim.sync()
  local cur_total, reserve, in_gun = ShotgunAnim.totals()
    
  if ShotgunAnim.last_total > cur_total then  -- we took a shot
    if ShotgunAnim.chambered > 0 then
      ShotgunAnim.chambered = ShotgunAnim.chambered - math.min(ShotgunAnim.chambered, ShotgunAnim.last_total - cur_total)
    end
  end
  
  if (ShotgunAnim.chambered == 0) and (in_gun > 0) then
    ShotgunAnim.chambered = math.min(ShotgunAnim.shellct, cur_total)
  end
  
  ShotgunAnim.last_total = cur_total
end

function ShotgunAnim.adjust_bullets(weapon, rounds, total_rounds)
  if weapon.type.mnemonic == "shotgun" then
    return ShotgunAnim.chambered / ammo_mult["shotgun ammo"], ShotgunAnim.shellct / ammo_mult["shotgun ammo"]
  end
  return rounds, total_rounds
end

function ShotgunAnim.adjust_clip(ammo_type, clip_count)
  if ammo_type.mnemonic == "shotgun ammo" then
    return ShotgunAnim.last_total - ShotgunAnim.chambered
  end
  return clip_count
end

function compile_anim(anim)
  local compiled = {}
  local animsize = #anim
  for i,v in ipairs(anim) do
    local clr = v[1]
    for rep = 0,v[2] do
      table.insert(compiled, clr)
    end
    if v[3] > 0 then
      local nclr = anim[1][1]
      if i < #anim then nclr = anim[i + 1][1] end
      local steps = v[3] + 1
      for blendi = 1,v[3] do
        local efrac = blendi / steps
        local bfrac = 1.0 - efrac
        local ec = { (clr[1] * bfrac) + (nclr[1] * efrac), (clr[2] * bfrac) + (nclr[2] * efrac), (clr[3] * bfrac) + (nclr[3] * efrac), (clr[4] * bfrac) + (nclr[4] * efrac) }
        table.insert(compiled, ec)
      end
    end
  end
  return compiled
end

function animated_color(name)
  local anim = canims[name]
  local frame = 1 + (Game.ticks % #anim)
  return anim[frame]
end

Animation = {start_val = 0, final_val = 0, current_val = 0, start_ticks = 0, final_ticks = 0}
function Animation:new(obj)
  obj = obj or {}
  setmetatable(obj, self)
  self.__index = self
  return obj
end

function Animation:adjust_frac(frac)
  return math.sqrt(1 - math.pow(frac - 1.0, 2))
end

function Animation:update()
  if Game.ticks >= self.final_ticks then
    self.current_val = self.final_val
  else
    local pos = self:adjust_frac((Game.ticks - self.start_ticks) / (self.final_ticks - self.start_ticks))
    self.current_val = (pos * (self.final_val - self.start_val)) + self.start_val
  end
end

function Animation:set(to)
  self.start_val = to
  self.final_val = to
  self.current_val = to
  self.start_ticks = Game.ticks
  self.final_ticks = Game.ticks
  return
end

function Animation:target(from, to, when)
  if when <= 0 then
    self:set(to)
    return
  end
  -- otherwise, calculate from current value
  self:update()
  
  -- don't recalculate if we're on the same animation
  if (from == self.start_val) and (to == self.final_val) then
    return
  end
  
  local frac = math.abs(to - self.current_val) / math.abs(to - from)
  if frac < 1 then
    -- finish sooner, based on requested speed
    when = math.ceil(when * self:adjust_frac(frac))
  end
  
  self.start_val = self.current_val
  self.final_val = to
  self.start_ticks = Game.ticks
  self.final_ticks = Game.ticks + when
end

function Animation:current()
  return self.current_val
end
  
function format_time(ticks)
   local secs = math.ceil(ticks / 30)
   return string.format("%d:%02d", math.floor(secs / 60), secs % 60)
end

function net_gamename(gametype)
  if not gamename then
    gamename = { }
    gamename["kill monsters"] = "EMFH"
    gamename["cooperative play"] = "Co-op"
    gamename["capture the flag"] = "CTF"
    gamename["king of the hill"] = "KOTH"
    gamename["kill the man with the ball"] = "KTMWTB"
    gamename["rugby"] = "Rugby"
    gamename["tag"] = "Tag"
    gamename["defense"] = "Defense"
    
    gamename["most points"] = "Netscript"
    gamename["least points"] = "Netscript"
    gamename["most time"] = "Netscript"
    gamename["least time"] = "Netscript"
  end
  
  return gamename[gametype.mnemonic]
end

function net_gamelimit()
  if Game.time_remaining then
    return format_time(Game.time_remaining)
  end
  if Game.kill_limit then
    local max_kills = 0
    for i = 1,#Game.players do
      max_kills = math.max(max_kills, Game.players[i - 1].kills)
    end
    return string.format("%d", Game.kill_limit - max_kills)
  end
  return nil
end

function ranking_text(gametype, ranking)
  if (gametype == "kill monsters") or
     (gametype == "capture the flag") or
     (gametype == "rugby") or
     (gametype == "most points") then
    return string.format("%d", ranking)
  end
  if (gametype == "least points") then
    return string.format("%d", -ranking)
  end
  if (gametype == "cooperative play") then
    return string.format("%d%%", ranking)
  end
  if (gametype == "most time") or
     (gametype == "least time") or
     (gametype == "king of the hill") or
     (gametype == "kill the man with the ball") or
     (gametype == "defense") or
     (gametype == "tag") then
    return format_time(math.abs(ranking))
  end
  
  -- unknown
  return nil
end

function comp_player(a, b)
  if a.ranking > b.ranking then
    return true
  end
  if a.ranking < b.ranking then
    return false
  end
  if a.name < b.name then
    return true
  end
  return false
end

function sorted_players()
  local tbl = {}
  for i = 1,#Game.players do
    table.insert(tbl, Game.players[i - 1])
  end
  table.sort(tbl, comp_player)
  return tbl
end

function top_two()
  local tbl = sorted_players()
  local one = tbl[1]
  local two = tbl[2]
  local i = 2
  while (not one.local_) and two and (not two.local_) do
    i = i + 1
    two = tbl[i]
  end
  return one, two
end

function netrow_header(x, y, w, h, gametype)
  netheader:draw(x, y + 14*scale*scale_netadjust)
  local lt = net_gamename(gametype)
  local rt = net_gamelimit()
  if lt and rt then
    lt = lt .. ":"
  end
  netrow_text(x, y, w, h, lt, rt)
end

function netrow_player(x, y, w, h, gametype, player)
  if not player then return end
  
  local img = netplayers[player.color.mnemonic]
  img:draw(x, y + 8*scale*scale_netadjust)
  netteams[player.team.mnemonic]:draw(x + img.width, y + 8*scale*scale_netadjust)
  netrow_text(x, y, w, h, player.name, ranking_text(gametype, player.ranking))
end

function netrow_text(x, y, w, h, left_text, right_text)
  if left_text then
    local lw, lh = netf:measure_text(left_text)
    local lx = x + 60*scale*scale_netadjust
    local ly = (y + (h - lh)/2) - 2
    netf:draw_text(left_text, lx, ly, { 1, 1, 1, 1 })
  end
  if right_text then
    local lw, lh = netf:measure_text(right_text)
    local lx = x + (w - lw) - 30*scale*scale_netadjust
    local ly = (y + (h - lh)/2) - 2
    netf:draw_text(right_text, lx, ly, { 1, 1, 1, 1 })
  end
end

function netrow_local(x, target_y, w, h, gametype, player)

  -- determine position of box
  local frac = h
  if anim_netswap > 0 then frac = h/anim_netswap end
  if not netlocaly then
    netlocaly = target_y
  end
  local y = target_y
  if y > (netlocaly + frac) then
    y = netlocaly + frac
  elseif y < (netlocaly - frac) then
    y = netlocaly - frac
  end
  netlocaly = y
  netrow_player(x, y, w, h, gametype, player)
end

function netrow_nonlocal(x, target_y, w, h, gametype, player)

  -- determine position of box
  local frac = h
  if anim_netswap > 0 then frac = h/anim_netswap end
  if not nonlocaly then
    nonlocaly = target_y
  end
  local y = target_y
  if y > (nonlocaly + frac) then
    y = nonlocaly + frac
  elseif y < (nonlocaly - frac) then
    y = nonlocaly - frac
  end
  nonlocaly = y
  
  -- update player list for animation
  if not nonlocalp then
    nonlocalp = { }
    nonlocalp[1] = { p = player, t = Game.ticks }
  end
  if not (nonlocalp[#nonlocalp].p == player) then
    table.insert(nonlocalp, { p = player, t = Game.ticks })
  else
    nonlocalp[#nonlocalp].t = Game.ticks
  end
  while (Game.ticks - nonlocalp[1].t) >= anim_netscroll do
    table.remove(nonlocalp, 1)
  end

  local sty = 0
  frac = h
  if anim_netscroll > 0 then frac = h/anim_netscroll end
  for i,v in ipairs(nonlocalp) do
    local t = Game.ticks - v.t
    local edy = (h - t*frac)

    Screen.clip_rect.y = y + sty
    Screen.clip_rect.height = edy - sty

    netrow_player(x, y, w, h, gametype, v.p)
    
    sty = edy
  end

  Screen.clip_rect.y = 0
  Screen.clip_rect.height = Screen.height
end
