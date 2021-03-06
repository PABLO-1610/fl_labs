---@author Pablo Z.
---@version 1.0
--[[
  This file is part of FreeLife.
  
  File [labs] created at [27/07/2021 19:23]

  Copyright (c) FreeLife - All Rights Reserved

  Unauthorized using, copying, modifying and/or distributing of this file,
  via any medium is strictly prohibited. This code is confidential.
--]]

---@class Labs
Labs = {}
---@type table<number, Lab>
Labs.list = {}

RegisterCommand("createlab", function(_src, args)
    if _src == 0 then return end
    local xPlayer = ESX.GetPlayerFromId(_src)
    if xPlayer.group ~= "superadmin" then
        Utils:notify(_src, "Vous n'avez pas la permission de faire cette commande")
        return
    end
    if #args ~= 2 then
        Utils:notify(_src, "Utilisation: ~y~/createlab (type) (faction)")
        return
    end
    local found = false
    for type, number in pairs(DrugType) do
        if tonumber(args[1]) == number then
            found = true
        end
    end
    if not found then
        Utils:notify(_src, "Cette drogue n'existe pas")
        return
    end
    Labs:add(tonumber(args[1]), args[2], GetEntityCoords(GetPlayerPed(_src)), _src)
    Utils:notify(_src, "~y~Création du labo en cours...")
end)

RegisterNetEvent("ft_labs:enterLab")
AddEventHandler("ft_labs:enterLab", function(labId)
    local _src = source
    if not Labs.list[labId] then
        DropPlayer(_src, "[ERREUR] fl_labs: le laboratoire est invalide")
        return
    end
    ---@type Lab
    local lab = Labs.list[labId]
    if not lab:isAllowed(_src) then
        TriggerClientEvent("esx:showNotification", "~r~Vous n'avez pas accès à ce laboratoire")
        return
    end
    lab:enter(_src)
end)

RegisterNetEvent("ft_labs:withdraw")
AddEventHandler("ft_labs:withdraw", function(labId)
    local _src = source
    if not Labs.list[labId] then
        DropPlayer(_src, "[ERREUR] fl_labs: le laboratoire est invalide")
        return
    end
    ---@type Lab
    local lab = Labs.list[labId]
    if not lab:isAllowed(_src) then
        TriggerClientEvent("esx:showNotification", _src, "~r~Vous n'avez pas accès à ce laboratoire")
        return
    end
    local xPlayer = ESX.GetPlayerFromId(_src)
    for item, qty in pairs(lab.container.output) do
        xPlayer.addInventoryItem(item, qty)
    end
    lab.container.output = {}
    lab:saveInventory()
    lab:updatePlayers()
    TriggerClientEvent("fl_labs:serverCb", _src, "~g~Objets récupérés !")
end)

RegisterNetEvent("ft_labs:deposit")
AddEventHandler("ft_labs:deposit", function(labId, itemId, qty)
    local _src = source
    if not Labs.list[labId] then
        DropPlayer(_src, "[ERREUR] fl_labs: le laboratoire est invalide")
        return
    end
    ---@type Lab
    local lab = Labs.list[labId]
    if not lab:isAllowed(_src) then
        TriggerClientEvent("esx:showNotification", _src, "~r~Vous n'avez pas accès à ce laboratoire")
        return
    end
    local xPlayer = ESX.GetPlayerFromId(_src)
    if xPlayer.getInventoryItem(itemId).count < qty then
        TriggerClientEvent("fl_labs:serverCb", _src, ("~r~Vous n'avez pas assez de cet objet pour pouvoir en déposer %s"):format(qty))
        return
    end
    --[[
    local maxQty = Drugs[lab.type].lab.capacity
    if (lab:getFullContainerSize() + qty) > maxQty then
        TriggerClientEvent("fl_labs:serverCb", _src, "~r~Capacité maximale dépassée")
        return
    end
    --]]
    if not lab.container.input[itemId] then
        lab.container.input[itemId] = 0
    end
    xPlayer.removeInventoryItem(itemId, qty)
    lab.container.input[itemId] = (lab.container.input[itemId] + qty)
    lab:saveInventory()
    lab:updatePlayers()
    TriggerClientEvent("fl_labs:serverCb", _src, "~g~Objets déposés")
end)

---initialize
---@return nil
---@public
function Labs:initialize()
    MySQL.Async.fetchAll("SELECT * FROM labs", {}, function(result)
        for _, data in pairs(result) do
            Labs.list[data.id] = Lab(true, data)
        end
    end)
end

---add
---@param type number
---@param faction string
---@param entry table<x:number, y:number, z:number>
---@param _src number
---@return nil
---@public
function Labs:add(type, faction, entry, _src)
    local defaultUpgrades, defaultFlags = {}, {}
    if Drugs[type] then
        defaultFlags = Drugs[type].lab.iplDefaultFlags
        for flag, values in pairs(Drugs[type].lab.upgrades) do
            for valueId, value in pairs(values) do
                if value.default then
                    defaultUpgrades[flag] = valueId
                end
            end
        end
    end
    MySQL.Async.insert("INSERT INTO labs (type, faction, entry, upgrades, flags, container) VALUES(@a, @b, @c, @d, @e, @f)", {
        ['@a'] = type,
        ['@b'] = faction,
        ['@c'] = json.encode(entry),
        ['@d'] = json.encode(defaultUpgrades),
        ['@e'] = json.encode(defaultFlags),
        ['@f'] = json.encode({ input = {}, output = {} })
    }, function(id)
        Labs.list[id] = Lab(false, {
            id = id,
            type = type,
            faction = faction,
            entry = entry,
            upgrades = defaultUpgrades,
            flags = defaultFlags,
            container = { input = {}, output = {} }
        })
        if _src ~= nil then Utils:notify(_src, "~g~Labo créé avec succès") end
    end)
end