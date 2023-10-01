-------------------------------------------------------------------------------
-- Settings

-- Change this to 'true' to enable 'stealth' kills from behind during combat
local allowFinishersInCombat = false
-- local allowFinishersWithRangedWeapons = true -- Broken - Don't change

-------------------------------------------------------------------------------

registerForEvent("onInit", function()
    -- Set up new interaction at same interaction layer as Grapple, using Choice2 (Grapple uses Choice1)
    TweakDB:CloneRecord("Interactions.Kv_StealthFinisher", "Interactions.NewPerkFinish")
    TweakDB:SetFlat("Interactions.Kv_StealthFinisher.action", "Choice2")
    TweakDB:SetFlat("Interactions.Kv_StealthFinisher.name", "Kv_StealthFinisher")
    TweakDB:SetFlat("Interactions.Kv_StealthFinisher.caption", LocKey(320)) -- "Stealth Kill"

    -- Create new Takedown record and link to new interaction
    TweakDB:CloneRecord("Takedown.Kv_StealthFinisher", "Takedown.NewPerkFinisher")
    TweakDB:SetFlat("Takedown.Kv_StealthFinisher.objectActionUI", "Interactions.Kv_StealthFinisher")
    TweakDB:SetFlat("Takedown.Kv_StealthFinisher.actionName", "Kv_StealthFinisher")
    TweakDB:SetFlat("Takedown.Kv_StealthFinisher.interactionLayer", "Grapple")
    -- Mimic the rewards flat of the Takedown.Takedown objectAction Record so that we properly award Shinobi XP on takedowns
    TweakDB:SetFlat("Takedown.Kv_StealthFinisher.rewards", TweakDB:GetFlat("Takedown.Takedown.rewards"))

    local instigatorPrereqs = TweakDB:GetFlat("Takedown.Grapple.instigatorPrereqs") -- Use grapple's prereqs as our basis
    -- if not allowFinishersWithRangedWeapons then
        table.insert(instigatorPrereqs, "Prereqs.MeleeWeaponHeldPrereq")
    -- end
    local flatKey_instigatorPrereqs = "Takedown.Kv_StealthFinisher.instigatorPrereqs"
    local instigatorPrereqsSuccess = TweakDB:SetFlat(flatKey_instigatorPrereqs, instigatorPrereqs)

    local targetPrereqs = TweakDB:GetFlat("Takedown.Kv_StealthFinisher.targetPrereqs")
    if not allowFinishersInCombat then
        table.insert(targetPrereqs, "Takedown.IsTargetInAcceptableState")
    end
    local flatKey_targetPrereqs = "Takedown.Kv_StealthFinisher.targetPrereqs"
    local targetPrereqsSuccess = TweakDB:SetFlat(flatKey_targetPrereqs, targetPrereqs)

    print(string.format("ZKVTD Init done - instigatorPrereqsSuccess: %s, targetPrereqsSuccess: %s, allowFinishersInCombat: %s", instigatorPrereqsSuccess, targetPrereqsSuccess, allowFinishersInCombat))

end)
