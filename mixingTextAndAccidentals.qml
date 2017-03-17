//=============================================================================
//  MuseScore
//  Music Composition & Notation
//
//  Copyright (C) 2012 Werner Schweer
//  Copyright (C) 2013-2015 Nicolas Froment, Joachim Schmitz
//  Copyright (C) 2014 Jörn Eichler
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2
//  as published by the Free Software Foundation and appearing in
//  the file LICENCE.GPL
//=============================================================================


//	This plugin used modified code from the ColorNotes plugin, plus added
//	code for the pedal-adding functionality.
//  It uses two arrays to keep track of harp pedals, curPedals (for the position 
//	the pedals are currently in) and keyPedals (for the position the pedals
//	would be in if they matched the key signature). The pedal ordering is as
//	follows: B-0, C-1, D-2, E-3, F-4, G-5, A-6.
// 	It uses pitch and accidentalType to determine which pedals should be 
//	moved.

import QtQuick 2.0
import MuseScore 1.0

MuseScore {
      version:  "1.0"
      description: "This new plugin tests the modification of code in plugins :)"
      menuPath: "Plugins.Testing Text And Accidentals.Test Here"

      property variant black : "#000000"
	  property variant red : "#e21c48"

      // Apply the given function to all notes in selection
      // or, if nothing is selected, in the entire score

      function applyToNotesInSelection(func) {
            var cursor = curScore.newCursor();
            cursor.rewind(1);
            var startStaff;
            var endStaff;
            var endTick;
            var fullScore = false;
			
			var keyPedals = [0, 0, 0, 0, 0, 0, 0]
			var curPedals = [0, 0, 0, 0, 0, 0, 0]
			
            if (!cursor.segment) { // no selection
                  fullScore = true;
                  startStaff = 0; // start with 1st staff
                  endStaff = curScore.nstaves - 1; // and end with last
            } else {
                  startStaff = cursor.staffIdx;
                  cursor.rewind(2);
                  if (cursor.tick == 0) {
                        // this happens when the selection includes
                        // the last measure of the score.
                        // rewind(2) goes behind the last segment (where
                        // there's none) and sets tick=0
                        endTick = curScore.lastSegment.tick + 1;
                  } else {
                        endTick = cursor.tick;
                  }
                  endStaff = cursor.staffIdx;
            }
            console.log(startStaff + " - " + endStaff + " - " + endTick)
			
            for (var staff = startStaff; staff <= endStaff; staff++) {
                  for (var voice = 0; voice < 4; voice++) {
                        cursor.rewind(1); // sets voice to 0
                        cursor.voice = voice; //voice has to be set after goTo
                        cursor.staffIdx = staff;

                        if (fullScore)
                              cursor.rewind(0) // if no selection, beginning of score
						
						var pedalText;
                        while (cursor.segment && (fullScore || cursor.tick < endTick)) {
                              if (cursor.element && cursor.element.type == Element.CHORD) {
                                    var graceChords = cursor.element.graceNotes;
                                    for (var i = 0; i < graceChords.length; i++) {
                                          // iterate through all grace chords
                                          var notes = graceChords[i].notes;
                                          for (var j = 0; j < notes.length; j++)
                                                func(notes[j], curPedals);
                                    }
                                    var notes = cursor.element.notes;
                                    for (var i = 0; i < notes.length; i++) {
                                          var note = notes[i];
                                          pedalText = func(note, curPedals);
                                    }
                              }
							  
							  var text = newElement(Element.STAFF_TEXT);
							  text.text = pedalText;
							  text.pos.x = 0;  //pedal text below note
							  text.pos.y = 8.5; //pedal text below note
							  cursor.add(text);
							  
                              cursor.next();
                        }
                  }
            }
      }

      function colorRedIfAcc(note, curPedals) {
		var tempPedals = [0, 0, 0, 0, 0, 0, 0]
		for (var i=0; i<7; i++)
			tempPedals[i] = curPedals[i];
	  
		if (note.accidental) {
				if ((note.accidentalType == -1) && ((note.pitch == 10) || (note.pitch == 22) || (note.pitch == 34) || (note.pitch == 46) 
				|| (note.pitch == 58) || (note.pitch == 70) || (note.pitch == 82) || (note.pitch == 94) || (note.pitch == 106) || (note.pitch == 118)))
					curPedals[2] = -1;
				else if ((note.accidentalType == 0) && ((note.pitch == 11) || (note.pitch == 23) || (note.pitch == 35) || (note.pitch == 47)
				|| (note.pitch == 59) || (note.pitch == 71) || (note.pitch == 83) || (note.pitch == 95) || (note.pitch == 107) || (note.pitch == 119)))
					curPedals[2] = 0;
				else if ((note.accidentalType == -1) && ((note.pitch == 11) || (note.pitch == 23) || (note.pitch == 35) || (note.pitch == 47) 
				|| (note.pitch == 59) || (note.pitch == 71) || (note.pitch == 83) || (note.pitch == 95) || (note.pitch == 107) || (note.pitch == 119)))
					curPedals[1] = -1;
				else if ((note.accidentaType == 1) && ((note.pitch == 0) || (note.pitch == 12) || (note.pitch == 24) || (note.pitch == 36) || (note.pitch == 48) 
				|| (note.pitch == 60) || (note.pitch == 72) || (note.pitch == 84) || (note.pitch == 96) || (note.pitch == 108) || (note.pitch == 120)))
					curPedals[2] = 1;
				else if ((note.accidentaType == 0) && ((note.pitch == 0) || (note.pitch == 12) || (note.pitch == 24) || (note.pitch == 36) || (note.pitch == 48) 
				|| (note.pitch == 60) || (note.pitch == 72) || (note.pitch == 84) || (note.pitch == 96) || (note.pitch == 108) || (note.pitch == 120)))
					curPedals[1] = 0;
				else if ((note.accidentalType == 1) && ((note.pitch == 1) || (note.pitch == 13) || (note.pitch == 25) || (note.pitch == 37) || (note.pitch == 49)
				|| (note.pitch == 61) || (note.pitch == 73) || (note.pitch == 85) || (note.pitch == 97) || (note.pitch == 109) || (note.pitch == 121)))
					curPedals[1] = 1;
				else if ((note.accidentalType == -1) && ((note.pitch = 1) || (note.pitch == 13) || (note.pitch == 25) || (note.pitch == 37) || (note.pitch == 49) 
				|| (note.pitch == 61) || (note.pitch == 73) || (note.pitch == 85) || (note.pitch == 97) || (note.pitch == 109) || (note.pitch == 121)))
					curPedals[0] = -1;
				else if ((note.accidentalType == 0) && ((note.pitch == 2) || (note.pitch == 14) || (note.pitch == 26) || (note.pitch == 38) || (note.pitch == 50)
				|| (note.pitch == 62) || (note.pitch == 74) || (note.pitch == 86) || (note.pitch == 98) || (note.pitch == 110) || (note.pitch == 122)))
					curPedals[0] = 0;
				else if ((note.accidentalType == 1) && ((note.pitch == 3) || (note.pitch == 15) || (note.pitch == 27) || (note.pitch == 39) || (note.pitch == 51) 
				|| (note.pitch == 63) || (note.pitch == 75) || (note.pitch == 87) || (note.pitch == 99) || (note.pitch == 111) || (note.pitch == 123)))
					curPedals[0] = 1;
				else if ((note.accidentalType == -1) && ((note.pitch == 3) || (note.pitch == 15) || (note.pitch == 27) || (note.pitch == 39) || (note.pitch == 51)
				|| (note.pitch == 63) || (note.pitch == 75) || (note.pitch == 87) || (note.pitch == 99) || (note.pitch == 111) || (note.pitch == 123)))
					curPedals[3] = -1;
				else if ((note.accidentalType == 0) && ((note.pitch == 4) || (note.pitch == 16) || (note.pitch == 28) || (note.pitch == 40) || (note.pitch == 52) 
				|| (note.pitch == 64) || (note.pitch == 76) || (note.pitch == 88) || (note.pitch == 100) || (note.pitch == 112) || (note.pitch == 124)))
					curPedals[3] = 0;
				else if ((note.accidentalType == -1) && ((note.pitch == 4) || (note.pitch == 16) || (note.pitch == 28) || (note.pitch == 40) || (note.pitch == 52)
				|| (note.pitch == 64) || (note.pitch == 76) || (note.pitch == 88) || (note.pitch == 100) || (note.pitch == 112) || (note.pitch == 124)))
					curPedals[4] = -1;
				else if ((note.accidentalType == 1) && ((note.pitch == 5) || (note.pitch == 17) || (note.pitch == 29) || (note.pitch == 41) || (note.pitch == 53)
				|| (note.pitch == 65) || (note.pitch == 77) || (note.pitch == 89) || (note.pitch == 101) || (note.pitch == 113) || (note.pitch == 125)))
					curPedals[3] = 1;
				else if ((note.accidentalType == 0) && ((note.pitch == 5) || (note.pitch == 17) || (note.pitch == 29) || (note.pitch == 41) || (note.pitch == 53)
				|| (note.pitch == 65) || (note.pitch == 77) || (note.pitch == 89) || (note.pitch == 101) || (note.pitch == 113) || (note.pitch == 125)))
					curPedals[4] = 0;
				else if ((note.accidentalType == 1) && ((note.pitch == 6) || (note.pitch == 18) || (note.pitch == 30) || (note.pitch == 42) || (note.pitch == 54)
				|| (note.pitch == 66) || (note.pitch == 78) || (note.pitch == 90) || (note.pitch == 102) || (note.pitch == 114) || (note.pitch == 126)))
					curPedals[4] = 1;
				else if ((note.accidentalType == -1) && ((note.pitch == 6) || (note.pitch == 18) || (note.pitch == 30) || (note.pitch == 42) || (note.pitch == 54)
				|| (note.pitch == 66) || (note.pitch == 78) || (note.pitch == 90) || (note.pitch == 102) || (note.pitch == 114) || (note.pitch == 126)))
					curPedals[5] = -1;
				else if ((note.accidentalType == 0) && ((note.pitch == 7) || (note.pitch == 19) || (note.pitch == 31) || (note.pitch == 43) || (note.pitch == 55) 
				|| (note.pitch == 67) || (note.pitch == 79) || (note.pitch == 91) || (note.pitch == 103) || (note.pitch == 115) || (note.pitch == 127)))
					curPedals[5] = 0;
				else if ((note.accidentalType == 1) && ((note.pitch == 8) || (note.pitch == 20) || (note.pitch == 32) || (note.pitch == 44) || (note.pitch == 56)
				|| (note.pitch == 68) || (note.pitch == 80) || (note.pitch == 92) || (note.pitch == 104) || (note.pitch == 116)))
					curPedals[5] = 1;
				else if ((note.accidentalType == -1) && ((note.pitch == 8) || (note.pitch == 20) || (note.pitch == 32) || (note.pitch == 44) || (note.pitch == 56) 
				|| (note.pitch == 68) || (note.pitch == 80) || (note.pitch == 92) || (note.pitch == 104) || (note.pitch == 116)))
					curPedals[6] = -1;
				else if ((note.accidentalType == 0) && ((note.pitch == 9) || (note.pitch == 21) || (note.pitch == 33) || (note.pitch == 45) || (note.pitch == 57) 
				|| (note.pitch == 69) || (note.pitch == 81) || (note.pitch == 93) || (note.pitch == 105) || (note.pitch == 117)))
					curPedals[6] = 0;
				else if ((note.accidentalType == 1) && ((note.pitch == 10) || (note.pitch == 22) || (note.pitch == 34) || (note.pitch == 46) || (note.pitch == 58) 
				|| (note.pitch == 70) || (note.pitch == 82) || (note.pitch == 94) || (note.pitch == 106) || (note.pitch == 118)))
					curPedals[6] = 1;
				else
					console.log("unrecognized accidental type");
			}
			
			for (var j=0; j<7; j++){
				if (curPedals[j] != tempPedals[j]){
					if (j == 0){
						return "B";
					}
					else if (j == 1){
						return "C";
					}
					else if (j == 2){
						return "D";
					}
					else if (j == 3){
						return "E";
					}
					else if (j == 4){
						return "F";
					}
					else if (j == 5){
						return "G";
					}
					else if (j == 6){
						return "A";
					}
					else{
						return "?";
					}
				}
			}
			
			return "";
         }

      onRun: {
            console.log("hello harp pedal adder");

            if (typeof curScore === 'undefined')
                  Qt.quit();

            applyToNotesInSelection(colorRedIfAcc)

            Qt.quit();
         }
}
