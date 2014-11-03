/////////////////////////////////////////////////////////////////////////////////////////
//
// COMS20001
// ASSIGNMENT 1
// CODE SKELETON
// TITLE: "LED Ant Defender Game"
//
/////////////////////////////////////////////////////////////////////////////////////////

#include <stdio.h>
#include <platform.h>
#include <timer.h>

#define DEBUG 0

#ifndef DEBUG
#define printf(...)
#endif

#define MOVE_ALLOWED 0
#define MOVE_FORBIDDEN 1
#define GAME_OVER 2000
#define GAME_NOT_OVER 3000
#define GAME_TERMINATED 4000
#define GAME_PAUSED 5000
#define GAME_RESTARTED 6000
#define LEVEL_UP 7000
#define LEVELED_UP 8000

#define BUTTON_A 14
#define BUTTON_B 13
#define BUTTON_C 11
#define BUTTON_D 7

out port cled0 = PORT_CLOCKLED_0;
out port cled1 = PORT_CLOCKLED_1;
out port cled2 = PORT_CLOCKLED_2;
out port cled3 = PORT_CLOCKLED_3;
out port cledG = PORT_CLOCKLED_SELG;
out port cledR = PORT_CLOCKLED_SELR;
in port buttons = PORT_BUTTON;
out port speaker = PORT_SPEAKER;

void waitMoment(int timeToWait);

/////////////////////////////////////////////////////////////////////////////////////////
//
//  Helper Functions provided for you
//
/////////////////////////////////////////////////////////////////////////////////////////

//DISPLAYS an LED pattern in one quadrant of the clock LEDs
int showLED(out port p, chanend fromVisualiser) {
  unsigned int lightUpPattern;
  int shutDownLED = GAME_NOT_OVER;

  while (shutDownLED == GAME_NOT_OVER) {
    fromVisualiser :> lightUpPattern; //read LED pattern from visualiser process

    if (lightUpPattern == GAME_OVER) {
    	printf("Game over led");
    	shutDownLED = GAME_OVER;
    } else {
    	//printf("Light up pattern: %d\n", lightUpPattern);
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
    	printf("LEVELUP\n");

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

//PLAYS a short sound (pls use with caution and consideration to other students in the labs!)
void playSound(unsigned int wavelength, out port speaker) {
	timer tmr;
	int t, isOn = 1;
	tmr :> t;
	for (int i = 0; i < 2; i++) {
		isOn = !isOn;
		t += wavelength;
		tmr when timerafter(t) :> void;
		speaker <: isOn;
	}
}

//READ BUTTONS and send to userAnt
void buttonListener(in port b, out port spkr, chanend toUserAnt) {
	int r;
	int shutDownButtonListener = GAME_NOT_OVER;
	int prevButton = 15;

	while (shutDownButtonListener == GAME_NOT_OVER) {
		//printf("Button pressed\n");
	    b :> r;   // check if some buttons are pressed

	    if (prevButton == 15 && r != 15) {
	    	playSound(2000000,spkr);   // play sound
	    	toUserAnt <: r;            // send button pattern to userAnt

		    int isGameOver;
		    toUserAnt :> isGameOver;
		    if (isGameOver == GAME_OVER) {
		    	shutDownButtonListener = GAME_OVER;
		    }
	    }
	    prevButton = r;
	}
}

//WAIT function
void waitMoment(int timeToWait) {
	timer tmr;
	uint waitTime;
	tmr :> waitTime;
	waitTime += timeToWait;
	tmr when timerafter(waitTime) :> void;
}

int mod(int a, int b) {
	return (a % b + b) % b;
}

/////////////////////////////////////////////////////////////////////////////////////////
//
//  MOST RELEVANT PART OF CODE TO EXPAND FOR YOU
//
/////////////////////////////////////////////////////////////////////////////////////////

//DEFENDER PROCESS... The defender is controlled by this process userAnt,
//                    which has channels to a buttonListener, visualiser and controller
void userAnt(chanend fromButtons, chanend toVisualiser, chanend toController) {
	int userAntPosition = 11; //the current defender position
	int buttonInput; //the input pattern from the buttonListener
	int attemptedAntPosition = 0; //the next attempted defender position after considering button
	int moveForbidden; //the verdict of the controller if move is allowed
	int gameIsOver = 0;
	int gameIsPaused = 0;

	toVisualiser <: userAntPosition; //show initial position

	int i= 0;

	while (gameIsOver == 0) {
		timer t;
		unsigned int lastPress = 0;
		i++;

		fromButtons :> buttonInput;
		//printf("Is game paused: %d and button is %d\n", gameIsPaused, buttonInput);
		if (gameIsPaused == 1 && buttonInput == BUTTON_A) {
			//printf("Restart game\n");
			toController <: GAME_RESTARTED;
			fromButtons <: GAME_NOT_OVER;

			userAntPosition = 11;
			toVisualiser <: userAntPosition;
			gameIsPaused = 0;
		} else {
			if (buttonInput == BUTTON_A) {
				attemptedAntPosition = mod((userAntPosition + 1), 12);
			}
			if (buttonInput == BUTTON_D) {
				attemptedAntPosition = mod((userAntPosition - 1), 12);
			}
			if (buttonInput == BUTTON_C) {
				fromButtons <: GAME_OVER;
				toVisualiser <: GAME_OVER;
				toController <: GAME_TERMINATED;
			}
			if (buttonInput == BUTTON_B) {
				if (gameIsPaused == 0) {
					gameIsPaused = 1;
				} else {
					gameIsPaused = 0;
				}

				toController <: GAME_PAUSED;
				fromButtons <: GAME_NOT_OVER;
				//printf("Does reach here\n");
			}

			if (buttonInput != BUTTON_B) {
				//printf("Attempted ant position %d\n", attemptedAntPosition);
	            toController <: attemptedAntPosition;
				//printf("Move allowed\n");

	            toController :> moveForbidden;

				if (moveForbidden == MOVE_ALLOWED) {
					fromButtons <: GAME_NOT_OVER;
					userAntPosition = attemptedAntPosition;
					toVisualiser <: userAntPosition;
				} else if (moveForbidden == MOVE_FORBIDDEN) {
					fromButtons <: GAME_NOT_OVER;
				} else if (moveForbidden == GAME_OVER) {
					fromButtons <: GAME_OVER;
					toVisualiser <: GAME_OVER;
					gameIsOver = 1;
				}
			}

		}
	}
}

//ATTACKER PROCESS... The attacker is controlled by this process attackerAnt,
//                    which has channels to the visualiser and controller
void attackerAnt(chanend toVisualiser, chanend toController) {
	int moveCounter = 0; //moves of attacker so far
	unsigned int attackerAntPosition = 5; //the current attacker position
	unsigned int attemptedAntPosition; //the next attempted  position after considering move direction
	int currentDirection = 1; //the current direction the attacker is moving
	int moveForbidden = 0; //the verdict of the controller if move is allowed
	int gameIsOver = GAME_NOT_OVER;
	int timeToWait = 30000000;
	int lastMoveCounter = 0;

	toVisualiser <: attackerAntPosition; //show initial position

	while (gameIsOver == GAME_NOT_OVER) {
		if (moveCounter % 31 == 0 || moveCounter % 37 == 0 || moveCounter % 47 == 0) {
			currentDirection *= -1;
		}

		if (moveCounter % 50 == 0 && moveCounter != lastMoveCounter) {
			lastMoveCounter = moveCounter;
			printf("Move counter: %d\n", moveCounter);



			timeToWait = timeToWait - 1000000;

			toController <: GAME_PAUSED;
			toVisualiser <: LEVEL_UP;
			int response;
			toVisualiser :> response;
			toController <: GAME_PAUSED;
		}

		attemptedAntPosition = mod((attackerAntPosition + currentDirection), 12);

		toController <: attemptedAntPosition;
		toController :> moveForbidden;

		if (moveForbidden == MOVE_ALLOWED) {
			attackerAntPosition = attemptedAntPosition;
			toVisualiser <: attackerAntPosition;
			moveCounter += 1;
		} else if (moveForbidden == GAME_RESTARTED) {
			attackerAntPosition = 5;
			moveCounter = 0;
			toVisualiser <: attackerAntPosition;
		}
		else if (moveForbidden == MOVE_FORBIDDEN) {
			currentDirection *= -1;
		} else if (moveForbidden == GAME_OVER) {
			attackerAntPosition = attemptedAntPosition;
			toVisualiser <: attackerAntPosition;
			gameIsOver = GAME_OVER;
		} else if (moveForbidden == GAME_TERMINATED) {
			gameIsOver = GAME_OVER;
		}

		waitMoment(timeToWait);

	}
}

//COLLISION DETECTOR... the controller process responds to permission-to-move requests
//                      from attackerAnt and userAnt. The process also checks if an attackerAnt
//                      has moved to LED positions I, XII and XI.
void controller(chanend fromAttacker, chanend fromUser) {
	unsigned int lastReportedUserAntPosition = 11; //position last reported by userAnt
	unsigned int lastReportedAttackerAntPosition = 5; //position last reported by attackerAnt
	unsigned int attempt = 0;
	int gameIsOver = 0;
	int gameIsPaused = 0;
	int shouldTerminate = 0;
	int shouldRestart = 0;
	int shutDownController = 0;

	fromUser :> attempt; //start game when user moves
	fromUser <: MOVE_FORBIDDEN; //forbid first move

	while (shutDownController == 0) {
		select {
			case fromAttacker :> attempt:
				//printf("Attempt from attacker: %d\n", attempt);

				if (attempt == GAME_PAUSED) {
					if (gameIsPaused == 0) {
						gameIsPaused = 1;
					} else {
						gameIsPaused = 0;
					}
				} else if (attempt == lastReportedUserAntPosition) {
                    fromAttacker <: MOVE_FORBIDDEN;
                } else if (shouldRestart == 1) {
                	fromAttacker <: GAME_RESTARTED;
                	shouldRestart = 0;
                	gameIsPaused = 0;
                } else if (shouldTerminate == 1) {
                	fromAttacker <: GAME_TERMINATED;
                	shutDownController = 1;
                } else if (gameIsPaused == 1) {
                	fromAttacker <: MOVE_FORBIDDEN;
                } else {
                    if (attempt == 0 || attempt == 11 || attempt == 10) {
                        lastReportedAttackerAntPosition = attempt;
                        gameIsOver = 1;
                        fromAttacker <: GAME_OVER;
                    } else {
                        lastReportedAttackerAntPosition = attempt;
                        fromAttacker <: MOVE_ALLOWED;
                    }
                }
			break;

			case fromUser :> attempt:
				//printf("Attempt from user: %d\n", attempt);
                if (gameIsOver == 1) {
                	printf("Game is over?\n");
                    fromUser <: GAME_OVER;
                    shutDownController = 1;
                } else if (attempt == GAME_PAUSED) {
                	if (gameIsPaused == 1) {
                		gameIsPaused = 0;
                	} else {
                		gameIsPaused = 1;
                	}
                } else if (attempt == GAME_RESTARTED) {
                	printf("Should restart here\n");
                	shouldRestart = 1;
                } else if (attempt == GAME_TERMINATED) {
                	printf("Game is terminated :(\n");
                	shouldTerminate = 1;
                } else if (attempt == lastReportedAttackerAntPosition || gameIsPaused == 1)  {
                	//printf("no dont move\n");
                    fromUser <: MOVE_FORBIDDEN;
                } else {
                	//printf("fast like the wind\n");
                    lastReportedUserAntPosition = attempt;
                    fromUser <: MOVE_ALLOWED;
                }
            break;
		}
	}
}

//MAIN PROCESS defining channels, orchestrating and starting the processes
int main(void) {
  chan buttonsToUserAnt,         //channel from buttonListener to userAnt
       userAntToVisualiser,      //channel from userAnt to Visualiser
       attackerAntToVisualiser,  //channel from attackerAnt to Visualiser
       attackerAntToController,  //channel from attackerAnt to Controller
       userAntToController;      //channel from userAnt to Controller
  chan quadrant0,quadrant1,quadrant2,quadrant3; //helper channels for LED visualisation

  par {
    //PROCESSES FOR YOU TO EXPAND
    on stdcore[1]: userAnt(buttonsToUserAnt,userAntToVisualiser,userAntToController);
    on stdcore[2]: attackerAnt(attackerAntToVisualiser,attackerAntToController);
    on stdcore[3]: controller(attackerAntToController, userAntToController);

    //HELPER PROCESSES
    on stdcore[0]: buttonListener(buttons, speaker,buttonsToUserAnt);
    on stdcore[0]: visualiser(userAntToVisualiser,attackerAntToVisualiser,quadrant0,quadrant1,quadrant2,quadrant3);
    on stdcore[0]: showLED(cled0,quadrant0);
    on stdcore[1]: showLED(cled1,quadrant1);
    on stdcore[2]: showLED(cled2,quadrant2);
    on stdcore[3]: showLED(cled3,quadrant3);
  }
  return 0;
}
