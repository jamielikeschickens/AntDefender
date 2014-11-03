/*
 * led.h
 *
 *  Created on: Nov 3, 2014
 *      Author: jamie
 */

#include <stdio.h>
#include <platform.h>

#ifndef LED_H_
#define LED_H_

int showLED(out port p, chanend fromVisualiser);
void visualiser(chanend fromUserAnt, chanend fromAttackerAnt, chanend toQuadrant0, chanend toQuadrant1, chanend toQuadrant2, chanend toQuadrant3);

extern out port cled0;
extern out port cled1;
extern out port cled2;
extern out port cled3;
extern out port cledG;
extern out port cledR;

#endif /* LED_H_ */
