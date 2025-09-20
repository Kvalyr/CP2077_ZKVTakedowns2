module ZKVTD

import ZKVTD.ZKVTD_Utils


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


@wrapMethod(LocomotionTakedownEvents)
protected final func SelectSyncedAnimationAndExecuteAction(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>, owner: ref<GameObject>, target: ref<GameObject>, action: CName) -> Void {
    // Intercept this method and repurpose unused ETakedownActionType.KillTarget

    ZKVTD_Utils.Log("SelectSyncedAnimationAndExecuteAction");

    switch this.GetTakedownAction(stateContext) {
        case ETakedownActionType.KillTarget:

            ZKVTD_Utils.Log("SelectSyncedAnimationAndExecuteAction - ETakedownActionType.KillTarget");

            let effectTag: CName = n"kill";
            let syncedAnimName: CName = n"grapple_sync_kill";
            let dataTrackingEvent: ref<TakedownActionDataTrackingRequest> = new TakedownActionDataTrackingRequest();
            let gameEffectName: CName = n"takedowns";

            // Set up effect tags etc. for Stealth Takedown
            effectTag = ZKVTD_Utils.ETakedownActionType_KillTarget(scriptInterface, owner, target, effectTag);

            // ====
            // Replicating LocomotionTakedownEvents.SelectSyncedAnimationAndExecuteAction
            if IsNameValid(syncedAnimName) && IsDefined(owner) && IsDefined(target) {
                // ZKVTD_Utils.Log("SelectSyncedAnimationAndExecuteAction - IsNameValid");
                if this.IsTakedownWeapon(stateContext, scriptInterface)
                {
                    ZKVTD_Utils.Log("SelectSyncedAnimationAndExecuteAction - IsTakedownWeapon");
                    this.FillAnimWrapperInfoBasedOnEquippedItem(scriptInterface, false);
                };
                this.PlayExitAnimation(scriptInterface, owner, target, syncedAnimName);
            };
            // ZKVTD_Utils.Log("SelectSyncedAnimationAndExecuteAction - syncedAnimName: " + NameToString(syncedAnimName) + ", effectTag: " + NameToString(effectTag));
            dataTrackingEvent.eventType = this.GetTakedownAction(stateContext);
            scriptInterface.GetScriptableSystem(n"DataTrackingSystem").QueueRequest(dataTrackingEvent);
            this.DefeatTarget(stateContext, scriptInterface, owner, target, gameEffectName, effectTag);
            break;
            // ==== End of replicating LocomotionTakedownEvents.SelectSyncedAnimationAndExecuteAction

        default:
            // If not ETakedownActionType.KillTarget, just defer to the wrapped method
            wrappedMethod(stateContext, scriptInterface, owner, target, action);
            break;
    }
}


@wrapMethod(TakedownUtils)
    public final static func TakedownActionNameToEnum(actionName: CName) -> ETakedownActionType {
        switch actionName {
            case n"Kv_MeleeTakedown":
                // ZKV_Takedowns.Log(s"ZKV - TakedownActionNameToEnum() - actionName: Kv_MeleeTakedown");
                return ETakedownActionType.KillTarget;
            case n"Kv_StealthFinisher":
                // ZKV_Takedowns.Log(s"ZKV - TakedownActionNameToEnum() - actionName: Kv_StealthFinisher");
                return ETakedownActionType.KillTarget;
        default:
            return wrappedMethod(actionName);
    }
}


@wrapMethod(TakedownExecuteTakedownEvents)
    public func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {

    ZKVTD_Utils.Log("SelectSyncedAnimationAndExecuteAction");

    switch this.GetTakedownAction(stateContext) {
        case ETakedownActionType.KillTarget:
            // ====
            // Kv: Replicating TakedownExecuteTakedownEvents.OnEnter
            // But we don't temp-unequip weapon for ETakedownActionType.KillTarget

            let actionName: CName;
            let weaponType: gamedataItemType;
            // ZKV_Takedowns.Log(s"TakedownExecuteTakedownEvents.OnEnter");
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
            // Skip this during finisher-takedowns; don't interfere with base-game takedowns
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
            // ==== End of replicating Replicating TakedownExecuteTakedownEvents.OnEnter
            break;

        default:
            // If not ETakedownActionType.KillTarget, just defer to the wrapped method
            wrappedMethod(stateContext, scriptInterface);
            break;
    }
}
