module ZKVTD


public class ZKVTD_Utils extends IScriptable {

    public static func Log(const str: script_ref<String>) -> Void {
        //   LogChannel(n"DEBUG", "ZKVTD: " + str);
        FTLog(s"ZKVTD2: " + str);
    }

    // Static version of FinisherAttackEvents.GetFinisherNameBasedOnWeapon()
    public static func GetFinisherNameByWeapon(const target: ref<GameObject>, const instigator: ref<GameObject>, const hasFromFront: Bool, const hasFromBack: Bool, out finisherName: CName) -> Bool {
        let angle: Float;
        let finisher: String;
        let i: Int32;
        let weaponRecord: ref<Item_Record>;
        let weaponTags: array<CName>;
        finisherName = n"finisher_default";
        let weapon: ref<WeaponObject> = GameObject.GetActiveWeapon(instigator);

        // ZKVTD_Utils.Log(s"GetFinisherNameByWeapon");

        if !IsDefined(weapon) {
            return false;
        };
        weaponRecord = TweakDBInterface.GetWeaponItemRecord(ItemID.GetTDBID(weapon.GetItemID()));
        if !IsDefined(weaponRecord) {
            return true;
        };

        // ZKVTD_Utils.Log(s"GetFinisherNameByWeapon - weaponRecord.ItemType().Name(): " + NameToString(weaponRecord.ItemType().Name()));
        finisherName = weaponRecord.ItemType().Name();
        if Equals(weaponRecord.ItemType().Type(), gamedataItemType.Wea_Sword) {
            finisherName = EnumValueToName(n"gamedataItemType", 82l);
            // ZKVTD_Utils.Log(s"GetFinisherNameByWeapon - Wea_Sword - EnumValueToName::gamedataItemType: " + NameToString(finisherName));
        };

        // Gwynbleidd hack to force it to be treated as a Katana
        if weapon.GetItemID().GetTDBID() == t"Items.Preset_Sword_Witcher" {
            // ZKVTD_Utils.Log(s"GetFinisherNameByWeapon - Items.Preset_Sword_Witcher");
            finisherName = n"Wea_Katana";
        }

        weaponTags = weaponRecord.Tags();
        i = ArraySize(weaponTags) - 1;
        while i >= 0 {
            if GameInstance.GetGameEffectSystem(instigator.GetGame()).HasEffect(n"playFinisher", weaponTags[i]) {
                finisherName = weaponTags[i];
                break;
            };
            i -= 1;
        };
        if IsNameValid(finisherName) {
            angle = Vector4.GetAngleBetween(instigator.GetWorldForward(), target.GetWorldForward());
            if hasFromBack && AbsF(angle) < 90.00 {
                finisher = NameToString(finisherName);
                finisher += "_Back";
                finisherName = StringToName(finisher);
                return true;
            };
            if hasFromFront && AbsF(angle) >= 90.00 {
                return true;
            };
        };
        return false;
    }

    public static func IsEffectTagInEffectSet(activator: wref<GameObject>, effectSetName: CName, effectTag: CName) -> Bool {
        return GameInstance.GetGameEffectSystem(activator.GetGame()).HasEffect(effectSetName, effectTag);
    }

    public static func ETakedownActionType_KillTarget(scriptInterface: ref<StateGameScriptInterface>, owner: ref<GameObject>, target: ref<GameObject>, effectTag: CName) -> CName {
        let weapon: ref<WeaponObject> = GameObject.GetActiveWeapon(owner as PlayerPuppet);
        let weaponRecord: ref<Item_Record> = TweakDBInterface.GetWeaponItemRecord(ItemID.GetTDBID(weapon.GetItemID()));
        let weapontags: array<CName> = weaponRecord.Tags();

        ZKVTD_Utils.GetFinisherNameByWeapon(target, owner, ArrayContains(weapontags, n"FinisherFront"), ArrayContains(weapontags, n"FinisherBack"), effectTag);
        TakedownGameEffectHelper.FillTakedownData(scriptInterface.executionOwner, owner, target, n"playFinisher", effectTag);

        // Apply memory wipe debuff to target to make them 'blind' and clear their threat-tracking
        StatusEffectHelper.ApplyStatusEffect(target as ScriptedPuppet, t"BaseStatusEffect.MemoryWipeExitCombat");

        // Apply blind debuff to ensure they can't see V
        StatusEffectHelper.ApplyStatusEffect(target as ScriptedPuppet, t"BaseStatusEffect.Blind");

        // Apply 'Gag' debuff (same as the game applies when hitting a target with the 'Gag Order' perk) to prevent them calling reinforcements while being killed
        StatusEffectHelper.ApplyStatusEffect(target as ScriptedPuppet, t"BaseStatusEffect.Gag");

        // ZKVTD_Utils.Log("ETakedownActionType_KillTarget 1: " + NameToString(effectTag));
        if !IsNameValid(effectTag) || !ZKVTD_Utils.IsEffectTagInEffectSet(owner, n"playFinisher", effectTag) {
            // effectTag = n"finisher_default";  // Broken
            // effectTag = n"KillTarget";  // Broken
            effectTag = n"Wea_Fists";
        }
        // ZKVTD_Utils.Log("ETakedownActionType_KillTarget 2: " + NameToString(effectTag));

        (target as NPCPuppet).SetMyKiller(owner);
        return effectTag;
    }


}
