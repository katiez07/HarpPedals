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
			
			//var keyPedals = [0, 0, 0, 0, 0, 0, 0]
			
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
                                                func(notes[j]);
                                    }
                                    var notes = cursor.element.notes;
                                    for (var i = 0; i < notes.length; i++) {
                                          var note = notes[i];
                                          pedalText = func(note);
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

      function colorRedIfAcc(note) {
            if (note.accidental) {
				//if ((note.pitch == 6) || (note.pitch == 78))
				if (note.accidentalType == 1)
					return "pedal";
				return "hi";
            }

            for (var i = 0; i < note.dots.length; i++) {
                  if (note.dots[i]) {
                        if (note.dots[i].color == black)
                              note.dots[i].color = red;
                        else
                              note.dots[i].color = black;
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
