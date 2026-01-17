@wrapMethod(CR4Player) function PlayHitEffect(damageAction : W3DamageAction) {
    if(damageAction.DealsAnyDamage() && !damageAction.IsDoTDamage()) {
    theGame.VibrateControllerVeryLight(0.05f);
    }
    
    wrappedMethod(damageAction);
}