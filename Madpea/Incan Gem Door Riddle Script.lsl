// --- KONFIGURATION ---
// Reihenfolge angepasst an deine Story: Isle (Emerald) vor Tree (Jade)
list REIHENFOLGE = ["Amethyst", "Onyx", "Citrine", "Sapphire", "Emerald", "Jade", "Ruby"];

string SOUND_MAHLEN = "4354aede-ce14-5a91-e6a8-514b4e60976c"; 
string SOUND_FEHLER = "ce520714-59fb-dd73-b2b9-4ed2fe9f1327"; 
string SOUND_CLICK  = "b9de1817-0c19-9ef6-03b0-bd7597df193b"; 

vector BEWEGUNG = <3.5, 0.0, 0.0>; 
float DREHWINKEL = 60.0;        
integer SCHRITTE = 80; // Höherer Wert für majestätisch langsame Bewegung
float WARTEZEIT = 15.0;

// --- INTERNE VARIABLEN ---
list gEingabe = [];
integer gOffen = FALSE;
vector gStartPos;
rotation gStartRot;

// Hilfsfunktion: Setzt das Leuchten für einen bestimmten Prim
set_glow(integer link, float intensity, integer fullbright) {
    llSetLinkPrimitiveParamsFast(link, [PRIM_GLOW, ALL_SIDES, intensity, PRIM_FULLBRIGHT, ALL_SIDES, fullbright]);
}

// Hilfsfunktion: Alle Kristalle zurücksetzen
reset_all_gems() {
    integer i;
    for(i = 0; i < llGetListLength(REIHENFOLGE); i++) {
        string name = llList2String(REIHENFOLGE, i);
        // Wir suchen den Prim im Linkset anhand des Namens
        integer link_idx;
        for(link_idx = 2; link_idx <= llGetNumberOfPrims(); link_idx++) {
            if(llGetLinkName(link_idx) == name) set_glow(link_idx, 0.0, FALSE);
        }
    }
}

move_and_roll(integer auf) {
    llLoopSound(SOUND_MAHLEN, 1.0);
    integer i;
    for(i = 1; i <= SCHRITTE; i++) {
        float fortschritt = (float)i / (float)SCHRITTE;
        if(!auf) fortschritt = 1.0 - fortschritt;
        vector aktuelle_ziel_pos = gStartPos + (BEWEGUNG * fortschritt) * gStartRot;
        rotation aktuelle_ziel_rot = llEuler2Rot(<0, (DREHWINKEL * fortschritt) * DEG_TO_RAD, 0>) * gStartRot;
        llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_POSITION, aktuelle_ziel_pos, PRIM_ROTATION, aktuelle_ziel_rot]);
        llSleep(0.03); 
    }
    llStopSound();
}

default {
    state_entry() {
        gStartPos = llGetPos();
        gStartRot = llGetRot();
        reset_all_gems();
        llPreloadSound(SOUND_MAHLEN);
        llPreloadSound(SOUND_FEHLER);
        llPreloadSound(SOUND_CLICK);
    }

    touch_start(integer num_detected) {
        if(gOffen) return; 

        integer link_num = llDetectedLinkNumber(0);
        string geklickt = llGetLinkName(link_num);
        
        // Rätsel-Text ausgeben, wenn die Tür selbst geklickt wird
        if (link_num == LINK_ROOT) {
            llRegionSayTo(llDetectedKey(0), 0, "\nAn ancient inscription reads:\n'The Emperor in their robes of state traveled through the moonless night. Morning star revealed the way across the waters to the verdant isle and the dark leaf tree. They burned to set their spirits free.'");
            return;
        }

        integer index = llListFindList(REIHENFOLGE, [geklickt]);
        if(index != -1) {
            llTriggerSound(SOUND_CLICK, 1.0);
            
            // Visuelles Feedback: Kristall leuchtet auf
            set_glow(link_num, 0.3, TRUE);

            if(geklickt == llList2String(REIHENFOLGE, llGetListLength(gEingabe))) {
                gEingabe += [geklickt];
                if(llGetListLength(gEingabe) == llGetListLength(REIHENFOLGE)) {
                    gOffen = TRUE;
                    llOwnerSay("The mechanism awakens...");
                    move_and_roll(TRUE);
                    llSetTimerEvent(WARTEZEIT);
                }
            } else {
                llTriggerSound(SOUND_FEHLER, 1.0);
                llOwnerSay("The light fades... wrong sequence.");
                gEingabe = [];
                llSleep(0.5);
                reset_all_gems(); // Alle Lichter aus bei Fehler
            }
        }
    }

    timer() {
        llSetTimerEvent(0.0);
        move_and_roll(FALSE);
        reset_all_gems();
        llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_POSITION, gStartPos, PRIM_ROTATION, gStartRot]);
        gOffen = FALSE;
        gEingabe = [];
    }
    
    on_rez(integer sp) { llResetScript(); }
}
