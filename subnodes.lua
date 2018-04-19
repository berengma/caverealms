 
--[[ this lua file was made by Tagada the April 16th 2018

   in the following comments I distinguish the mod "stairs" (with quotes)
   from the stair-shaped node stair (without quotes), as i write mods "names" with quotes.

   The goal is to register the full blocks provided by this mod in :
   1°) the circular saw ('c-saw') provided by the mod "moreblocks\stairsplus";
   2°) the mod "stairs" optionaly as fallback if moreblocks is not present;
   3°) the mod "columnia"
   
   Note that it is not possible to register all the blocks in the workbench from "xdecor" because
   "xdecor" have rules that exclude nodes with some fields (for example 'light_source') from
   being processed by the workbench.
   
   
   by this way we can obtain
   1°) slopes, microblocks, stairs and all sub-nodes by c-saw;
   2°) recipes for stairs and slabs from "stairs";
   3°) the columns blocks by "columnia";
   
   if those mods are installed of course ! (we test that first of all)   
   
   Why "stairs" and/or/not c-saw ?
   -------------------------------------------
      c-saw provide more subnodes than "stairs";
      c-saw preserve the name of the original mod while "stairs" do not.
            for example with stairs c-saw register "caverealm:stair_glow_crystal" while
               "stairs" register "stairs:stair_glow_crystal";
      c-saw preserve all the fields from the original blocks, like 'use_texture_alpha' for transparency;
      "stairs" do not preserve some fields like transparency, so we have to override the nodes created to preserve all the fields;
      
   so you may want to register -or not- with c-saw and/or "stairs" (optionaly as fallback) : see below

   
   
   WHAT YOU HAVE TO DO :
   =====================
   
   1°) Edit the depends.txt file of this mod and add (if they are not present) the lines :
   
      moreblocks?
      stairs?
      columnia?
      
   to be sure that those mods will be loaded prior to this one and then their registering functions can be call by us
   
   2°) Edit the init.lua of this mod "caverealms" and add the line :
   
      dofile(modpath.."/subnodes.lua")
      
   actualy at line n°19, just after the existing line :
      dofile(modpath.."/abms.lua") --abm definitions
      
   Our "dofile()" will make this subnodes.lua processed
   
   3°) copy this file subnodes.lua in the directory of the mod "caverealms"
   
   
   License: as this mod, code WTFPL (the only work i've done is to call the registering functions of
   the mods moreblocks-circular saw, stairs and columnia)
   Have fun :)   
   contact : tagacraft@free.fr
]]

--[[ the folowing booleans behave to register :
   1°) first with c-saw;
   2°) if c-saw is not present, with "stairs" as fallback;
   3°) not with "stairs", no matter if c-saw was called or not;
   4°) with "columnia"

]]
local allow_c_saw = true      -- register with circular saw;
local fallback_to_stairs = true  -- with "stairs" only if "moreblocks" is not installed
local also_stairs = false        -- register with "stairs" even if registered with circular saw
local allow_columnia = true      -- register with "columnia"

local c_saw_installed = false
local stairs_installed = false
local columnia_installed = false

if minetest.get_modpath("moreblocks") then
   c_saw_installed = true
end

if minetest.get_modpath("stairs") then
   stairs_installed = true
end

if minetest.get_modpath("columnia") then
   columnia_installed = true
end

-- construct the list of the nodes to register in "moreblocks", "stairs" and "columnia" :
local nodes2register = {
   "glow_crystal",
   "glow_emerald",
   "glow_mese",
   "glow_ruby",
   "glow_amethyst",
   "glow_ore",
   "glow_emerald_ore",
   "glow_ruby_ore",
   "glow_amethyst_ore",
   "thin_ice",
   "salt_crystal",
   "stone_with_salt",
   "hot_cobble",
   "glow_obsidian",
   "glow_obsidian_2",
   "coal_dust",
   "mushroom_stem",
   "mushroom_cap",
}

if c_saw_installed and allow_c_saw then
   -- ==================================================
   -- Registering for 'circular saw' from "moreblocks" :

   --[[ for memory, the function in moreblocks/stairsplus/init.lua is :
      function stairsplus:register_all(modname, subname, recipeitem, fields)
   ]]
   local node_name=""
   for i,v in ipairs(nodes2register) do
      node_name = "caverealms:"..v
      stairsplus:register_all("caverealms", v, node_name,   minetest.registered_nodes[node_name])
      table.insert(circular_saw.known_stairs, node_name)
   end   
end

if stairs_installed and (also_stairs or ( not c_saw_installed and fallback_to_stairs)) then
--[[
   for memory the registering function from stairs/init.lua is :
      function stairs.register_stair_and_slab(subname, recipeitem,
            groups, images, desc_stair, desc_slab, sounds)
         stairs.register_stair(subname, recipeitem, groups, images, desc_stair, sounds)
         stairs.register_slab(subname, recipeitem, groups, images, desc_slab, sounds)
      end
   And nodes will be called stairs:{stair,slab}_<subname> example : stairs:stair_glow_crystal
]]

--function to override "stairs" registered nodes to preserve fields not taken in account by "stairs" :
   local function override_stairs(generic_name, main_node)
      local fields_to_add = {}
      local name_prefix = "stairs:"
      local name_mids = {"stair_","slab_"}
      local node_name = ""   
      -- retrieve all the fields from the main node :
      for k,v in pairs(minetest.registered_nodes[main_node]) do
         -- keep all the field that are not functions because we look only for fields like "light_source", "use_texture_alpha", etc.
         if type(v)~="function" then fields_to_add[k] = v end
      end
      
      for key, value in pairs(name_mids) do -- construct the sub_nodes names to override (slab, stair)
         node_name = name_prefix..value..generic_name -- example: stairs:stair_glow_crystal
         local node = {}
         for k,v in pairs(minetest.registered_nodes[node_name]) do node[k] = v end -- clone the node created by "stairs";
         for k2add, v2add in pairs(fields_to_add) do
            if not node[k2add] then node[k2add] = v2add end-- add fields/values from fields_to_add if they not yet exist;
         end   
         node_name = ":"..node_name
         minetest.register_node(node_name, node) -- override node
      end      
   end

   local node_name_short= ""
   local node_name_full = ""
   local groups={}
   local images={}
   local desc=""
   local desc_slab=""
   local desc_stair=""
   local sounds={}
   
   for i,v in ipairs(nodes2register) do
      node_name_short = v
      node_name_full = "caverealms:"..node_name_short
      groups = minetest.registered_nodes[node_name_full].groups
      images = minetest.registered_nodes[node_name_full].tiles
      desc =  minetest.registered_nodes[node_name_full].description
      desc_stair = desc.." stair"
      desc_slab = desc.." slab"
      sounds =  minetest.registered_nodes[node_name_full].sounds
      
      stairs.register_stair_and_slab(node_name_short, node_name_full,   groups, images, desc_stair, desc_slab, sounds)
      override_stairs(node_name_short, node_name_full)    
   end

end


-- ================================
-- Registering for 'columnia' mod :

if columnia_installed and allow_columnia then

--function to override "columnia" registered nodes to preserve fields not taken in account by "columnia" :
   local function override_column(generic_name, main_node)
   -- for example generic_name = "glow_crystal" and main_node = "caverealms:glow_crystal"
      local fields_to_add = {}
      local name_prefix = "columnia:column_"
      local name_mids = {"mid_","bottom_","top_","crosslink_","link_","linkdown_"}
      local node_name = ""      
      
      -- retrieve all the fields from the main node :
      for k,v in pairs(minetest.registered_nodes[main_node]) do
         -- keep all the field that are not functions because we look only for fields like "light_source", "use_texture_alpha", etc.
         if type(v)~="function" then fields_to_add[k] = v end
      end

      for key, value in pairs(name_mids) do -- construct each node name to override
         node_name = name_prefix..value..generic_name -- example: columnia:column_mid_glow_crystal
         local node = {}
         for k,v in pairs(minetest.registered_nodes[node_name]) do node[k] = v end -- clone the node created by "columnia";
         for k2add, v2add in pairs(fields_to_add) do
            if not node[k2add] then node[k2add] = v2add end -- add fields/values from fields_to_add if they not yet exist;
         end   
         node_name = ":"..node_name
         minetest.register_node(node_name, node) -- override node
      end      
   end

   local node_name_short=""
   local node_name_full=""
   local groups={}
   local images={}
   local desc=""
   
   for i,v in ipairs(nodes2register) do
      node_name_short = v
      node_name_full = "caverealms:"..v
      groups = minetest.registered_nodes[node_name_full].groups
      images = minetest.registered_nodes[node_name_full].tiles
      desc =  minetest.registered_nodes[node_name_full].description
      sounds =  minetest.registered_nodes[node_name_full].sounds
   
      columnia.register_column_ia(node_name_short, node_name_full,
         groups, images,
         desc.." Column",
         desc.." Column Top",
         desc.." Column Bottom",
         desc.." Column Crosslink",
         desc.." Column Link",
         desc.." Column Linkdown",
         sounds)
      -- override nodes to add some missing fields :
      override_column(node_name_short, node_name_full)      
   end   
   end
   