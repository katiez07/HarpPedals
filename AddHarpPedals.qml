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
			
		// if the note has an accidental, set the note's pedal to the new accidental
		if (note.accidental){
			// flats DCBEFGA
			if (note.tpc == 9)
				curPedals[0] = -1;
			else if (note.tpc == 7)
				curPedals[1] = -1;
			else if (note.tpc == 12)
				curPedals[2] = -1;
			else if (note.tpc == 11)
				curPedals[3] = -1;
			else if (note.tpc == 6)
				curPedals[4] = -1;
			else if (note.tpc == 8)
				curPedals[5] = -1;
			else if (note.tpc == 10)
				curPedals[6] = -1;
				
			// naturals DCBEFGA
			else if (note.tpc == 16)
				curPedals[0] = 0;
			else if (note.tpc == 14)
				curPedals[1] = 0;
			else if (note.tpc == 19)
				curPedals[2] = 0;
			else if (note.tpc == 18)
				curPedals[3] = 0;
			else if (note.tpc == 13)
				curPedals[4] = 0;
			else if (note.tpc == 15)
				curPedals[5] = 0;
			else if (note.tpc == 17)
				curPedals[6] = 0;
				
			// sharps DCBEFGA
			else if (note.tpc == 23)
				curPedals[0] = 1;
			else if (note.tpc == 21)
				curPedals[1] = 1;
			else if (note.tpc == 26)
				curPedals[2] = 1;
			else if (note.tpc == 25)
				curPedals[3] = 1;
			else if (note.tpc == 20)
				curPedals[4] = 1;
			else if (note.tpc == 22)
				curPedals[5] = 1;
			else if (note.tpc == 24)
				curPedals[6] = 1;
				
			else
				console.log("unknown tpc")
		}
			
		// else set the note's pedal to the key sig
		else{
			if ((note.tpc == 9) || (note.tpc == 16) || (note.tpc == 23))
				curPedals[0] = keyPedals[0];
			else if ((note.tpc == 7) || (note.tpc == 14) || (note.tpc == 21))
				curPedals[1] = keyPedals[1];
			else if ((note.tpc == 12) || (note.tpc == 19) || (note.tpc == 26))
				curPedals[2] = keyPedals[2];
			else if ((note.tpc == 11) || (note.tpc == 18) || (note.tpc == 25))
				curPedals[3] = keyPedals[3];
			else if ((note.tpc == 6) || (note.tpc == 13) || (note.tpc == 20))
				curPedals[4] = keyPedals[4];
			else if ((note.tpc == 8) || (note.tpc == 15) || (note.tpc == 22))
				curPedals[5] = keyPedals[5];
			else if ((note.tpc == 10) || (note.tpc == 17) || (note.tpc == 24))
				curPedals[6] = keyPedals[6];
			else
				console.log("unknown tpc")
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
