/*
 * led.xc
 *
 *  Created on: Nov 3, 2014
 *      Author: jamie
 */

#include "led.h"
#include "constants.h"
#include "AntDefender.h"

out port cled0 = PORT_CLOCKLED_0;
out port cled1 = PORT_CLOCKLED_1;
out port cled2 = PORT_CLOCKLED_2;
out port cled3 = PORT_CLOCKLED_3;
out port cledG = PORT_CLOCKLED_SELG;
out port cledR = PORT_CLOCKLED_SELR;


//DISPLAYS an LED pattern in one quadrant of the clock LEDs
int showLED(out port p, chanend fromVisualiser) {
  unsigned int lightUpPattern;
  int shutDownLED = GAME_NOT_OVER;

  while (shutDownLED == GAME_NOT_OVER) {
    fromVisualiser :> lightUpPattern; //read LED pattern from visualiser process

    if (lightUpPattern == GAME_OVER) {
    	shutDownLED = GAME_OVER;
    } else {
    	p <: lightUpPattern;  //send pattern to LEDs
    }

  }
  return 0;
}

//PROCESS TO COORDINATE DISPLAY of LED Ants
void visualiser(chanend fromUserAnt, chanend fromAttackerAnt, chanend toQuadrant0, chanend toQuadrant1, chanend toQuadrant2, chanend toQuadrant3) {
  unsigned int userAntToDisplay = 11;
  unsigned int attackerAntToDisplay = 5;
  int shutDownVisualiser = GAME_NOT_OVER;
  int i, j;
  cledR <: 1;
  while (shutDownVisualiser == GAME_NOT_OVER) {
    select {
      case fromUserAnt :> userAntToDisplay:
    	  if (userAntToDisplay == GAME_OVER) {

    		  toQuadrant0 <: 0b01110000;
    		  toQuadrant1 <: 0b01110000;
    		  toQuadrant2 <: 0b01110000;
    		  toQuadrant3 <: 0b01110000;

    		  waitMoment(16000000);

    		  toQuadrant0 <: 0;
    		  toQuadrant1 <: 0;
    		  toQuadrant2 <: 0;
    		  toQuadrant3 <: 0;

    		  waitMoment(16000000);

    		  toQuadrant0 <: 0b01110000;
    		  toQuadrant1 <: 0b01110000;
    		  toQuadrant2 <: 0b01110000;
    		  toQuadrant3 <: 0b01110000;

    		  waitMoment(16000000);

    		  shutDownVisualiser = GAME_OVER;
    		  toQuadrant0 <: GAME_OVER;
    		  toQuadrant1 <: GAME_OVER;
    		  toQuadrant2 <: GAME_OVER;
    		  toQuadrant3 <: GAME_OVER;
    	  }
        break;
      case fromAttackerAnt :> attackerAntToDisplay:
        break;
    }
    if (attackerAntToDisplay == LEVEL_UP) {
    	printf("LEVEL UP\n");

    	cledR <: 0;
    	cledG <: 1;

		 toQuadrant0 <: 0b01110000;
		 toQuadrant1 <: 0b01110000;
		 toQuadrant2 <: 0b01110000;
		 toQuadrant3 <: 0b01110000;

		 waitMoment(16000000);

		 toQuadrant0 <: 0;
		 toQuadrant1 <: 0;
		 toQuadrant2 <: 0;
		 toQuadrant3 <: 0;

		 waitMoment(16000000);

		 toQuadrant0 <: 0b01110000;
		 toQuadrant1 <: 0b01110000;
		 toQuadrant2 <: 0b01110000;
		 toQuadrant3 <: 0b01110000;

		 waitMoment(16000000);

		 cledG <: 0;
		 cledR <: 1;

    	fromAttackerAnt <: LEVELED_UP;

    } else if (userAntToDisplay != GAME_OVER) {

    	j = 16<<(userAntToDisplay%3);
    	i = 16<<(attackerAntToDisplay%3);
    	toQuadrant0 <: (j*(userAntToDisplay/3==0)) + (i*(attackerAntToDisplay/3==0)) ;
    	toQuadrant1 <: (j*(userAntToDisplay/3==1)) + (i*(attackerAntToDisplay/3==1)) ;
    	toQuadrant2 <: (j*(userAntToDisplay/3==2)) + (i*(attackerAntToDisplay/3==2)) ;
    	toQuadrant3 <: (j*(userAntToDisplay/3==3)) + (i*(attackerAntToDisplay/3==3)) ;
    }
  }
}

