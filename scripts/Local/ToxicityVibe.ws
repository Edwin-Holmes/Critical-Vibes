class W3Effect_ToxicityVibe extends CBaseGameplayEffect {
    default effectType = EET_ToxicityVibe;
    default isPositive = false;
    default isNeutral = true;
    default isNegative = false;

    private saved var pulseTimer: float;          // Time until next vibration.
    private saved var vibing: bool;               // Is the effect currently Active?
    private saved var doubleVibe: bool;           // Flag to get two quick vibes followed by a longGap.

    private var longGap: float;             default longGap = 1.0f;
    private var shortGap: float;            default shortGap = 0.15f;
    private var alertVibeDuration: float;   default alertVibeDuration = 0.15f; // On threshold crossed.
    private var toxVibeDuration: float;     default toxVibeDuration = 0.03f;   // Heartbeat vibe.

    // 0 = Very Light; 1 = Light; 2 = Hard; 3 = Very Hard.
    private var alertVibeIntensity: int;    default alertVibeIntensity = 3;    // On threshold crossed.
    private var toxVibeIntensity: int;      default toxVibeIntensity = 1;      // Heartbeat vibe.

    private function Vibrate(intensity: int, duration: float) {
        switch (intensity) {
            case 3: theGame.VibrateControllerVeryHard(duration); break;
            case 2: theGame.VibrateControllerHard(duration); break;
            case 1: theGame.VibrateControllerLight(duration); break;
            default: theGame.VibrateControllerVeryLight(duration); break;
        }
    }

    public function Init(params: SEffectInitInfo) {
        params.duration = -1.0;                                 // Buff runs until removed.
        
        super.Init(params);                                     // Call function in CBaseGameplayEffect.   
    }

    event OnEffectAdded(optional customParams: W3BuffCustomParams) {
        super.OnEffectAdded(customParams);

        Vibrate(alertVibeIntensity, alertVibeDuration);         // Alert vibe crossing threshold.
        pulseTimer = 2.0f;
        vibing = true;
    }

    event OnUpdate(dt: float) {
        var wp: W3PlayerWitcher = GetWitcherPlayer();
        var tox: float = wp.GetStatPercents(BCS_Toxicity);
        var tdt: float = wp.GetToxicityDamageThreshold();

        longGap = 1.0f;
        shortGap = 0.15f;

        if (vibing && tox < tdt) {                              // Exit when below threshold.
            pulseTimer = -1.0f;
            vibing = false;
            wp.RemoveBuff(EET_ToxicityVibe);
            return false;
        }

        if(vibing) {

            pulseTimer -= dt;                                   // Countdown to next pulse using delta time.   

            if (doubleVibe && pulseTimer <= 0.0f) {             // Second pulse
                Vibrate(toxVibeIntensity, toxVibeDuration);
                pulseTimer   = longGap;                         // reset for next full cycle
                doubleVibe   = false;
            }
        
            else if (pulseTimer <= 0.0f) {
                Vibrate(toxVibeIntensity, toxVibeDuration);     // First pulse
                pulseTimer   = shortGap;                        // Short delay before second pulse
                doubleVibe   = true;        
            }
        }
        
        super.OnUpdate(dt);
    }
}

@wrapMethod(W3Effect_Toxicity) function OnUpdate(deltaTime : float) {
    var wp: W3PlayerWitcher = GetWitcherPlayer();
    var tox: float = wp.GetStatPercents(BCS_Toxicity);
    var tdt: float = wp.GetToxicityDamageThreshold();

    if (tox >= tdt && !wp.HasBuff(EET_ToxicityVibe)) {          // Add vibe when threshold crossed.
        wp.AddEffectDefault(EET_ToxicityVibe, NULL, "ToxicityVibeEffect");
    }

    return wrappedMethod(deltaTime);
}