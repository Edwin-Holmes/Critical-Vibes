@wrapMethod(CR4Player) function PlayHitEffect(damageAction : W3DamageAction) {
    if (false) {
        wrappedMethod(damageAction);
    }
    
    super.PlayHitEffect(damageAction);          // Do not call PlayEffect('hit_screen').
    if(damageAction.DealsAnyDamage() && !damageAction.IsDoTDamage()) {
    theGame.VibrateControllerVeryLight(0.05f);
    }
}

@wrapMethod(CBaseGameplayEffect) function OnUpdate(dt: float) {
    if (effectType == EET_Toxicity || effectType == EET_VitalityDrain || effectType == EET_LowHealth) {
        thePlayer.StopEffect(cameraEffectName);
        return false;  // Skip SwitchCameraEffect and PlayTargetFX.		
    }

    return wrappedMethod(dt);  
}