// ============================================================================
// Title: Protogen Visor Damage System LSL Script (Sound on State 1 & 2, Silent on Max Damage)
// Filepath: protogen_visor.lsl
// Description: LSL Script for Second Life Protogen visor damage with sound triggers on transitions, silent click at max damage state 2, and minimized chat spam.
// ============================================================================

integer API_CHANNEL = 1;

// Damage states: 0 = Normal, 1 = Cracked, 2 = Damaged (Max)
integer damageState = 0;

// Click counters and randomized thresholds
integer clickCount = 0;
integer targetFirstStage = 0;
integer targetSecondStage = 0;

// Custom Sound UUID constants provided by user
string SOUND_CLICK = "b3390fd5-233a-f30f-4d3e-12b69b674642"; // knock-Glas
string SOUND_HEAVY = "8a21b8a9-d3b2-4982-f240-921836443441"; // Damage-Sound

// Touch tracking for owner long-press repair (≥ 1.5 seconds)
float touchStartTime = 0.0;

resetTargets() {
    targetFirstStage = (integer)(llFrand(4.0) + 3.0);
    targetSecondStage = (integer)(llFrand(3.0) + 2.0);
    clickCount = 0;
}

applyVisualsAndAPI() {
    if (damageState == 0) {
        llRegionSay(API_CHANNEL, "PROTOGEN_API_SET_DAMAGE::0::None");
    } else if (damageState == 1) {
        llRegionSay(API_CHANNEL, "PROTOGEN_API_SET_DAMAGE::1::Cracked");
    } else if (damageState == 2) {
        llRegionSay(API_CHANNEL, "PROTOGEN_API_SET_DAMAGE::2::Damaged");
    }
}

default {
    state_entry() {
        llOwnerSay("[SYSTEM] Protogen Visor System Online.");
        damageState = 0;
        resetTargets();
        applyVisualsAndAPI();
    }

    touch_start(integer total_number) {
        touchStartTime = llGetTime();
    }

    touch_end(integer total_number) {
        float touchDuration = llGetTime() - touchStartTime;
        key toucher = llDetectedKey(0);
        integer isOwner = (toucher == llGetOwner());

        if (isOwner) {
            if (touchDuration >= 1.5) {
                damageState = 0;
                resetTargets();
                applyVisualsAndAPI();
                llTriggerSound(SOUND_CLICK, 1.0);
                llOwnerSay("[LSL_OWNER] Visor fully repaired!");
            } else {
                llTriggerSound(SOUND_CLICK, 1.0);
            }
            return;
        }

        // If visor is already at maximum damage (State 2), completely silent (no glass knock sound, no chat spam)
        if (damageState == 2) {
            return;
        }

        clickCount++;

        if (damageState == 0) {
            if (clickCount >= targetFirstStage) {
                damageState = 1;
                clickCount = 0;
                applyVisualsAndAPI();
                // Play heavy damage sound on transition to State 1
                llTriggerSound(SOUND_HEAVY, 1.0);
                llOwnerSay("[LSL_STATE] Visor transitioned to Stage 1 (Cracked).");
            } else {
                // Play standard glass knock on intermediate clicks leading to stage 1 (No chat spam)
                llTriggerSound(SOUND_CLICK, 1.0);
            }
        } 
        else if (damageState == 1) {
            if (clickCount >= targetSecondStage) {
                damageState = 2;
                clickCount = 0;
                applyVisualsAndAPI();
                // Play heavy sound on transition to State 2
                llTriggerSound(SOUND_HEAVY, 1.0);
                llOwnerSay("[LSL_STATE] Visor transitioned to Stage 2 (Damaged / Max).");
            } else {
                // Play standard glass knock on intermediate clicks leading to stage 2 (No chat spam)
                llTriggerSound(SOUND_CLICK, 1.0);
            }
        }
    }
}
