/*
 * AntDefender.h
 *
 *  Created on: Nov 3, 2014
 *      Author: jamie
 */

#ifndef ANTDEFENDER_H_
#define ANTDEFENDER_H_

void waitMoment(int timeToWait);
void restartGame(chanend toController, chanend toVisualiser, chanend fromButtons, int *userAntPosition, int *gameIsPaused);
void terminateGame(chanend toController, chanend toVisualiser, chanend fromButtons);
void pauseGame(chanend toController, chanend fromButtons, int *gameIsPaused);
void moveAnt(chanend toController, chanend toVisualiser, chanend fromButtons, int attemptedAntPosition, int *userAntPosition, int *gameIsOver);

void changeDirection(int *currentDirection);
void levelUp(chanend toController, chanend toVisualiser, int *lastMoveCounter, int moveCounter, int *timeToWait);

#endif /* ANTDEFENDER_H_ */
