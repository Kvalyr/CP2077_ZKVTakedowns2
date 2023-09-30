public static func ZKVLog(const str: script_ref<String>) -> Void {
    //   LogChannel(n"DEBUG", "ZKVTD: " + str);
    FTLog(s"ZKVTD2: " + str);
}

@replaceMethod(ScriptedPuppetPS)
  public final func DetermineInteractionState(interaction: ref<InteractionComponent>, context: GetActionsContext, objectActionsCallbackController: wref<gameObjectActionsCallbackController>) -> Void {
    let actionRecords: array<wref<ObjectAction_Record>>;
    let choices: array<InteractionChoice>;

    if !this.GetHudManager().IsQuickHackPanelOpened() {
      this.SetHasDirectInteractionChoicesActive(false);
      if !IsDefined(this.m_cooldownStorage) {
        this.m_cooldownStorage = new CooldownStorage();
        this.m_cooldownStorage.Initialize(this.GetID(), this.GetClassName(), this.GetGameInstance());
      };
      if !IsNameValid(context.interactionLayerTag) {
        context.interactionLayerTag = this.m_lastInteractionLayerTag;
      };
      if Equals(context.requestType, gamedeviceRequestType.Direct) {
        this.GetOwnerEntity().GetRecord().ObjectActions(actionRecords);

        // Kv Changes
        ArrayPush(actionRecords, TweakDBInterface.GetObjectActionRecord(t"Takedown.Kv_StealthFinisher"));
        // Kv Changes END

        this.GetValidChoices(actionRecords, context, objectActionsCallbackController, true, choices);
        if ArraySize(choices) > 0 {
          this.SetHasDirectInteractionChoicesActive(true);
        };
      };
    };
    this.PushChoicesToInteractionComponent(interaction, context, choices);
  }


// Static version of FinisherAttackEvents.GetFinisherNameBasedOnWeapon()
public final static func ZKV_GetFinisherNameBasedOnWeapon(const target: ref<GameObject>, const instigator: ref<GameObject>, const hasFromFront: Bool, const hasFromBack: Bool, out finisherName: CName) -> Bool {
    let angle: Float;
    let finisher: String;
    let i: Int32;
    let weaponRecord: ref<Item_Record>;
    let weaponTags: array<CName>;
    finisherName = n"finisher_default";
    let weapon: ref<WeaponObject> = GameObject.GetActiveWeapon(instigator);

    // ZKVLog(s"ZKV_GetFinisherNameBasedOnWeapon");

    if !IsDefined(weapon) {
        return false;
    };
    weaponRecord = TweakDBInterface.GetWeaponItemRecord(ItemID.GetTDBID(weapon.GetItemID()));
    if !IsDefined(weaponRecord) {
        return true;
    };
    finisherName = weaponRecord.ItemType().Name();
    if Equals(weaponRecord.ItemType().Type(), gamedataItemType.Wea_Sword) {
        finisherName = EnumValueToName(n"gamedataItemType", 82l);
    };
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

// public final static func ZKV_IsEffectTagInEffectSet(activator: wref<GameObject>, effectSetName: CName, effectTag: CName) -> Bool {
//     return GameInstance.GetGameEffectSystem(activator.GetGame()).HasEffect(effectSetName, effectTag);
// }

@replaceMethod(LocomotionTakedownEvents)
protected final func SelectSyncedAnimationAndExecuteAction(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>, owner: ref<GameObject>, target: ref<GameObject>, action: CName) -> Void {
    let effectTag: CName;
    let syncedAnimName: CName;
    let dataTrackingEvent: ref<TakedownActionDataTrackingRequest> = new TakedownActionDataTrackingRequest();
    let gameEffectName: CName = n"takedowns";

    switch this.GetTakedownAction(stateContext) {
        case ETakedownActionType.GrappleFailed:
        TakedownGameEffectHelper.FillTakedownData(scriptInterface.executionOwner, owner, target, gameEffectName, action, "");
        break;
        case ETakedownActionType.TargetDead:
        syncedAnimName = n"grapple_sync_death";
        break;
        case ETakedownActionType.BreakFree:
        syncedAnimName = n"grapple_sync_recover";
        break;
        case ETakedownActionType.Takedown:
        syncedAnimName = this.SelectRandomSyncedAnimation(stateContext);
        effectTag = n"kill";
        (target as NPCPuppet).SetMyKiller(owner);
        break;
        case ETakedownActionType.TakedownNonLethal:
        if stateContext.GetConditionBool(n"CrouchToggled") {
            syncedAnimName = n"grapple_sync_nonlethal_crouch";
        } else {
            syncedAnimName = this.SelectRandomSyncedAnimation(stateContext);
        };
        effectTag = n"setUnconscious";
        break;
        case ETakedownActionType.TakedownNetrunner:
        syncedAnimName = n"personal_link_takedown_01";
        effectTag = n"setUnconsciousTakedownNetrunner";
        break;
        case ETakedownActionType.TakedownMassiveTarget:
        TakedownGameEffectHelper.FillTakedownData(scriptInterface.executionOwner, owner, target, gameEffectName, action, "");
        effectTag = n"setUnconsciousTakedownMassiveTarget";
        break;
        case ETakedownActionType.AerialTakedown:
        TakedownGameEffectHelper.FillTakedownData(scriptInterface.executionOwner, owner, target, gameEffectName, this.SelectAerialTakedownWorkspot(scriptInterface, owner, target, true, true, false, false, action));
        effectTag = n"setUnconsciousAerialTakedown";
        break;
        case ETakedownActionType.BossTakedown:
        TakedownGameEffectHelper.FillTakedownData(scriptInterface.executionOwner, owner, target, gameEffectName, this.SelectSyncedAnimationBasedOnPhase(stateContext, target), "");
        effectTag = this.SetEffectorBasedOnPhase(stateContext);
        syncedAnimName = this.GetSyncedAnimationBasedOnPhase(stateContext);
        StatusEffectHelper.ApplyStatusEffect(target, t"BaseStatusEffect.BossTakedownCooldown");
        target.GetTargetTrackerComponent().AddThreat(owner, true, owner.GetWorldPosition(), 1.00, 10.00, false);
        break;
        case ETakedownActionType.ForceShove:
        syncedAnimName = n"grapple_sync_shove";
        break;

        // Kv
        // Repurpose unused KillTarget enumValue as Melee-weapon-takedown
        case ETakedownActionType.KillTarget:
            let weapon: ref<WeaponObject> = GameObject.GetActiveWeapon(owner as PlayerPuppet);
            let weaponRecord: ref<Item_Record> = TweakDBInterface.GetWeaponItemRecord(ItemID.GetTDBID(weapon.GetItemID()));
            let weapontags: array<CName> = weaponRecord.Tags();

            ZKV_GetFinisherNameBasedOnWeapon(target, owner, ArrayContains(weapontags, n"FinisherFront"), ArrayContains(weapontags, n"FinisherBack"), effectTag);
            TakedownGameEffectHelper.FillTakedownData(scriptInterface.executionOwner, owner, target, n"playFinisher", effectTag);

            (target as NPCPuppet).SetMyKiller(owner);
            break;
        // Kv End

        default:
        syncedAnimName = n"grapple_sync_kill";
        effectTag = n"kill";
    };
    if IsNameValid(syncedAnimName) && IsDefined(owner) && IsDefined(target) {
        if this.IsTakedownWeapon(stateContext, scriptInterface)
        {
            this.FillAnimWrapperInfoBasedOnEquippedItem(scriptInterface, false);
        };
        this.PlayExitAnimation(scriptInterface, owner, target, syncedAnimName);
    };
    dataTrackingEvent.eventType = this.GetTakedownAction(stateContext);
    scriptInterface.GetScriptableSystem(n"DataTrackingSystem").QueueRequest(dataTrackingEvent);
    this.DefeatTarget(stateContext, scriptInterface, owner, target, gameEffectName, effectTag);
}

@replaceMethod(TakedownUtils)
    public final static func TakedownActionNameToEnum(actionName: CName) -> ETakedownActionType {
        // ZKVLog(s"ZKV - TakedownActionNameToEnum() - actionName: " + NameToString(actionName));
        switch actionName {
            case n"GrappleFailed":
                return ETakedownActionType.GrappleFailed;
            case n"GrappleTarget":
                return ETakedownActionType.Grapple;
            case n"Takedown":
                return ETakedownActionType.Takedown;
            case n"TakedownNonLethal":
                return ETakedownActionType.TakedownNonLethal;
            case n"TakedownNetrunner":
                return ETakedownActionType.TakedownNetrunner;
            case n"TakedownMassiveTarget":
                return ETakedownActionType.TakedownMassiveTarget;
            case n"LeapToTarget":
                return ETakedownActionType.LeapToTarget;
            case n"AerialTakedown":
                return ETakedownActionType.AerialTakedown;
            case n"Struggle":
                return ETakedownActionType.Struggle;
            case n"BreakFree":
                return ETakedownActionType.BreakFree;
            case n"TargetDead":
                return ETakedownActionType.TargetDead;
            case n"KillTarget":
                return ETakedownActionType.KillTarget;
            case n"SpareTarget":
                return ETakedownActionType.SpareTarget;
            case n"ForceShove":
                return ETakedownActionType.ForceShove;
            case n"BossTakedown":
                return ETakedownActionType.BossTakedown;

            // Kv
            case n"Kv_MeleeTakedown":
                // ZKVLog(s"ZKV - TakedownActionNameToEnum() - actionName: Kv_MeleeTakedown");
                return ETakedownActionType.KillTarget;
            case n"Kv_StealthFinisher":
                // ZKVLog(s"ZKV - TakedownActionNameToEnum() - actionName: Kv_StealthFinisher");
                return ETakedownActionType.KillTarget;
            // Kv End

            default:
        };
        return ETakedownActionType.None;
    }

@replaceMethod(TakedownExecuteTakedownEvents)
    public func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
        let actionName: CName;
        let weaponType: gamedataItemType;
        // ZKVLog(s"TakedownExecuteTakedownEvents.OnEnter");
        if TakedownUtils.ShouldForceTakedown(scriptInterface) {
            actionName = n"TakedownNonLethal";
        } else {
            actionName = this.stateMachineInitData.actionName;
        };
        if Equals(this.GetTakedownAction(stateContext), ETakedownActionType.LeapToTarget) {
            actionName = n"AerialTakedown";
        };
        this.UpdateCameraParams(stateContext, scriptInterface);
        this.SetGameplayCameraParameters(scriptInterface, "cameraTakedowns");
        weaponType = TweakDBInterface.GetWeaponItemRecord(ItemID.GetTDBID(ScriptedPuppet.GetWeaponRight(scriptInterface.executionOwner).GetItemID())).ItemType().Type();
        // Kv
        // TODO: Only skip this during finisher-takedowns; don't interfere with base-game takedowns
        // if NotEquals(weaponType, gamedataItemType.Cyb_MantisBlades) {
        //     this.ForceTemporaryWeaponUnequip(stateContext, scriptInterface, true);
        // };
        // Kv End
        TakedownUtils.SetTakedownAction(stateContext, TakedownUtils.TakedownActionNameToEnum(actionName));
        this.SelectSyncedAnimationAndExecuteAction(stateContext, scriptInterface, scriptInterface.executionOwner, this.stateMachineInitData.target, actionName);
        this.SetLocomotionParameters(stateContext, scriptInterface);
        this.SetBlackboardIntVariable(scriptInterface, GetAllBlackboardDefs().PlayerStateMachine.Takedown, EnumInt(gamePSMTakedown.Takedown));
        // Kv
        // Make takedowns completely silent? This is overkill, but..
        // if !scriptInterface.HasStatFlag(gamedataStatType.CanTakedownSilently) {
        //     this.TriggerNoiseStim(scriptInterface.executionOwner, TakedownUtils.TakedownActionNameToEnum(actionName));
        // };
        // Kv End
        if Equals(this.GetTakedownAction(stateContext), ETakedownActionType.TakedownNonLethal) && stateContext.GetConditionBool(n"CrouchToggled") {
            scriptInterface.SetAnimationParameterFloat(n"crouch", 1.00);
        };
        GameInstance.GetRazerChromaEffectsSystem(scriptInterface.GetGame()).PlayAnimation(n"Takedown", false);
        GameInstance.GetTelemetrySystem(scriptInterface.GetGame()).LogTakedown(actionName, this.stateMachineInitData.target);
    }