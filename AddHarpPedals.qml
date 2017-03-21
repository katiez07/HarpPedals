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
//	follows: B=0, C=1, D=2, E=3, F=4, G=5, A=6. The arrays are composed of ints
//	which correspond to accidentals: -1=flat, 0=natural, 1=sharp.
// 	The functions use pitch and accidentalType to determine which pedals should 
//	be moved.

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
                        cursor.voice = voice; // voice has to be set after goTo
                        cursor.staffIdx = staff;

                        if (fullScore)
                              cursor.rewind(0) // if no selection, beginning of score
							  
							 
						// sets keyPedals
						if (Staff.keySignature == 0)
							keyPedals = [0, 0, 0, 0, 0, 0, 0];
						else if (Staff.keySignature == 1)
							keyPedals = [0, 0, 0, 0, 1, 0, 0];
						else if (Staff.keySignature == 2)
							keyPedals = [0, 1, 0, 0, 1, 0, 0];
						else if (Staff.keySignature == 3)
							keyPedals = [0, 1, 0, 0, 1, 1, 0];
						else if (Staff.keySignature == 4)
							keyPedals = [1, 1, 0, 0, 1, 1, 0];
						else if (Staff.keySignature == 5)
							keyPedals = [1, 1, 0, 0, 1, 1, 1];
						else if (Staff.keySignature == 6)
							keyPedals = [1, 1, 0, 1, 1, 1, 1];
						else if (Staff.keySignature == 7)
							keyPedals = [1, 1, 1, 1, 1, 1, 1];
						else if (Staff.keySignature == -1)
							keyPedals = [0, 0, -1, 0, 0, 0, 0];
						else if (Staff.keySignature == -2)
							keyPedals = [0, 0, -1, -1, 0, 0, 0];
						else if (Staff.keySignature == -3)
							keyPedals = [0, 0, -1, -1, 0, 0, -1];
						else if (Staff.keySignature == -4)
							keyPedals = [-1, 0, -1, -1, 0, 0, -1];
						else if (Staff.keySignature == -5)
							keyPedals = [-1, 0, -1, -1, 0, -1, -1];
						else if (Staff.keySignature == -6)
							keyPedals = [-1, -1, -1, -1, 0, -1, -1];
						else if (Staff.keySignature == -7)
							keyPedals = [-1, -1, -1, -1, -1, -1, -1];
						else
							console.log("unknown key signature")
						
						var pedalText;
                        while (cursor.segment && (fullScore || cursor.tick < endTick)) {
                              if (cursor.element && cursor.element.type == Element.CHORD) {
                                    var graceChords = cursor.element.graceNotes;
                                    for (var i = 0; i < graceChords.length; i++) {
                                          // iterate through all grace chords
                                          var notes = graceChords[i].notes;
                                          for (var j = 0; j < notes.length; j++)
                                                func(notes[j], curPedals, keyPedals);
                                    }
                                    var notes = cursor.element.notes;
                                    for (var i = 0; i < notes.length; i++){
                                          pedalText = func(notes[i], curPedals, keyPedals);
										  var text = newElement(Element.STAFF_TEXT);
										  text.text = pedalText;
										  text.pos.x = 0;  //pedal text below note
										  text.pos.y = 10; //pedal text below note
										  cursor.add(text);
									}
                              }
                              cursor.next();
                        }
                  }
            }
      }

      function checkPedals(note, curPedals, keyPedals) {
		var tempPedals = [0, 0, 0, 0, 0, 0, 0]
		for (var i=0; i<7; i++)
			tempPedals[i] = curPedals[i];
			
		// if there's an accidental on the note, checking to see if it matches the current pedal configuration
		if (note.accidental){
			// D
			if (note.tcp % 7 == 5){
				if (note.accidentalType == 2)
					curPedals[0] = -1;
				else if (note.accidentalType == 5)
					curPedals[0] = 0;
				else if (note.accidentalType == 1)
					curPedals[0] = 1;
				else
					console.log("unknown accidental type")
			}
			// C
			else if (note.tcp % 7 == 0){
				if (note.accidentalType == 2)
					curPedals[1] = -1;
				else if (note.accidentalType == 5)
					curPedals[1] = 0;
				else if (note.accidentalType == 1)
					curPedals[1] = 1;
				else
					console.log("unknown accidental type")
			}
			// B
			else if (note.tcp % 7 == 2){
				if (note.accidentalType == 2)
					curPedals[2] = -1;
				else if (note.accidentalType == 5)
					curPedals[2] = 0;
				else if (note.accidentalType == 1)
					curPedals[2] = 1;
				else
					console.log("unknown accidental type")
			}
			// E
			else if (note.tcp % 7 == 4){
				if (note.accidentalType == 2)
					curPedals[3] = -1;
				else if (note.accidentalType == 5)
					curPedals[3] = 0;
				else if (note.accidentalType == 1)
					curPedals[3] = 1;
				else
					console.log("unknown accidental type")
			}
			// F
			else if (note.tcp % 7 == 6){
				if (note.accidentalType == 2)
					curPedals[4] = -1;
				else if (note.accidentalType == 5)
					curPedals[4] = 0;
				else if (note.accidentalType == 1)
					curPedals[4] = 1;
				else
					console.log("unknown accidental type")
			}
			// G
			else if (note.tcp % 7 == 1){
				if (note.accidentalType == 2)
					curPedals[5] = -1;
				else if (note.accidentalType == 5)
					curPedals[5] = 0;
				else if (note.accidentalType == 1)
					curPedals[5] = 1;
				else
					console.log("unknown accidental type")
			}
			// A
			else if (note.tcp % 7 == 3){
				if (note.accidentalType == 2)
					curPedals[6] = -1;
				else if (note.accidentalType == 5)
					curPedals[6] = 0;
				else if (note.accidentalType == 1)
					curPedals[6] = 1;
				else
					console.log("unknown accidental type")
			}
			else{
				console.log("unknown tcp")
			}
		}
			
		// if there is no accidental on the note, checking if it matches the key sig
		else{
				
		}
			
		// printing pedal changes if there were any
		for (var j=0; j<7; j++){
			if (curPedals[j] != tempPedals[j]){
				if (j == 0){
					if (note.accidentalType == 1)
						return "D" + qsTranslate("accidental", "Sharp");
					else if (note.accidentalType == 5)
						return "D" + qsTranslate("accidental", "Natural");
					else if (note.accidentalType == 2)
						return "D" + qsTranslate("accidental", "Flat");
					else
						return "x";
				}
				else if (j == 1){
					if (note.accidentalType == 1)
						return "C" + qsTranslate("accidental", "Sharp");
					else if (note.accidentalType == 5)
						return "C" + qsTranslate("accidental", "Natural");
					else if (note.accidentalType == 2)
						return "C" + qsTranslate("accidental", "Flat");
					else
						return "x";
				}
				else if (j == 2){
					if (note.accidentalType == 1)
						return "B" + qsTranslate("accidental", "Sharp");
					else if (note.accidentalType == 5)
						return "B" + qsTranslate("accidental", "Natural");
					else if (note.accidentalType == 2)
						return "B" + qsTranslate("accidental", "Flat");
					else
						return "x";
				}
				else if (j == 3){
					if (note.accidentalType == 1)
						return "E" + qsTranslate("accidental", "Sharp");
					else if (note.accidentalType == 5)
						return "E" + qsTranslate("accidental", "Natural");
					else if (note.accidentalType == 2)
						return "E" + qsTranslate("accidental", "Flat");
					else
						return "x";
				}
				else if (j == 4){
					if (note.accidentalType == 1)
						return "F" + qsTranslate("accidental", "Sharp");
					else if (note.accidentalType == 5)
						return "F" + qsTranslate("accidental", "Natural");
					else if (note.accidentalType == 2)
						return "F" + qsTranslate("accidental", "Flat");
					else
						return "x";
				}
				else if (j == 5){
					if (note.accidentalType == 1)
						return "G" + qsTranslate("accidental", "Sharp");
					else if (note.accidentalType == 5)
						return "G" + qsTranslate("accidental", "Natural");
					else if (note.accidentalType == 2)
						return "G" + qsTranslate("accidental", "Flat");
					else
						return "x";
				}
				else if (j == 6){
					if (note.accidentalType == 1)
						return "A" + qsTranslate("accidental", "Sharp");
					else if (note.accidentalType == 5)
						return "A" + qsTranslate("accidental", "Natural");
					else if (note.accidentalType == 2)
						return "A" + qsTranslate("accidental", "Flat");
					else
						return "x";
				}
				else{
					return "x";
				}
			}
		}
			return "";
      }

      onRun: {
            console.log("hello harp pedal adder");

            if (typeof curScore === 'undefined')
                  Qt.quit();

            applyToNotesInSelection(checkPedals)

            Qt.quit();
         }
}
