@wrapMethod(CActor) function AddEffectDefault(effectType: EEffectType, creat: CGameplayEntity, optional srcName: string, optional signEffect: bool): EEffectInteract {
    if (effectType == EET_LowHealth) {
        return EI_Deny; // block vanilla low-health fx.
    }

    return wrappedMethod(effectType, creat, srcName, signEffect);
}

@wrapMethod(CR4Player) function PlayHitEffect(damageAction : W3DamageAction) {
    if (false) {
        wrappedMethod(damageAction);
    }
    super.PlayHitEffect(damageAction);          // Do not call PlayEffect('hit_screen').
}

@wrapMethod(CBaseGameplayEffect) function OnUpdate(dt: float) {
    if (effectType == EET_Toxicity) {
        thePlayer.StopEffect(cameraEffectName);
        return false;  // Skip SwitchCameraEffect and PlayTargetFX.		
    }

    wrappedMethod(dt);  
}