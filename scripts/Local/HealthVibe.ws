class W3Effect_LowHealthVibe extends CBaseGameplayEffect {
    default effectType = EET_LowHealthVibe;
    default isPositive = false;
    default isNeutral = true;
    default isNegative = false;

    private saved var pulseTimer: float;        // Time until next vibration.
    private saved var vibing: bool;             // Is the effect currently active?
    private saved var doubleVibe: bool;         // Flag to get two quick vibes followed by a longGap.
    private saved var healthToxAlerted: bool;   // Prevent low health + tox damage aleart from firing every frame.

    private var longGap: float;             default longGap = 1.5f;
    private var shortGap: float;            default shortGap = 0.3f;
    private var alertVibeDuration: float;   default alertVibeDuration = 0.15f;  // On threshold crossed.
    private var healthVibeDuration: float;  default healthVibeDuration = 0.03f; // Heartbeat vibe.

    // 0 = Very Light; 1 = Light; 2 = Hard; 3 = Very Hard.
    private var alertVibeIntensity: int;    default alertVibeIntensity = 3;    // On threshold crossed.
    private var healthVibeIntensity: int;   default healthVibeIntensity = 1;   // Heartbeat vibe.

    private function Vibrate(intensity: int, duration: float) {
        switch (intensity) {
            case 3: theGame.VibrateControllerVeryHard(duration); break;
            case 2: theGame.VibrateControllerHard(duration); break;
            case 1: theGame.VibrateControllerLight(duration); break;
            default: theGame.VibrateControllerVeryLight(duration); break;
        }
    }

    public function Init(params: SEffectInitInfo) {
        params.duration = -1.0;                                     // Buff runs until removed.                              
        super.Init(params);
    }

    event OnEffectAdded(optional customParams: W3BuffCustomParams) {
        super.OnEffectAdded(customParams);

        Vibrate(alertVibeIntensity, alertVibeDuration);             // Alert for crossing threshold.
        pulseTimer = 2.0f;
        vibing = true;
    }

    event OnUpdate(dt: float) {
        var currentHealth: float = GetWitcherPlayer().GetStatPercents(BCS_Vitality);
        var lowHealth: float = theGame.params.LOW_HEALTH_EFFECT_SHOW;
        var hasToxVibe: bool = GetWitcherPlayer().HasBuff(EET_ToxicityVibe);

        longGap = 1.5f;
        shortGap = 0.3f;

        if (thePlayer.IsCiri()) {
            pulseTimer = -1.0f;
            vibing = false; 
            return false;                                           // Ciri Vibe buggy and she has massive regen anyway.
        }

        if (currentHealth > lowHealth) { 
            pulseTimer = -1.0f;
            vibing = false; 
            healthToxAlerted = false;                       
            GetWitcherPlayer().RemoveBuff(EET_LowHealthVibe);       // No more vibrations.
            return false;                                           // Early exit.
        }

        if (currentHealth > 0.1f || !hasToxVibe) {                  // Reset alert if health above 10% or no tox damage.
            healthToxAlerted = false;
        }

        if (hasToxVibe && currentHealth <= 0.1f) {
            if (!healthToxAlerted) {
                Vibrate(3, 0.2f);                                   // Very low health + tox damage alert.
                healthToxAlerted = true;
            }
        }

        if (vibing && hasToxVibe) {                                 // Prevent overlap with toxicity vibe.
            Vibrate(alertVibeIntensity, alertVibeDuration);
            pulseTimer = -1.0f;
            vibing = false;
        }

        if (!vibing && !hasToxVibe) {                               // Resume if stopped and below tox damage threshold.  
            pulseTimer = 2.0f;                                      
            vibing = true;
        }

        if (vibing) {

            pulseTimer -= dt;                                       // Countdown to next pulse using delta time.

            if (doubleVibe && pulseTimer <= 0.0f) {                 // Second pulse.
                Vibrate(2, healthVibeDuration);   
                pulseTimer = longGap;                               // reset for next full cycle.
                doubleVibe = false;  
            }

            else if (pulseTimer <= 0.0f) {
                Vibrate(healthVibeIntensity, healthVibeDuration);   // First pulse.
                pulseTimer = shortGap;                              // Short delay before second pulse.
                doubleVibe = true;                                 
            }
        }

        super.OnUpdate(dt);    
    }
}

@addField(CActor)
private var alreadyInWrap: bool; // Re-Entry flag for EET_LowHealth/EET_LowHealthVibe.

@wrapMethod(CActor) function AddEffectDefault(effectType: EEffectType, creat: CGameplayEntity, optional srcName: string, optional signEffect: bool): EEffectInteract {
    if (!alreadyInWrap && effectType == EET_LowHealth) {
        alreadyInWrap = true;

        if (!this.HasBuff(EET_LowHealthVibe)) {
            AddEffectDefault(EET_LowHealthVibe, thePlayer, "LowHealthVibeEffect"); // Add vibration effect.
        }

        alreadyInWrap = false;
        return EI_Deny; // block vanilla low-health fx.
    }

    return wrappedMethod(effectType, creat, srcName, signEffect);
}