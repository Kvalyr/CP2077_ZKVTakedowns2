-- ====================================================================================================================
-- Stealth Finishers (ZKV_Takedowns) by Kvalyr for CP2077 v2.0
-- =========================================================
:: Adds the following features ::
♦ Melee Weapon finishers as stealth takedowns
♦ Takedowns without grappling first - Initiate grapple OR takedown from stealth (See screenshots)


:: Configuration ::
♦ None :)


:: Known Issues ::
♦ 'Frontal' finisher animations often playing when killing from behind
    • This is a limitation of the animations available in the game. I probably won't be fixing this; sorry.
♦ Blunt/Non-Lethal weapons have NOT been tested yet
    • As far as I've seen, non-lethal finishers work as intended but I haven't tested extensively. (Why not just use the choke in that case anyway?..)

:: Requirements ::
♦ Cyberpunk 2077 v2.0
♦ Cyber Engine Tweaks (latest version) ( https://www.nexusmods.com/cyberpunk2077/mods/107 )
♦ redscript (latest version) ( https://www.nexusmods.com/cyberpunk2077/mods/1511 )
♦ red4ext (latest version) ( https://www.nexusmods.com/cyberpunk2077/mods/2380 )

Use the old version of the mod from the following link if you're playing an older (pre-2.0) version of CP2077: https://www.nexusmods.com/cyberpunk2077/mods/6508?tab=posts&BH=0


:: Installation
♦ Install manually by extracting the bin and r6 folders to your CP2077 main folder. (Drag and drop from the .zip)
♦ Vortex installation is not supported. It might work, it might not. I don't use Vortex myself and can't help you with it.


:: Compatibility & Technical details ::

The following redscript methods are replaced:
♦ ScriptedPuppetPS.DetermineInteractionState()
♦ LocomotionTakedownEvents.SelectSyncedAnimationAndExecuteAction()
♦ TakedownUtils.TakedownActionNameToEnum()
♦ TakedownExecuteTakedownEvents.OnEnter()


Mods that also modify/replace the above functions/files will likely be incompatible with this mod.
Known compatibility risks:
♦ Breach Takedown by Scissors123454321 ( https://www.nexusmods.com/cyberpunk2077/mods/4808 )
    • ZKV_Takedowns and Breach Takedown both modify the `LocomotionTakedownEvents.SelectSyncedAnimationAndExecuteAction` method; but this mod incorporates the same fix to that method and as long as this mod loads last, they might work okay together. No guarantees.
    • I'll make changes for compatibility if necessary in a later version.


::  CREDITS ::
♦ The developers behind Cyber Engine Tweaks & redscript, without which this mod wouldn't be possible whatsoever
