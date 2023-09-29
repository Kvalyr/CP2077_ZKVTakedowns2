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

    -- Make takedown prompt only show when a weapon is held
    -- table.insert(instigatorPrereqs, "Prereqs.MeleeWeaponHeldPrereq")

    local flatKey = "Takedown.Kv_StealthFinisher.instigatorPrereqs"
    local success = TweakDB:SetFlat(flatKey, instigatorPrereqs)

end)
