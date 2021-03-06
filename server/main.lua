---@author Pablo Z.
---@version 1.0
--[[
  This file is part of FreeLife.
  
  File [main] created at [27/07/2021 12:09]

  Copyright (c) FreeLife - All Rights Reserved

  Unauthorized using, copying, modifying and/or distributing of this file,
  via any medium is strictly prohibited. This code is confidential.
--]]

ESX = nil

-- Loader
TriggerEvent("esx:getSharedObject", function(obj)
    ESX = obj
    -- ESX loaded
    Labs:initialize()
    LabsTransformer:init()
    Harvest:initialize()
end)

-- Prevent leak memory
AddEventHandler("playerDropped", function()
    local _src = source
    ---@param lab Lab
    for id, lab in pairs(Labs.list) do
        if(lab.inside[_src]) then
            lab:removeFromInside(_src)
        end
    end
end)