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
#include "led.h"
#include "constants.h"
#include "AntDefender.h"

#define DEBUG 1

#ifndef DEBUG
#define printf(...)
#endif

in port buttons = PORT_BUTTON;
out port speaker = PORT_SPEAKER;

/////////////////////////////////////////////////////////////////////////////////////////
//
//  Helper Functions provided for you
//
/////////////////////////////////////////////////////////////////////////////////////////

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
	    b :> r;   // check if some buttons are pressed

	    // Button debouncing
	    if (prevButton == NO_BUTTON && r != NO_BUTTON) {
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

	int gameIsOver = GAME_NOT_OVER;
	int gameIsPaused = GAME_NOT_PAUSED;

	toVisualiser <: userAntPosition; //show initial position

	while (gameIsOver == GAME_NOT_OVER) {

		fromButtons :> buttonInput;
		if (gameIsPaused == GAME_PAUSED && buttonInput == BUTTON_A) {
			restartGame(toController, toVisualiser, fromButtons, &userAntPosition, &gameIsPaused);
		} else {
			if (buttonInput == BUTTON_A) {
				attemptedAntPosition = mod((userAntPosition + 1), 12);
			}
			if (buttonInput == BUTTON_D) {
				attemptedAntPosition = mod((userAntPosition - 1), 12);
			}
			if (buttonInput == BUTTON_C) {
				terminateGame(toController, toVisualiser, fromButtons);
			}
			if (buttonInput == BUTTON_B) {
				pauseGame(toController, fromButtons, &gameIsPaused);
			}
			if (buttonInput != BUTTON_B) {
				moveAnt(toController, toVisualiser, fromButtons, attemptedAntPosition, &userAntPosition, &gameIsOver);
			}
		}
	}
}

void restartGame(chanend toController, chanend toVisualiser, chanend fromButtons, int *userAntPosition, int *gameIsPaused) {
	printf("Restart game\n");
	toController <: GAME_RESTARTED;
	fromButtons <: GAME_NOT_OVER;

	*userAntPosition = 11;
	toVisualiser <: *userAntPosition;
	*gameIsPaused = GAME_NOT_PAUSED;
}

void terminateGame(chanend toController, chanend toVisualiser, chanend fromButtons) {
	printf("Terminate game\n");
	fromButtons <: GAME_OVER;
	toVisualiser <: GAME_OVER;
	toController <: GAME_TERMINATED;
}

void pauseGame(chanend toController, chanend fromButtons, int *gameIsPaused) {
	printf("Pause/play\n");
	if (*gameIsPaused == GAME_NOT_PAUSED) {
		*gameIsPaused = GAME_PAUSED;
	} else {
		*gameIsPaused = GAME_NOT_PAUSED;
	}

	toController <: GAME_PAUSED;
	fromButtons <: GAME_NOT_OVER;
}

void moveAnt(chanend toController, chanend toVisualiser, chanend fromButtons, int attemptedAntPosition, int *userAntPosition, int *gameIsOver) {
	int moveForbidden; //the verdict of the controller if move is allowed

    toController <: attemptedAntPosition;
    toController :> moveForbidden;

	if (moveForbidden == MOVE_ALLOWED) {
		fromButtons <: GAME_NOT_OVER;
		*userAntPosition = attemptedAntPosition;
		toVisualiser <: *userAntPosition;
	} else if (moveForbidden == MOVE_FORBIDDEN) {
		fromButtons <: GAME_NOT_OVER;
	} else if (moveForbidden == GAME_OVER) {
		fromButtons <: GAME_OVER;
		toVisualiser <: GAME_OVER;
		*gameIsOver = GAME_OVER;
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
	int timeToWait = 25000000;
	int lastMoveCounter = 0;

	toVisualiser <: attackerAntPosition; //show initial position

	while (gameIsOver == GAME_NOT_OVER) {
		if (moveCounter % 31 == 0 || moveCounter % 37 == 0 || moveCounter % 47 == 0) {
			changeDirection(&currentDirection);
		}

		if (moveCounter % LEVEL_SIZE == 0 && moveCounter != lastMoveCounter) {
			levelUp(toController, toVisualiser, &lastMoveCounter, moveCounter, &timeToWait);
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
			timeToWait = 25000000;
			toVisualiser <: attackerAntPosition;
		}
		else if (moveForbidden == MOVE_FORBIDDEN) {
			changeDirection(&currentDirection);
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

void changeDirection(int *currentDirection) {
	*currentDirection *= -1;
}

void levelUp(chanend toController, chanend toVisualiser, int *lastMoveCounter, int moveCounter, int *timeToWait) {
	*lastMoveCounter = moveCounter;
	printf("Move counter: %d\n", moveCounter);

	*timeToWait = *timeToWait - 2000000;

	toController <: GAME_PAUSED;
	printf("after sending game paused\n");
	toVisualiser <: LEVEL_UP;
	printf("after sending level up to visualiser\n");
	int response;
	toVisualiser :> response;
	printf("we get a response\n");
	toController <: GAME_PAUSED;
}

//COLLISION DETECTOR... the controller process responds to permission-to-move requests
//                      from attackerAnt and userAnt. The process also checks if an attackerAnt
//                      has moved to LED positions I, XII and XI.
void controller(chanend fromAttacker, chanend fromUser) {
	unsigned int lastReportedUserAntPosition = 11; //position last reported by userAnt
	unsigned int lastReportedAttackerAntPosition = 5; //position last reported by attackerAnt
	unsigned int attempt = 0;
	int gameIsOver = GAME_NOT_OVER;
	int gameIsPaused = GAME_NOT_PAUSED;
	int shouldTerminate = 0;
	int shouldRestart = 0;
	int shutDownController = 0;

	fromUser :> attempt; //start game when user moves
	fromUser <: MOVE_FORBIDDEN; //forbid first move

	while (shutDownController == 0) {
		select {
			case fromAttacker :> attempt:

				if (attempt == GAME_PAUSED) {
					if (gameIsPaused == GAME_NOT_PAUSED) {
						gameIsPaused = GAME_PAUSED;
					} else {
						gameIsPaused = GAME_NOT_PAUSED;
					}
				} else if (attempt == lastReportedUserAntPosition) {
                    fromAttacker <: MOVE_FORBIDDEN;
                } else if (shouldRestart == 1) {
                	fromAttacker <: GAME_RESTARTED;
                	shouldRestart = 0;
                	gameIsPaused = GAME_NOT_PAUSED;
                } else if (shouldTerminate == 1) {
                	fromAttacker <: GAME_TERMINATED;
                	shutDownController = 1;
                } else if (gameIsPaused == GAME_PAUSED) {
                	fromAttacker <: MOVE_FORBIDDEN;
                } else {
                    if (attempt == 0 || attempt == 11 || attempt == 10) {
                        lastReportedAttackerAntPosition = attempt;
                        gameIsOver = GAME_OVER;
                        fromAttacker <: GAME_OVER;
                    } else {
                        lastReportedAttackerAntPosition = attempt;
                        fromAttacker <: MOVE_ALLOWED;
                    }
                }
			break;

			case fromUser :> attempt:
                if (gameIsOver == GAME_OVER) {
                    fromUser <: GAME_OVER;
                    shutDownController = 1;
                } else if (attempt == GAME_PAUSED) {
                	if (gameIsPaused == GAME_PAUSED) {
                		gameIsPaused = GAME_NOT_PAUSED;
                	} else {
                		gameIsPaused = GAME_PAUSED;
                	}
                } else if (attempt == GAME_RESTARTED) {
                	shouldRestart = 1;
                } else if (attempt == GAME_TERMINATED) {
                	shouldTerminate = 1;
                } else if (attempt == lastReportedAttackerAntPosition || gameIsPaused == GAME_PAUSED)  {
                    fromUser <: MOVE_FORBIDDEN;
                } else {
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
